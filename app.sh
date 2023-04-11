#!/bin/bash
caddy run --config /app/Caddyfile &
unbound -c /app/unbound.conf &
unbound -c /app/unbound2.conf &
rm /etc/dnsdist/dnsdist.conf
rm /etc/dnsdist.conf

test -e /etc/dnsdist/ || mkdir /etc/dnsdist/
(
    python3 -c 'from dnsdist_console import Key;print("setKey(\""+str(Key().generate())+"\")")'
    cat /app/dnsdist.mini.conf 
) > /dev/shm/dnsdist.conf


ln -s /dev/shm/dnsdist.conf /etc/dnsdist/dnsdist.conf
ln -s /dev/shm/dnsdist.conf /etc/dnsdist.conf

sh /launchjson.sh &
#coredns -conf /app/Corefile &
(dnsdist -C /dev/shm/dnsdist.conf --supervised 2>&1 |grep -v -e "Got control connection" -e "Closed control connection") &
sleep 3;
while (true);do (echo "showResponseLatency()";echo "showServers()")|dnsdist -C /dev/shm/dnsdist.conf -c;sleep 600;done &
wait -n
exit $?
