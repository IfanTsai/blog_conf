local ngx           = ngx
local cjson         = require 'cjson.safe'
local http          = require 'resty.http'
local redis         = require 'resty.redis-util'
local cai           = require 'cai'
local cai_conf      = require 'cai_conf'
local get_post_data = cai.get_post_data
local is_args_empty = cai.is_args_empty
local is_not_null   = cai.is_not_null
local is_null       = cai.is_null
local ungzip        = cai.ungzip
local redis_conf    = cai_conf.redis_conf
local editor_domain = cai_conf.editor_domain

local body = get_post_data(true)
local json = cjson.decode(body)
if is_args_empty(2, json['language'], json['data']) then
    --ngx.exit(406)
    ngx.say('')
    ngx.exit(200)
end

local md5 = ngx.md5(body)

local rds = redis:new(redis_conf)

local key = 'editor_run_' .. md5
local res, err = rds:get(key)
if not err and is_not_null(res) then
    rds:set(key, res, 60 * 60 * 1)
    ngx.say(res)
    ngx.exit(200)
end

local httpc = http:new()
httpc:set_timeout(60 * 1000)
res, err = httpc:request_uri(editor_domain .. '/editor/run', {
    method = 'POST',
    body = body,
})
httpc:close()

if err then
    ngx.log(ngx.ERR, "request failed: ", err)
    ngx.exit(500)
end

if is_null(res) or 200 ~= res.status then
    ngx.log(ngx.ERR, 'http request /editor/run error, status: ' .. res.status)
    ngx.exit(500)
end

res.body = ungzip(res.headers, res.body)

rds:set(key, res.body, 60 * 60 * 1)

ngx.say(res.body)
ngx.exit(200)
