#!/bin/bash

docker build -t my_blog --progress=plain .

docker volume create openresty

docker run -itd -v \
/etc/letsencrypt:/etc/letsencrypt \
-v /etc/nginx/.htpasswd:/etc/nginx/.htpasswd \
-v /usr/sbin/modprobe:/usr/sbin/modprobe \
-v /lib/modules:/lib/modules \
-v /usr/src:/usr/src \
-v /var/www/hexo:/var/www/hexo \
-v /usr/local/blog/json:/usr/local/openresty/nginx/conf/json \
-v openresty:/usr/local/openresty \
--net=host --rm --privileged my_blog
