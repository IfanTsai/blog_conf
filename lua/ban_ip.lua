local ngx = ngx

if ngx.status < 400 or 403 == ngx.status then
    return
end

local get_client_ip = require 'cai'.get_client_ip
local security_shm = ngx.shared.security_shm

local ip = get_client_ip()
local req_token = 'error_res_' .. ip
local black_token = 'black_' .. ip
local req_time_out = 3600
local req_max_times = 6
local req_forbide_time = 60

local is_black_ip = security_shm:get(black_token)
if 1 == is_black_ip then
    ngx.exit(403)
end

local times = security_shm:get(req_token)
if nil == times then
    security_shm:set(req_token, 1, req_time_out)
else
    if times >= req_max_times then
        security_shm:set(black_token, 1, req_forbide_time)
        security_shm:delete(req_token)
        ngx.exit(403)
    else
        security_shm:incr(req_token, 1)
    end
end
