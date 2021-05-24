local ngx = ngx
local cjson = require 'cjson.safe'
local uuid  = require 'resty.jit-uuid'
-- https://github.com/openresty/openresty/issues/510
zlib = require 'zlib'

-- table.new     = require 'table.new'
-- table.isempty = require 'table.isempty'
-- table.isarray = require 'table.isarray'
-- table.nkeyss  = require 'table.nkeys'
-- table.clone   = require 'table.clone'

cjson.encode_empty_table_as_object(false)

-- seed the random number generator
local seed = nil
local f, err = io.open('/dev/urandom', 'rb')
if nil == f then
    ngx.log(ngx.ERR, 'failed to open /dev/urandom: ', err)
else
    local random_str = f:read(4)
    f:close()
    seed = 0
    for i = 1, 4 do
        seed = seed * 256 + random_str:byte(i)
    end
end
uuid.seed(seed)

-- read configure file
f, err = io.open('/usr/local/openresty/nginx/conf/lua/cai.json', 'r')
assert(f, err)
local cai_conf = f:read("*a")
f:close()
cai_conf = cjson.decode(cai_conf)
assert(cai_conf, 'cai_conf json decode failed!')

-- set config
redis_conf = cai_conf['redis_conf']
editor_domain = cai_conf['editor_domain']
ip_black_list = cai_conf['ip_black_list']