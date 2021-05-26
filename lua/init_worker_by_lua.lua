prometheus = require 'prometheus'.init('prometheus_metrics_shm', {
    prefix = "nginx_http_",
    sync_interval = 1,
})

metric_requests = prometheus:counter('requests_total', 'Number of HTTP requests', {'host', 'status'})
metric_uri = prometheus:counter('uri_total', 'Number of HTTP uri', {'host', 'uri', 'status'})
metric_latency = prometheus:histogram('request_duration_seconds', 'HTTP request latency', {'host'})
metric_connections = prometheus:gauge('connections', 'Number of HTTP connections', {'state'})