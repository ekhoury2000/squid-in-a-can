FROM this/squid
ADD mime.conf squid.conf /etc/
# I'd like to make this dynamic based on on local interfaces
ADD deploy_squid.sh /deploy_squid.sh
VOLUME /squid
CMD /deploy_squid.sh
