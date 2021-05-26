local ngx = ngx
local ngx_var = ngx.var
local server_name = ngx_var.server_name
local uri = ngx_var.uri
local status = ngx_var.status
local request_time = tonumber(ngx_var.request_time)
local metric_requests = metric_requests
local metric_uri = metric_uri
local metric_latency = metric_latency

metric_requests:inc(1, {
    server_name,
    status
})

metric_uri:inc(1, {
    server_name,
    uri,
    status
})

metric_latency:observe(request_time, {
    server_name
})