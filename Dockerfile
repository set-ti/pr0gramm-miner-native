FROM node:alpine

# install curl bash git cmake make gcc g++ autoconf automake pkgconf libtool libc-dev libuv-dev curl-dev openssl-dev
RUN apk add --no-cache curl bash git cmake make gcc g++ autoconf automake pkgconf libtool libc-dev libuv-dev curl-dev openssl-dev

# download CUDA
RUN curl -L https://developer.nvidia.com/compute/cuda/8.0/Prod2/local_installers/cuda_8.0.61_375.26_linux-run -o cuda-linux.run

# make the run file executable and extract
RUN chmod +x cuda-linux.run
RUN ./cuda-linux.run --tar mxvf

# install CUDA
RUN sh /run_files/cuda-linux64-rel-8.0.61-21551265.run -noprompt -prefix=/usr/local/cuda-8
RUN ln -s /usr/local/cuda-8 /usr/local/cuda

# add CUDA to PATH
ENV PATH=/usr/local/cuda/bin:$PATH LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

# install glibc
RUN ALPINE_GLIBC_BASE_URL="https://github.com/sgerrand/alpine-pkg-glibc/releases/download" && \
    ALPINE_GLIBC_PACKAGE_VERSION="2.25-r0" && \
    ALPINE_GLIBC_BASE_PACKAGE_FILENAME="glibc-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_BIN_PACKAGE_FILENAME="glibc-bin-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_I18N_PACKAGE_FILENAME="glibc-i18n-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    apk add --no-cache --virtual=.build-dependencies wget ca-certificates && \
    wget \
        "https://raw.githubusercontent.com/andyshinn/alpine-pkg-glibc/master/sgerrand.rsa.pub" \
        -O "/etc/apk/keys/sgerrand.rsa.pub" && \
    wget \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    apk add --no-cache \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    \
    rm "/etc/apk/keys/sgerrand.rsa.pub" && \
    /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 C.UTF-8 || true && \
    echo "export LANG=C.UTF-8" > /etc/profile.d/locale.sh && \
    \
    apk del glibc-i18n && \
    \
    rm "/root/.wget-hsts" && \
    apk del .build-dependencies && \
    rm \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME"

ENV LANG=C.UTF-8

# clone and install ccminer
RUN git clone -b linux https://github.com/tpruvot/ccminer /ccminer
WORKDIR /ccminer
RUN ./autogen.sh
RUN ./configure CUDA_CFLAGS='--shared --compiler-options "-fPIC"' --prefix=/usr --sysconfdir=/etc --libdir=/usr/lib --with-cuda=/usr/local/cuda
RUN make

# Node.js package to keep the proxy running in case of failure
RUN npm -g i forever

# clone and install Fusl's fork of xmrig
RUN git clone https://github.com/Fusl/xmrig /xmrig
WORKDIR /xmrig
RUN cmake .
RUN make

# Add Node.js proxy server to container
ADD xm /xm
WORKDIR /xm
RUN npm i

ADD run.sh /xmrig

WORKDIR /xmrig
ENTRYPOINT ["./run.sh"]
