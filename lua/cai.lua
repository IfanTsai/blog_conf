local ngx = ngx
local cjson = require 'cjson.safe'
local zlib = zlib

local _M = { }

_M.str_find = function(s1, s2, is_re, pos)
    if is_re then
        local ctx = { pos = pos or 1 }
        return ngx.re.find(s1, s2, 'jo', ctx)
    end
    return string.find(s1, s2, 1, true)
end

_M.is_null = function(arg)
    return nil == arg or ngx.null == arg
end

_M.is_not_null = function(arg)
    return not _M.is_null(arg)
end

_M.is_empty = function(arg)
    return _M.is_null(arg) or 0 == #arg
end

_M.is_args_empty = function(cnt, ...)
    local args = { ... }
    if cnt ~= #args then
        return true
    end
    for _, v in ipairs(args) do
        if _M.is_null(v) or 0 == #v then
            return true
        end
    end
    return false
end

_M.ungzip = function(headers, body)
    local encoding = headers['Content-Encoding']
    if 'gzip' == encoding then
        local stream = zlib.inflate()
        body = stream(body)
    end
    return body
end

_M.get_client_ip = function()
    local headers = ngx.req.get_headers()
    local ip = headers['X-Real-IP']
    if _M.is_null(ip) then
        ip = headers['x_forwarded_for']
    end
    if _M.is_null(ip) then
        ip = ngx.var.remote_addr
    end
    return ip
end

_M.get_post_data = function(not_empty)
    if 'POST' ~= ngx.req.get_method() then
        ngx.exit(406)
    end

    -- get post body
    ngx.req.read_body()
    local body = ngx.req.get_body_data()

    if nil == body then
        local fname = ngx.req.get_body_file()
        if nil == fname then
            ngx.exit(406)
        end
        local f = io.open(fname, 'rb')
        body = f:read('*all')
        f:close()
    end

    -- unzip
    body = _M.ungzip(ngx.req.get_headers(), body)

    if not_empty and _M.is_null(body) then
        ngx.log(ngx.ERR, "body is null")
        ngx.exit(406)
    end

    return body
end

_M.get_post_json = function()
    local data = _M.get_post_data(true)
    data = cjson.decode(data)
    if nil == data then
        ngx.exit(406)
    end

    return data
end

return _M

--[[
redis_connect = function(host, port, passwd)
    local rds = redis:new()
    rds:set_timeout(1000)  -- 1000 ms
    local ok, err = rds:connect(host, port)
    if not ok then
        ngx.log(ngx.ERR, 'can not connect to redis: ' .. tostring(host) .. ':' .. tostring(port) .. ' error: ' .. err )
        return nil
    end

    if not is_null(passwd) then
        local count, err = rds:get_reused_times()
        if 'number' == type(count) and 0 == count then
            local ok, err = rds:auth(passwd)
            if not ok then
                ngx.log(ngx.ERR, 'redis auth error: ' .. tostring(host) .. ':' .. tostring(port) .. ' error: ' .. err )
                return nil
            end
        elseif err then
            ngx.log(ngx.ERR, 'failed to authenticate: ' .. err)
            rds:close()
            return nil
        end
    end

    return rds
end
]]
