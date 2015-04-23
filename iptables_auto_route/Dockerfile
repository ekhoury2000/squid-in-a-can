FROM squidinacan_base:latest

RUN apt-get -q update && \
    apt-get -qy install iptables && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD deploy.py /tmp/deploy.py
CMD /tmp/deploy.py
