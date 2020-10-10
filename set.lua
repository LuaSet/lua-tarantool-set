document = require "document"
json = require "json"

local Set = {}

Set.__index = Set
setmetatable(Set, {
  __call = function(set, id, options)
    local self = {}
    self.__index = self
    self._id = id
    return setmetatable(self, {
      __index = Set
    })
  end
})

function Set.config(options)
  box.cfg(options)
end

-- Server

function Set.server(options)
  local router = require "http.router".new()
  local server = require "http.server".new(options.host or "localhost", options.port or 2608, {
    log_requests = options.log and options.log.requests or true,
    log_errors = options.log and options.log.errors or true,
    display_errors = false,
  })
  for _, module in next, options.modules do
    require(module):init(router)
  end
  server:set_router(router)
  server:start()
end

function Set.error(code, text)
  return {status = code, body = text}
end

function Set.json(data)
  return {
    status = 200,
    headers = {
      ["content-type"] = "application/json;charset=utf8"
    },
    body = json.encode(data)
  }
end

-- Document

function Set.remove(set, data)
  return document.delete(box.space[set], data)
end

function Set.insert(set, data)
  return document.insert(box.space[set], data)
end

function Set.get(set, data)
  return document.get(box.space[set], data)
end

function Set.select(set, data)
  return document.select(box.space[set], data)
end

-- Schema

function Set:init(router)
  box.once(("schema.%s"):format(self._id), function()
    if not self._schema then return end
    for id, schema in next, self._schema do repeat
      if not schema or not schema.options then break end
      if schema.sequence then
        box.schema.sequence.create(id, schema.sequence)
      end
      local space = box.schema.space.create(id, schema.options)
      if schema.index then
        for _, index in next, schema.index do
          document.create_index(space, index.type, index.options)
        end
      end
    until true end
  end, self)
  box.once(("default.%s"):format(self._id), function()
    if not self._default then return end
    for _, callback in next, self._default do repeat
      if type(callback) ~= "function" then break end
      for set, values in next, callback(self) do
        for _, value in next, values do
          document.insert(box.space[set], value)
        end
      end
    until true end
  end, self)
  if router and self._routes then
    for path, route in next, self._routes do
      router:route(route.options, route.callback)
    end
  end
end

function Set:schema(id, options)
  if not id or not options then return end
  self._schema = self._schema or {}
  self._schema[id] = options
end

function Set:default(callback)
  if not callback then return end
  self._default = self._default or {}
  table.insert(self._default, callback)
end

function Set:next()
  return box.sequence[self._id]:next()
end

-- Router

function Set:call(callback, ...)
  local status, result = pcall(callback, self, ...)
  if status then return self.json(result) end
  return self.error(
    result.code or result[1] or 500,
    result.text or result[2] or "server.internal_error"
  )
end

function Set:create(callback)
  self:router("post", ("/%s"):format(self._id), function(http)
    local data = http:json()
    if not data then return self.error(400, "http.bad_request") end
    return self:call(callback, data)
  end)
end

function Set:read(callback)
  self:router("get", ("/%s/:id"):format(self._id), function(http)
    local id = tonumber(http:stash("id"))
    if not id then return self.error(400, "http.bad_request") end
    return self:call(callback, id)
  end)
end

function Set:update(callback)
  self:router("patch", ("/%s/:id"):format(self._id), function(http)
    local id = tonumber(http:stash("id"))
    if not id then return self.error(400, "http.bad_request") end
    local data = http:json()
    if not data then return self.error(400, "http.bad_request") end
    return self:call(callback, id, data)
  end)
end

function Set:delete(callback)
  self:router("delete", ("/%s/:id"):format(self._id), function(http)
    local id = tonumber(http:stash("id"))
    if not id then return self.error(400, "http.bad_request") end
    return self:call(callback, id)
  end)
end

function Set:route(method, path, callback, options)
  self:router(method, path, function(http)
    return self:call(callback, http:param())
  end)
end

function Set:router(method, path, callback, options)
  self._routes = self._routes or {}
  local route = {}
  route.callback = callback
  route.options = options or {}
  route.options.method = method
  route.options.path = path
  table.insert(self._routes, route)
end

return Set