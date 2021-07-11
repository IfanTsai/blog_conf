local ngx = ngx
local cjson = require 'cjson.safe'
local uuid  = require 'resty.jit-uuid'
local process = require 'ngx.process'
local python = require 'python'
-- https://github.com/openresty/openresty/issues/510
zlib = require 'zlib'

local conf_path = '/usr/local/openresty/nginx/conf/json/conf.json'

-- table.new     = require 'table.new'
-- table.isempty = require 'table.isempty'
-- table.isarray = require 'table.isarray'
-- table.nkeyss  = require 'table.nkeys'
-- table.clone   = require 'table.clone'

cjson.encode_empty_table_as_object(false)

python.execute('import sys')
python.execute('sys.path.insert(0, "/usr/local/openresty/nginx/conf/python/")')

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
f, err = io.open(conf_path, 'r')
assert(f, err)
local cai_conf = f:read('*a')
f:close()
cai_conf, err = cjson.decode(cai_conf)
assert(cai_conf, err)

-- set config
redis_conf    = cai_conf['redis_conf']
editor_domain = cai_conf['editor_domain']
auth_md5      = cai_conf['auth_md5']
auth_salt     = cai_conf['auth_salt']
qmsg_key      = cai_conf['qmsg_key']

-- enable privileged process
local ok
ok, err = process.enable_privileged_agent()
assert(ok, err)