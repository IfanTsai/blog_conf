local ip_black_list = ip_black_list

local ip = get_client_ip()
if ip_black_list[ip] then
    ngx.exit(403)
end

local ua = ngx.var.http_user_agent
local uri = ngx.var.request_uri
local url = ngx.var.host .. uri
local req_time_out = 5
local req_max_times = 8
local req_forbide_time = 3600

ua = is_null(ua) and 'unknown' or ua

local rds = redis:new(redis_conf)

local token = 'req_' .. ip .. '_' .. ngx.md5(url .. ua)
local req, err = rds:exists(token)
if err then return end
if 0 == req then
    local _, err = rds:incr(token, req_time_out)
    if err then return end
else
    local times, err = rds:get(token)
    if err then return end
    if tonumber(times) >= req_max_times then
        local black_req, err = rds:exists('black_' .. token)
        if err then return end
        if 0 == black_req then
            local _, err = rds:set('black_' .. token, 1, req_forbide_time)
            if err then return end
            local _, err = rds:expire(token, req_forbide_time)
            if err then return end
        end
        ngx.exit(403)
    else
        local _, err = rds:incr(token)
        if err then return end
    end
end
