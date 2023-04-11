#!/bin/bash
caddy run --config /app/Caddyfile &
unbound -c /app/unbound.conf &
unbound -c /app/unbound2.conf &


(
    python3 -c 'from dnsdist_console import Key;print("setKey(\""+str(Key().generate())+"\")")'
    cat /app/dnsdist.mini.conf 
) > /dev/shm/dnsdist.conf
sh /launchjson.sh &
#coredns -conf /app/Corefile &
dnsdist -C /dev/shm/dnsdist.conf --supervised &


wait -n
exit $?
