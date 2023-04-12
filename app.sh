#!/bin/bash
date -u +%s > /tmp/.starttime
caddy fmt --overwrite /app/Caddyfile
caddy run --config /app/Caddyfile &

rm /etc/dnsdist/dnsdist.conf &>/dev/null
rm /etc/dnsdist.conf &>/dev/null

test -e /etc/dnsdist/ || mkdir /etc/dnsdist/
(
    python3 -c 'from dnsdist_console import Key;print("setKey(\""+str(Key().generate())+"\")")'
    cat /app/dnsdist.mini.conf 
) > /dev/shm/dnsdist.conf

grep -v addDOHLocal  /dev/shm/dnsdist.conf |sed 's/127\.0\.0\.5/127.0.0.7/g;s/127\.0\.0\.6/127.0.0.8/g;s/:5199/:5200/g' > /dev/shm/dnsdist2.conf



ln -s /dev/shm/dnsdist.conf /etc/dnsdist/dnsdist.conf  &>/dev/null &
ln -s /dev/shm/dnsdist.conf /etc/dnsdist.conf          &>/dev/null &

(dnsdist -C /dev/shm/dnsdist.conf --supervised 2>&1 |grep -v -e "Got control connection" -e "Closed control connection") &
(dnsdist -C /dev/shm/dnsdist2.conf --supervised 2>&1 |grep -v -e "Got control connection" -e "Closed control connection") &

unbound -c /app/unbound.conf &
unbound -c /app/unbound2.conf &

sh /launchjson.sh &

sleep 2
#coredns -conf /app/Corefile &
(nslookup        ya.ru 127.0.0.5 &>/dev/null || true ) &
sleep 1
(nslookup      ghcr.io 127.0.0.5 &>/dev/null || true ) &
sleep 1
(nslookup    apple.com 127.0.0.5 &>/dev/null || true ) &
sleep 1
(nslookup   github.com 127.0.0.5 &>/dev/null || true ) &
sleep 1
(nslookup   gitlab.com 127.0.0.5 &>/dev/null || true ) &
sleep 1
(nslookup   google.com 127.0.0.5 &>/dev/null || true ) &
sleep 1
(nslookup mirosoft.com 127.0.0.5 &>/dev/null || true ) & 

sleep 5;

(while (true);do timediff=$(($(date -u  +%s)-$(cat /tmp/.starttime)));  
   echo "dumpStats()"|dnsdist -C /dev/shm/dnsdist.conf  -c|grep -e drop -e err -e servf -e uptime
 ( (echo "showResponseLatency()";echo "showServers()")|dnsdist -C /dev/shm/dnsdist.conf -c || true ) |sed 's/^/doh:up:'"${timediff}"' s |/g' ;

  echo "dumpStats()"|dnsdist -C /dev/shm/dnsdist2.conf  -c|grep -e drop -e err -e servf -e uptime
 ( (echo "showResponseLatency()";echo "showServers()")|dnsdist -C /dev/shm/dnsdist2.conf -c || true ) |sed 's/^/doh:up:'"${timediff}"' s |/g' ;
 
 sleep 1800;done )
#wait -n
#exit $?
