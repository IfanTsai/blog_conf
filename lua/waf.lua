local ngx = ngx
local redis = require 'resty.redis-util'
local cai = require 'cai'
local get_client_ip = cai.get_client_ip
local is_null = cai.is_null
local redis_conf = redis_conf
local ip_black_list = ip_black_list
local security_shm = ngx.shared.security_shm

local ip = get_client_ip()
if ip_black_list[ip] then
    ngx.exit(403)
end

local ban_ip_time = 3600 * 12
local black_ip_token = 'black_' .. ip

local rds = redis:new(redis_conf)

-- Ban ip
local is_black_ip = rds:exists(black_ip_token)
if 1 == is_black_ip then
    ngx.exit(403)
end

is_black_ip = security_shm:get(black_ip_token)
if 1 == is_black_ip then
    rds:set(black_ip_token, 1, ban_ip_time)
    ngx.exit(403)
end

local ua = ngx.var.http_user_agent
--local uri = ngx.var.request_uri   -- with args
local uri = ngx.var.uri
local url = ngx.var.host .. uri
local req_time_out = 5
local req_max_times = 8
local req_forbide_time = 3600

ua = is_null(ua) and 'unknown' or ua
local req_token = 'req_' .. ip .. '_' .. ngx.md5(url .. ua)
local black_token = 'black_' .. req_token

-- Block frequent access to the same uri
local black_req = rds:exists(black_token)
if 1 == black_req then
    ngx.exit(403)
end

local req_times = tonumber(rds:get(req_token))
if nil == req_times then
    rds:set(req_token, 1, req_time_out)
else
    if req_times >= req_max_times then
        rds:set(black_token, 1, req_forbide_time)
        --rds:expire(req_token, req_forbide_time)
        ngx.exit(403)
    else
        rds:incr(req_token)
    end
end
