#!/bin/bash
# crontab: 0 0 * * * /bin/bash /usr/local/openresty/nginx/conf/shell/cut_log.sh >/dev/null 2>&1

logs_path=/usr/local/openresty/nginx/logs/
pid_path=/usr/local/openresty/nginx/logs/nginx.pid

servers=('ngx' 'hexo' 'api' 'test' 'grafana')

for s in ${servers[@]}; do
    mv ${logs_path}${s}/access.log ${logs_path}${s}/access-$(date -d "yesterday" +%Y-%m-%d).log
    mv ${logs_path}${s}/error.log ${logs_path}${s}/error-$(date -d "yesterday" +%Y-%m-%d).log
done

#mv ${logs_path}error.log ${logs_path}error-$(date -d "yesterday" +%Y-%m-%d).log

kill -USR1 `cat ${pid_path}`
