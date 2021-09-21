FROM ubuntu:18.04

ARG UNVR_FW_URL
ARG ARCH=amd64

VOLUME /srv/unifi-protect/backups
VOLUME /var/lib/postgresql
EXPOSE 1935/tcp 7444/tcp 7447/tcp 6666/tcp 7442/tcp 7004/udp 7080/tcp 7443/tcp 7445/tcp 7446/tcp

WORKDIR /var/unvr/install

# Install build tools
RUN apt update \
    && apt install -y wget binwalk dpkg-repack dpkg \

COPY extract_packages.sh extract_packages.sh

RUN chmod +x extract_packages.sh \
    && ./extract_packages.sh $UNVR_FW_URL $ARCH \
    && cp *.deb /var/cache/apt/archives/ \
    && mv unifi-protect*.deb unifi-protect.deb \
    && dpkg -i unifi-protect.deb \
    && apt install -y -f \
    && rm -f *.deb

# Cleanup
RUN apt-get remove --purge --auto-remove -y wget \
 && rm -rf /var/cache/apt/lists/*

# Initialize based on /usr/share/unifi-protect/app/hooks/pre-start
RUN pg_ctlcluster 10 main start \
 && su postgres -c 'createuser unifi-protect -d' \
 && pg_ctlcluster 10 main stop \
 && ln -s /srv/unifi-protect/logs /var/log/unifi-protect \
 && mkdir /srv/unifi-protect /srv/unifi-protect/backups /var/run/unifi-protect \
 && chown unifi-protect:unifi-protect /srv/unifi-protect /srv/unifi-protect/backups /var/run/unifi-protect \
 && ln -s /tmp /srv/unifi-protect/temp

# Configure
COPY config.json /etc/unifi-protect/config.json

# Supply simple script to run postgres and unifi-protect
COPY init /init
CMD ["/init"]