local ngx           = ngx
local get_uri_args  = ngx.req.get_uri_args
local cai_conf      = require 'cai_conf'
local qmsg_key      = cai_conf.qmsg_key
local http          = require 'resty.http'
local cjson         = require 'cjson.safe'
local cai           = require 'cai'
local get_post_data = cai.get_post_data
local check_token   = cai.check_token

check_token(get_uri_args())

local body = get_post_data(true)

body = string.gsub(body, '\\n', '%0A')

local httpc = http:new()
local res, err = httpc:request_uri('https://qmsg.zendee.cn/send/' .. qmsg_key, {
    method = 'GET',
    query = {
        msg = body,
    }
})
httpc:close()

if err then
    ngx.log(ngx.ERR, 'qmsg_send: request failed', err)
    ngx.exit(500)
end

if 200 ~= res.status then
    ngx.log(ngx.ERR, 'qmsg_send: request failed, res status: ', tostring(res.status))
    ngx.exit(500)
end

body = cjson.decode(res.body)
if body['success'] == false then
    ngx.log(ngx.ERR, 'qmsg_send: error, res: ', res.body)
    ngx.exit(500)
end

ngx.say('success')
ngx.exit(200)