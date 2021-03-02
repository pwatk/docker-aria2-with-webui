FROM alpine

LABEL maintainer pwatk

ARG OS="linux"
ARG ARCH="amd64"
ARG S6_ARCH="amd64"

ENV \
PS1="$(whoami)@$(hostname):$(pwd)\\$ " \
HOME="/root" \
TERM="xterm" \
IPV6="false" \
BT_SEEDING="true" \
BT_TRACKER="true"

RUN \
 echo "**** install build packages ****" && \
 apk add --no-cache --virtual=build-dependencies \
	unzip \
	git \
	build-base \
	automake \
	autoconf \
	gettext-dev \
	libtool \
	gnutls-dev \
	expat-dev \
	sqlite-dev \
	c-ares-dev \
	zlib-dev \
	nettle-dev \
	libssh2-dev && \
 echo "**** install runtime packages ****" && \
 apk add --no-cache \
	tzdata \
	bash \
	darkhttpd \
	ca-certificates \
	gnutls \
	expat \
	sqlite-libs \
	c-ares \
	zlib \
	nettle \
	libssh2 \
	libgcc \
	libstdc++ \
	curl \
	coreutils \
	procps \
	shadow \
	logrotate && \
 echo "**** create user and directories ****" && \
 useradd -u 911 -U -G users -d /config -s /bin/false abc && \
 mkdir -p \
	/app \
	/config \
	/defaults && \
 echo "**** fix logrotate ****" && \
 sed -i "s|/var/log/messages {}.*| |" /etc/logrotate.conf && \
 sed -i "s|logrotate /etc/logrotate.conf|logrotate /etc/logrotate.conf -s /config/log/logrotate.status|" \
	/etc/periodic/daily/logrotate && \
 echo "**** install s6-overlay ****" && \
 S6_VERSION=$(curl -sX GET "https://api.github.com/repos/just-containers/s6-overlay/releases/latest" \
	| awk '/tag_name/{print $4;exit}' FS='[""]') && \
 curl \
	-o /tmp/s6-overlay-${S6_ARCH}.tar.gz -L \
	https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/s6-overlay-${S6_ARCH}.tar.gz && \
 tar xzf /tmp/s6-overlay-${S6_ARCH}.tar.gz -C / && \
 echo "**** install aria2 ****" && \
 ARIA2_VERSION=$(curl -sX GET "https://api.github.com/repos/aria2/aria2/releases/latest" \
	| awk '/tag_name/{print $4;exit}' FS='[""]') && \
 curl \
	-o /tmp/aria2.tar.gz -L \
	https://github.com/aria2/aria2/releases/download/${ARIA2_VERSION}/${ARIA2_VERSION/release/aria2}.tar.gz && \
 tar xzf /tmp/aria2.tar.gz -C /tmp/ && \
 ( \
	 cd /tmp/${ARIA2_VERSION/release/aria2} && \
	 autoreconf -i && \
	 ./configure CXXFLAGS="-Os -s" \
		--prefix=/usr \
		--sysconfdir=/etc \
		--mandir=/usr/share/man \
		--infodir=/usr/share/info \
		--localstatedir=/var \
		--disable-nls \
		--with-ca-bundle=/etc/ssl/certs/ca-certificates.crt && \
	 make -j $(getconf _NPROCESSORS_ONLN) && \
	 install -Dm 0755 src/aria2c /usr/bin/aria2c \
 ) && \
 echo "**** install AriaNg ****" && \
 mkdir -p /app/AriaNg && \
 ARIANG_VERSION=$(curl -sX GET "https://api.github.com/repos/mayswind/AriaNg/releases/latest" \
	| awk '/tag_name/{print $4;exit}' FS='[""]') && \
 curl \
	-o /tmp/AriaNg.zip -L \
	https://github.com/mayswind/AriaNg/releases/download/${ARIANG_VERSION}/AriaNg-${ARIANG_VERSION}.zip && \
 unzip /tmp/AriaNg.zip -d /app/AriaNg && \
 echo "**** cleanup ****" && \
 rm -rf /tmp/* && \
 apk del --purge build-dependencies

COPY root/ /

VOLUME /config /data
EXPOSE 80 6800 6881-6999 6881-6999/udp

ENTRYPOINT ["/init"]
