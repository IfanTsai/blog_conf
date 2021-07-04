local ngx = ngx
local ngx_var = ngx.var
local server_name = ngx_var.server_name
local uri = ngx_var.uri
local ngx_var_status = ngx_var.status
local ngx_status = ngx.status
local request_time = tonumber(ngx_var.request_time)
local metric_requests = metric_requests
local metric_uri = metric_uri
local metric_latency = metric_latency
local get_client_ip = require 'cai'.get_client_ip
local security_shm = ngx.shared.security_shm

--[[
    If the client sent a malformed HTTP request line which aborted the HTTP protocol parsing.
    Meanwhile, if you have a log_by_lua* directive inside HTTP block directly,
    the Lua code specified by this directive still has a chance to run,
    and when you fetch $request_uri or $uri  in your Lua code, you will get nil.
]]
if nil == uri then
    -- ban ip
    local req_forbide_time = 60
    local black_token = 'black_' .. get_client_ip()
    security_shm:set(black_token, 1, req_forbide_time)
    return
end

if 403 <= ngx_status and ngx_status <= 404 then
    return
end

metric_requests:inc(1, {
    server_name,
    ngx_var_status,
})

metric_uri:inc(1, {
    server_name,
    uri,
    ngx_var_status,
})

metric_latency:observe(request_time, {
    server_name,
    uri,
    ngx_var_status,
})