#!/bin/bash
caddy fmt --config /app/Caddyfile
caddy run --config /app/Caddyfile &

rm /etc/dnsdist/dnsdist.conf
rm /etc/dnsdist.conf

test -e /etc/dnsdist/ || mkdir /etc/dnsdist/
(
    python3 -c 'from dnsdist_console import Key;print("setKey(\""+str(Key().generate())+"\")")'
    cat /app/dnsdist.mini.conf 
) > /dev/shm/dnsdist.conf


ln -s /dev/shm/dnsdist.conf /etc/dnsdist/dnsdist.conf
ln -s /dev/shm/dnsdist.conf /etc/dnsdist.conf

(dnsdist -C /dev/shm/dnsdist.conf --supervised 2>&1 |grep -v -e "Got control connection" -e "Closed control connection") &

unbound -c /app/unbound.conf &
unbound -c /app/unbound2.conf &

sh /launchjson.sh &

sleep 2
#coredns -conf /app/Corefile &
nslookup        ya.ru 127.0.0.1 &>/dev/null &
nslookup      ghcr.io 127.0.0.1 &>/dev/null &
nslookup    apple.com 127.0.0.1 &>/dev/null &
nslookup   github.com 127.0.0.1 &>/dev/null &
nslookup   gitlab.com 127.0.0.1 &>/dev/null &
nslookup   google.com 127.0.0.1 &>/dev/null &
nslookup mirosoft.com 127.0.0.1 &>/dev/null & 

sleep 15;

while (true);do (echo "showResponseLatency()";echo "showServers()")|dnsdist -C /dev/shm/dnsdist.conf -c;sleep 600;done &
wait -n
exit $?
