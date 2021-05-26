local ngx = ngx
local ngx_var = ngx.var
local prometheus = prometheus
local metric_connections = metric_connections

metric_connections:set(ngx_var.connections_active, {'active'})
metric_connections:set(ngx_var.connections_reading, {'reading'})
metric_connections:set(ngx_var.connections_waiting, {'waiting'})
metric_connections:set(ngx_var.connections_writing, {'writing'})

prometheus:collect()