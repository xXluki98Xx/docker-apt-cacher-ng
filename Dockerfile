FROM debian:buster-20200224-slim
LABEL MAINTAINER lramm

ENV APT_CACHER_NG_CACHE_DIR=/var/cache/apt-cacher-ng \
    APT_CACHER_NG_LOG_DIR=/var/log/apt-cacher-ng \
    APT_CACHER_NG_USER=apt-cacher-ng

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
      apt-cacher-ng ca-certificates wget git \
 && sed 's/# ForeGround: 0/ForeGround: 1/' -i /etc/apt-cacher-ng/acng.conf \
#  && sed 's/# BindAddress: localhost 192.168.7.254 publicNameOnMainInterface/BindAddress: 0.0.0.0/' -i /etc/apt-cacher-ng/acng.conf \
 && sed 's/# Port:3142/Port:3142/' -i /etc/apt-cacher-ng/acng.conf \
 && sed 's/# PassThroughPattern:.*this would allow.*/PassThroughPattern: .* #/' -i /etc/apt-cacher-ng/acng.conf \
 && sed 's*Remap-fedora:  file:fedora_mirrors*Remap-fedora: file:/etc/apt-cacher-ng/mirror_list.d/list.fedora #*' -i /etc/apt-cacher-ng/acng.conf \
 && sed 's/Remap-epel/# Remap-epel/' -i /etc/apt-cacher-ng/acng.conf \
 && echo 'Remap-centos: file:/etc/apt-cacher-ng/mirror_list.d/list.centos' >> /etc/apt-cacher-ng/acng.conf \
 && echo 'Remap-fedora-epel: file:/etc/apt-cacher-ng/mirror_list.d/list.fedora-epel' >> /etc/apt-cacher-ng/acng.conf \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir -p "/etc/apt-cacher-ng/mirror_list.d" \
    && git clone https://github.com/xXluki98Xx/apt-cacher-ng-remap.git \
    && cd apt-cacher-ng-remap \
    && bash centos.sh \
    && bash debian.sh \
    && bash fedora.sh \
    && bash fedora-epel.sh \
    && mv list.* /etc/apt-cacher-ng/mirror_list.d/ \
    && chmod -R 0755 /etc/apt-cacher-ng/mirror_list.d/ \
    && chown -R ${APT_CACHER_NG_USER}:root /etc/apt-cacher-ng/mirror_list.d/

COPY entrypoint.sh /sbin/entrypoint.sh

RUN chmod 755 /sbin/entrypoint.sh

EXPOSE 3142/tcp

HEALTHCHECK --interval=10s --timeout=2s --retries=3 \
    CMD wget -q -t1 -o /dev/null  http://localhost:3142/acng-report.html || exit 1

ENTRYPOINT ["/sbin/entrypoint.sh"]

CMD ["/usr/sbin/apt-cacher-ng"]
