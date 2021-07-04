local ngx = ngx
local get_post_json = require 'cai'.get_post_json
local get_uri_args = ngx.req.get_uri_args
local auth_salt = auth_salt
local auth_md5 = auth_md5

local args = get_uri_args()
local token = args.token
if nil == token then
    ngx.exit(406)
end

local md5 = ngx.md5(token .. auth_salt)
if md5 ~= auth_md5 then
    ngx.exit(401)
end

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