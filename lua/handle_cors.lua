local ngx = ngx

ngx.header['Access-Control-Allow-Origin'] = 'https://www.caiyifan.cn'
--ngx.header['Access-Control-Allow-Origin'] = '*'
ngx.header['Access-Control-Allow-Headers'] = 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Content-Range,Range, userid, agent, brandid, language, token'

if 'OPTIONS' == ngx.req.get_method() then
    ngx.header['Access-Control-Max-Age'] = '1728000'
    ngx.header['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS, PUT, DELETE'
    ngx.header['Content-Length'] = '0'
    ngx.header['Content-Type'] = 'text/plain, charset=utf-8'
end
