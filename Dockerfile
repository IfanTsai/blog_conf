ARG RESTY_IMAGE_BASE="ubuntu"
ARG RESTY_IMAGE_TAG="20.04"

FROM ${RESTY_IMAGE_BASE}:${RESTY_IMAGE_TAG}

LABEL maintainer="Ifan Tsai <i@caiyifan.cn>"

ENV TZ=Asia/Shanghai

ARG DEBIAN_FRONTEND=noninteractive
ARG RESTY_VERSION="1.25.3.1"

RUN ["/bin/bash", "-c", "apt update \
    && apt install -y libpcre3-dev libz-dev libssl-dev perl \
        gcc make cmake wget git \
    && cd /tmp \
    && wget https://openresty.org/download/openresty-${RESTY_VERSION}.tar.gz \
    && tar xzf openresty-${RESTY_VERSION}.tar.gz \
    && cd openresty-${RESTY_VERSION} \
    && ./configure --with-cc-opt='-O3' --with-http_v2_module --with-http_realip_module --with-http_stub_status_module \
    && make -j4 \
    && make install \
    && cd /tmp \
    && rm -rf openresty-${RESTY_VERSION}.tar.gz openresty-${RESTY_VERSION} \
    && apt install -y curl zip bison build-essential cmake flex git libedit-dev \
       libllvm12 llvm-12-dev libclang-12-dev python zlib1g-dev libelf-dev libfl-dev python3-setuptools \
       liblzma-dev arping netperf iperf \
    && git clone https://github.com/iovisor/bcc.git \
    && mkdir bcc/build; cd bcc/build \
    && cmake .. \
    && make -j4 \
    && make install \
    && cmake -DPYTHON_CMD=python3 .. \
    && pushd src/python/ \
    && make \
    && make install \
    && popd \
    && cd /tmp \
    && rm -rf bcc \
    && cd /usr/local/openresty/nginx/logs \
    && mkdir api grafana hexo ngx test \
    && apt install -y liblua5.1-0-dev python3.8-dev \
    && export PATH=/usr/local/openresty/bin:$PATH \
    && opm get thibaultcha/lua-resty-jit-uuid \
                ledgetech/lua-resty-http \
                anjia0532/lua-resty-redis-util \
                knyar/nginx-lua-prometheus \
                jkeys089/lua-resty-hmac \
    && rm -rf /var/cache/apk \
    && rm -rf /var/lib/apt/lists \
    && apt purge -y python gcc make cmake wget git curl bison flex \
    && apt autoremove -y \
    && apt autoclean -y"]

ENV PATH=$PATH:/usr/local/openresty/luajit/bin:/usr/local/openresty/nginx/sbin:/usr/local/openresty/bin

WORKDIR /usr/local/openresty/nginx

COPY . conf

CMD ["/usr/local/openresty/nginx/sbin/nginx", "-g", "daemon off;"]

STOPSIGNAL SIGQUIT
