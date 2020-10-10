local clock = require 'clock'
local digest = require 'digest'

local Auth = {}

local function secret()
  return ''
end

function Auth.access(request)
  local auth, secret = request:header('authentication'), secret()
  if not auth then return {status = 400, body = 'auth.missing_header'}
  elseif not secret then return {status = 500, body = 'server.missing_config'} end
  local data, expire, token = auth:match('^(.+):(.+):(.+)$')
  if not token then return {status = 401, body = 'auth.invalid_token'}
  elseif tonumber(expire) < clock.time() then return {status = 401, body = 'auth.expired_token'}
  elseif digest.sha1_hex(('%s%s%d'):format(secret, data, expire)) ~= token then return {status = 401, body = 'auth.invalid_token'} end
  request.user = json.decode(digest.base64_decode(data))
  return request:next()
end 

function Auth.hash()
  return digest.urandom(32)
end

function Auth.password(password, hash)
  return digest.sha256_hex(('%s%s'):format(password, hash))
end

function Auth.token(data, expire)
  data = digest.base64_encode(json.encode(data))
  expire = expire or math.floor(clock.time() + 3600)
  local token = digest.sha1_hex(('%s%s%d'):format(secret(), data, expire))
  return ('%s:%d:%s'):format(data, expire, token)
end

return Auth