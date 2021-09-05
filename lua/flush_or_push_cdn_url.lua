local ngx               = ngx
local cjson             = require 'cjson.safe'
local hmac              = require "resty.hmac"
local http              = require 'resty.http'
local cai               = require 'cai'
local cai_conf          = require 'cai_conf'
local get_uri_args      = ngx.req.get_uri_args
local check_token       = cai.check_token
local get_post_json     = cai.get_post_json
local new_tab           = cai.new_tab
local qcloud_secret_id  = cai_conf.qcloud_secret_id
local qcloud_secret_key = cai_conf.qcloud_secret_key


local args = get_uri_args()
check_token(args)

local command = args.command
if 'flush' ~= command and 'push' ~= command then
    ngx.exit(406)
end

local method = 'POST'
local protocol = 'https://'
local host = 'cdn.api.qcloud.com'
local uri = '/v2/index.php'
local action = 'FlushOrPushOverall'

local params = {
    ['Action'] = action,
    ['SecretId'] = qcloud_secret_id,
    ['Timestamp'] = ngx.time(),
    ['Nonce'] = math.random(1000),
    ['type'] = 'url',
    ['mainland'] = 1,
    ['oversea'] = 1,
    ['command'] = command
}

local urls = get_post_json()['urls']
if 'table' ~= type(urls) then
    ngx.exit(406)
end

for index, url in ipairs(urls) do
    params['urls.' .. tostring(index - 1)] = url
end

-- 1. Sort parameters

local keys = new_tab(#params, 0)
local index = 1
for k, _ in pairs(params) do
    keys[index] = k
    index = index + 1
end

table.sort(keys)

-- 2. Concatenate request string

local tmp = new_tab(#keys, 0)
for i, k in ipairs(keys) do
    tmp[i] = k .. "=" .. tostring(params[k])
end

local sig_params = table.concat(tmp, '&')

-- 3. Concatenate the original signature string
local sig_url = method .. host .. uri .. '?' .. sig_params

-- 4. Generate signature string

local hmac_sha1 = hmac:new(qcloud_secret_key, hmac.ALGOS.SHA1)
if not hmac_sha1 then
    ngx.log(ngx.ERR, 'failed to create the hmac_sha1 object')
    ngx.exit(500)
end

local ok = hmac_sha1:update(sig_url)
if not ok then
    ngx.log(ngx.ERR, 'failed to add data')
    ngx.exit(500)
end

local mac = hmac_sha1:final()
local base64 = ngx.encode_base64(mac) .. '='
params['Signature'] = base64

-- 5. Send http request

local httpc = http:new()
httpc:set_timeouts(30 * 1000, 30 * 1000, 30 * 1000)

local request_url = protocol .. host .. uri
local res, err
if method == 'GET' then
    res, err = httpc:request_uri(request_url, {
        method = method,
        query = params,
    })
else
    res, err = httpc:request_uri(request_url, {
        method = method,
        body =  sig_params .. '&Signature=' .. base64,
        headers = {
            ["Content-Type"] = "application/x-www-form-urlencoded",
        }
    })
end

httpc:close()

if not res then
    ngx.log(ngx.ERR, 'request failed', err)
    ngx.exit(500)
end

if 200 ~= res.status then
    ngx.log(ngx.ERR, 'response header status code is not 200')
    ngx.exit(500)
end

local res_body = cjson.decode(res.body)
if not res_body['code'] or tonumber(res_body['code']) ~= 0 then
    ngx.log(ngx.ERR, 'response body status code is not 0, body: ', res.body)
    ngx.exit(500)
end

ngx.header['Content-Type'] = 'application/json'
ngx.say(res.body)
ngx.exit(200)