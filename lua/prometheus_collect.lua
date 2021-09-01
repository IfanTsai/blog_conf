local ngx                = ngx
local ngx_var            = ngx.var
local cai_conf           = require 'cai_conf'
local prometheus         = cai_conf.prometheus
local metric_connections = cai_conf.metric_connections

metric_connections:set(ngx_var.connections_active, {'active'})
metric_connections:set(ngx_var.connections_reading, {'reading'})
metric_connections:set(ngx_var.connections_waiting, {'waiting'})
metric_connections:set(ngx_var.connections_writing, {'writing'})

prometheus:collect()