local set = set or require "set"

local Example = set("example")

Example:schema("example", {
  index = {{
    type = "primary",
    options = {parts = {"id", "unsigned"}, if_not_exists = true}
  }},
  options = {engine = "vinyl", if_not_exists = true},
  sequence = {if_not_exists = true}
})

Example:default(function(self)
  local id = self:next()
  return {
    example = {{id = id, value = ""}}
  }
end)

Example:create(function(self, data)
  if not data.value then error{400, "example.missing_value"} end
  local id = self:next()
  self.insert("example", {
    id = id,
    value = data.value
  })
  return {
    id = id,
    value = data.value
  }
end)

Example:read(function(self, id)
  local example = self.get("example", {{"$id", "==", id}})
  if not example then error{404, "example.not_found"} end
  return example
end)

Example:route("get", "/examples", function(self)
  local index, examples = 1, {}
  for _, example in self.select("example") do
    examples[index] = example
    index = index + 1
  end
  return examples
end)

return Example