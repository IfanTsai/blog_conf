local ngx = ngx
local ngx_timer_every = ngx.timer.every
local redis = require 'resty.redis-util'
local process = require 'ngx.process'
local cjson = require 'cjson.safe'

local ip_black_list_path = '/usr/local/openresty/nginx/conf/json/ip_black_list.json'

local read_json_file = function(path)
    local f, err = io.open(path, 'r')
    if nil == f then
        ngx.log(ngx.ERR, 'failed to open ', path, ', err: ', err)
        return nil, err
    end

    local json = f:read('*a')
    f:close()

    local json_tab
    json_tab, err = cjson.decode(json)
    if nil == json_tab then
        ngx.log(ngx.ERR, 'failed to decode ', path, ', err: ', err)
        return nil, err
    end

    return json_tab
end

local write_json_file = function(path, json_tab)
    local f, err = io.open(path, 'w')
    if nil == f then
        ngx.log(ngx.ERR, 'failed to open ', path, ', err: ', err)
        return nil, err
    end

    f:write(cjson.encode(json_tab))
    f:close()

    return json_tab
end

local reload = function()
    local f, err = io.open(ngx.config.prefix() .. '/logs/nginx.pid')
    if nil == f then
        ngx.log(ngx.ERR, 'failed to open nginx.pid, err: ', err)
        return
    end

    local pid = f:read()
    f:close()
    os.execute('kill -HUP ' .. pid)
end

local flush_redis_black_ip_to_file = function(premature)
    local rds = redis:new(redis_conf)
    local res = rds:scan(0, 'match', 'black_*')
    local cursor, keys, err = res[1], res[2], res[3]

    if nil ~= err then
        ngx.log(ngx.ERR, 'failed to scan redis, err: ', err)
        return
    end

    if 0 == #keys then
        return
    end

    local ip_black_list = read_json_file(ip_black_list_path)
    if nil == ip_black_list then
        return
    end

    repeat
        for _, key in ipairs(keys) do
            local ip = key:match('black_(%d+%.%d+%.%d+%.%d+)')
            if nil ~= ip then
                ip_black_list[ip] = true
                rds:del(key)
            end
        end

        res = rds:scan(cursor, 'match', 'black_*')
        cursor, keys, err = res[1], res[2], res[3]

        if nil ~= err then
            ngx.log(ngx.ERR, 'failed to scan redis, err: ', err)
            return
        end
    until (0 == tonumber(cursor))

    write_json_file(ip_black_list_path, ip_black_list)

    reload()
end


-- privileged agent process
if 'privileged agent' == process.type() then
    local ok, err = ngx_timer_every(3600, flush_redis_black_ip_to_file)
    assert(ok, err)
    return
end

-- worker process

-- read ip black list
local err
ip_black_list, err = read_json_file(ip_black_list_path)
assert(ip_black_list, err)

prometheus = require 'prometheus'.init('prometheus_metrics_shm', {
    prefix = "nginx_http_",
    sync_interval = 1,
})

metric_requests = prometheus:counter('requests_total', 'Number of HTTP requests', {'host', 'status'})
metric_uri = prometheus:counter('uri_total', 'Number of HTTP uri', {'host', 'uri', 'status'})
metric_latency = prometheus:histogram('request_duration_seconds', 'HTTP request latency', {'host', 'uri', 'status'})
metric_connections = prometheus:gauge('connections', 'Number of HTTP connections', {'state'})