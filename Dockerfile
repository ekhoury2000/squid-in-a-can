FROM debian:jessie
RUN apt-get -q update ;\
		apt-get -qy install squid3 ;\
		apt-get -qy install python
ADD squid-preamble.conf /tmp/
# I'd like to make this dynamic based on on local interfaces
RUN cat /etc/squid3/squid.conf > /tmp/squid-orig.conf ;\
		cat /tmp/squid-preamble.conf > /etc/squid3/squid.conf ;\
		cat /tmp/squid-orig.conf >> /etc/squid3/squid.conf ;\
 		sed -i "s/^#http_access allow localnet/http_access allow localnet/" /etc/squid3/squid.conf ;\
		mkdir -p /var/cache/squid3 ; chown -R proxy:proxy /var/cache/squid3
ADD deploy_squid.py /tmp/deploy_squid.py
CMD /tmp/deploy_squid.py
