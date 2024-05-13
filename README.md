# This openresty server is running my hexo blog.

## Setup OpenResty server

### Setup git repo for hexo blog

Run the following commands to setup a git repo for the hexo blog.

```bash
sudo adduser git
sudo su git
cd /home/git
git init --bare hexo.git
cat <<EOF | tee hexo.git/hooks/post-receive
#!/bin/sh
git --work-tree=/var/www/hexo --git-dir=/home/git/hexo.git checkout -f
EOF
chmod +x hexo.git/hooks/post-receive
```

### Make directory for hexo blog 

```bash
exit # exit from git user
sudo mkdir /var/www/hexo
sudo chown git:git /var/www/hexo
```

### Run redis on docker

```bash
docker run -itd --name blog-redis -p 6379:6379 redis --requirepass "thisispassword"
```

### Apply letsencrypt certificate

```bash
sudo apt-get install certbot
sudo certbot certonly --manual -d caiyifan.cn,www.caiyifan.cn --agree-tos --no-bootstrap --manual-public-ip-logging-ok --preferred-challenges dns-01 --server https://acme-v02.api.letsencrypt.org/directory
```

### Copy the json directory from git repo
```bash
sudo mkdir /usr/local/blog
sudo cp -r ./json /usr/local/blog/
```

### Run the openresty server

```bash
./run_docker.sh
```

## Setup local environment
```bash
ssh-copy-id git@<server_ip>
```
