local _M = { _VERSION = '0.01' }

_M.init_conf = function(conf_tab)
    _M.redis_conf        = conf_tab['redis_conf']
    _M.editor_domain     = conf_tab['editor_domain']
    _M.auth_md5          = conf_tab['auth_md5']
    _M.auth_salt         = conf_tab['auth_salt']
    _M.qmsg_key          = conf_tab['qmsg_key']
    _M.qcloud_secret_id  = conf_tab['qcloud_secret_id']
    _M.qcloud_secret_key = conf_tab['qcloud_secret_key']
end

_M.add_conf = function(key, value)
    _M[key] = value
end

return _M