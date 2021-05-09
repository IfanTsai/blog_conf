cjson = require 'cjson.safe'
redis = require 'resty.redis-util'
mysql = require 'resty.mysql'
shell = require 'resty.shell'
http  = require 'resty.http'
zlib  = require 'zlib'
uuid  = require 'resty.jit-uuid'

uuid.seed()

cjson.encode_empty_table_as_object(false)

-- read configure file
local f, err = io.open('/usr/local/openresty/nginx/conf/lua/cai.json', 'r')
if f == nil then
    error(err)
end
local cai_conf = f:read("*a")
f:close()
cai_conf = cjson.decode(cai_conf)

-- set config
redis_conf = cai_conf['redis_conf']
editor_domain = cai_conf['editor_domain']
ip_black_list = cai_conf['ip_black_list']

is_null = function(arg)
    return nil == arg or ngx.null == arg
end

is_not_null = function(arg)
    return not is_null(arg)
end

is_empty = function(arg)
    return is_null(arg) or 0 == #arg
end

is_args_empty = function(cnt, ...)
    local args = { ... }
    if cnt ~= #args then
        return true
    end
    for _, v in ipairs(args) do
        if is_null(v) or 0 == #v then
            return true
        end
    end
    return false
end

is_not_empty = function(cnt, ...)
    return not is_empty(cnt, ...)
end

ungzip = function(headers, body)
    local encoding = headers['Content-Encoding']
    if 'gzip' == encoding then
        local stream = zlib.inflate()
        body = stream(body)
    end
    return body
end

get_client_ip = function()
    local ip = ngx.req.get_headers()['X-Real-IP']
    if is_null(ip) then
        ip = ngx.req.get_headers()['x_forwarded_for']
    end
    if is_null(ip) then
        ip = ngx.var.remote_addr
    end
    return ip
end

get_post_data = function(not_empty)
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
    body = ungzip(ngx.req.get_headers(), body)

    if not_empty and is_null(body) then
        ngx.log(ngx.ERR, "body is null")
        ngx.exit(406)
    end

    return body
end

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
