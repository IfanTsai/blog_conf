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
httpc.set_timeout(60 * 1000)
local res = httpc:request_uri(editor_domain .. '/editor/run', {
    method='POST',
    body=body,
})
httpc:close()

if is_null(res) or 200 ~= res.status then
    ngx.log(ngx.ERR, 'http request /editor/run error, status: ' .. res.status)
    ngx.exit(500)
end

res.body = ungzip(res.headers, res.body)

rds:set(key, res.body, 60 * 60 * 1)

ngx.say(res.body)
ngx.exit(200)
