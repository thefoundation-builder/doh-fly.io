#!/bin/bash
sh /launchjson.sh &
#coredns -conf /app/Corefile &
dnsdist -C /app/dnsdist.conf --supervised &
unbound -c /app/unbound.conf &
unbound -c /app/unbound2.conf &
caddy run --config /Caddyfile &

wait -n
exit $?
