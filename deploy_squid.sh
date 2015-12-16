#!/bin/busybox sh
export PATH=/libexec:$PATH

# This instant images come with a dep list of cached
# install packages, install shouldn't take long
cat /tmp/deps.list | time xargs -n 1 -- sudo -u tc tce-load -ci


# 32bit ldconfig is broken under 64bit kernelspace on ulibc I think
# LD_LIBRARY_PATH seems to not make it into subshells
# ldconfig also seems broken and doesn't update
# So after our packages are installed wi link into /usr/lib
#ln -s /usr/local/lib/* /usr/lib
#export LD_LIBRARY_PATH=/usr/local/lib


#[ -n "$DISK_CACHE_SIZE" ] || DISK_CACHE_SIZE=5000
#[ -n "$MAXIMUM_CACHE_OBJECT" ] || MAXIMUM_CACHE_OBJECT=1024

# Maybe use a template
#echo "Setting DISK_CACHE_SIZE $DISK_CACHE_SIZE"
#echo cache_dir ufs /data $DISK_CACHE_SIZE 16 256\
		 #>> /usr/local/squid/etc/squid.conf

#echo "Setting MAXIMUM_CACHE_OBJECT $MAXIMUM_CACHE_OBJECT"
#echo maximum_object_size $MAXIMUM_CACHE_OBJECT\
#		 >> /usr/local/squid/etc/squid.conf
# Generate our ssl certificate
[ -n "$CA_SUBJ" ] || CA_SUBJ="/C=US/ST=Oregon/L=Portland/O=Instant Infrastructure/OU=Internet Speedups/CN=proxy.intercept"
[ -d /squid/ssl/certs ] || mkdir -p /squid/ssl/certs
[ -d /squid/ssl/private ] || mkdir -p /squid/ssl/private
[ -f /squid/ssl/private/ca.key ] || \
		openssl req -x509 -newkey rsa:1024 \
						-keyout /squid/ssl/private/ca.key \
						-out /squid/ssl/certs/ca.crt -days 3650 \
						-nodes -subj "$CA_SUBJ"
[ -f /squid/ssl/browser.der ] || \
		openssl x509 -outform der \
						-in /squid/ssl/certs/ca.crt\
						-out /squid/ssl/browser.der
CAFILE=/squid/ssl/certs/`openssl x509 -hash -noout -in /squid/ssl/certs/ca.crt`.0
[ -f $CAFILE ] || cp /squid/ssl/certs/ca.crt $CAFILE
[ -f /squid/ssl/ca/ca-certificates.crt ] || cp /squid/ssl/certs/ca.crt /squid/ssl/certs/ca-certificates.crt 


openssl x509 -text -in /squid/ssl/browser.der -inform der | head -11

mkdir -p /squid/cache
mkdir -p /squid/log
mkdir -p /squid/ssl
# touch /squid/log/cache
# /var/logs /var/log/squid
ssl_crtd -c -s /squid/ssl/db
chown -R nobody:nogroup /squid/cache /squid/log /squid/ssl
#chown -R nobody:nogroup /squid
#/var/logs /var/log/squid
# mkdir -p /usr/local/squid/var/lib
# chown -R nobody:nogroup 
squid -z
tail -F /squid/log/access &
# Would be nice to run thees when socket comes online
#$(sleep 5 ;  iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to 3129 )&
#$(sleep 6 ;  iptables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to 3130 )&
echo Run these if you want transparant caching
echo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to 3129
echo
echo for ssl you will need to load /squid/ssl/certs into your clients
echo iptables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to 3130

squid -N
# Would be nice to trap these
#echo IPTABLESDOWN
#iptables -t nat -D PREROUTING -p tcp --dport 80 -j REDIRECT --to 3129 
#iptables -t nat -D PREROUTING -p tcp --dport 443 -j REDIRECT --to 3130
#-f /data/squid.conf
# openssl x509 -hash -noout -in /etc/ssl/certs/charles.pem
#  cp /etc/ssl/certs/charles.pem /etc/ssl/certs/`openssl x509 -hash -noout -in /etc/ssl/certs/charles.pem`.0
