FROM squidinacan_base:latest
#FROM this/squid
ADD mime.conf squid.conf /etc/
# I'd like to make this dynamic based on on local interfaces
ADD deploy_squid.sh /deploy_squid.sh
VOLUME /squid
CMD /deploy_squid.sh
#FROM debian:jessie
#RUN apt-get -q update && apt-get -qy install python squid3
#RUN sed -i "s/^#acl localnet/acl localnet/" /etc/squid3/squid.conf
#RUN sed -i "s/^#http_access allow localnet/http_access allow localnet/" /etc/squid3/squid.conf
#RUN mkdir -p /var/cache/squid3
#RUN chown -R proxy:proxy /var/cache/squid3
#ADD deploy_squid.py /tmp/deploy_squid.py
#CMD /tmp/deploy_squid.py
