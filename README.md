# lua-tarantool-set

**lua-tarantool-set** is a wrapper library for Tarantool like [lua-resty-set](https://github.com/emyasnikov/lua-resty-set) for OpenResty which tries to simplify the complexity of the framework.

## CRUD

**lua-tarantool-set** supports predefined CRUD endpoints, which can be used to shorten code. This only works with appropriate ID provided while registering new Set:

```lua
local Example = set("example")
```

### Create

```lua
Example:create(function(self, data) end)
```

This matches `POST /example` and reads data to `data`.

### Read

```lua
Example:read(function(self, id) end)
```

This matches `GET /example/1`.

### Update

```lua
Example:update(function(self, id, data) end)
```

This matches `PATCH /example/1` and reads data to `data`.

### Delete

```lua
Example:delete(function(self, id) end)
```

And this matches `DELETE /example/1`.

## Routes

```lua
Example:route('get', '/example/:id', function(self)
  local id = tonumber(http:stash("id"))
  if not id then return self.error(400, "http.bad_request") end
  return {}
end)
```

Route function takes method and path with named attributes in it, like the ID in this case.

## Dependencies

[tarantool/document](https://github.com/tarantool/document) — Effortless JSON storage for Tarantool


## Licence

**lua-tarantool-set** uses MIT License.

```
Copyright (c) 2020 Evgenij 'Warl' Myasnikov
All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```