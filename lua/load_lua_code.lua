local ngx           = ngx
local cai           = require 'cai'
local get_post_json = cai.get_post_json
local check_token   = cai.check_token
local get_uri_args  = ngx.req.get_uri_args

check_token(get_uri_args())

local code = get_post_json()['data']
local func, err = loadstring(code)
if not func then
    ngx.say('failed to load code, err: ', err)
    ngx.exit(200)
end

local ok
ok, err = pcall(func)
if not ok then
    ngx.say('failed to call code, err: ', err)
    ngx.exit(200)
end

ngx.exit(200)