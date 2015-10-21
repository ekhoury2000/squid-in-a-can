FROM debian:jessie
RUN apt-get -q update
RUN apt-get -qy install python ccze net-tools
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
