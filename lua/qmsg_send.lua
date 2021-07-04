local ngx = ngx
local qmsg_key = qmsg_key
local http = require 'resty.http'
local get_post_data = require 'cai'.get_post_data

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

if not res then
    ngx.log(ngx.ERR, 'qmsg_send: request failed', err)
    ngx.exit(500)
end

ngx.exit(200)