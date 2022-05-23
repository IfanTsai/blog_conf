#!/bin/bash

docker build -t my_blog .

docker run -itd -v /etc/letsencrypt:/etc/letsencrypt -v json:/usr/local/openresty/nginx/conf/json -v /etc/nginx/.htpasswd:/etc/nginx/.htpasswd -v /usr/sbin/modprobe:/usr/sbin/modprobe -v /lib/modules:/lib/modules -v /usr/src:/usr/src --net=host --rm --privileged my_blog
