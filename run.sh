#!/usr/bin/env bash

export PR0GRAMM_USER=${PR0GRAMM_USER:-holzmaster}
export NUM_THREADS_ALT=$(($(grep '^processor' /proc/cpuinfo | wc -l)/2))
export NUM_THREADS=${NUM_THREADS:-$NUM_THREADS_ALT}

echo "User $PR0GRAMM_USER will receive mining rewards."
echo "Will use $NUM_THREADS threads."

echo "Starting proxy."
forever start /xm/xmrbr.js

echo "Waiting 5s for proxy to initialize."
sleep 5s

echo "Starting miner."
#./xmrig --print-time=15 --max-cpu-usage=100 -t $NUM_THREADS -a cryptonight -o stratum+tcp://127.0.0.1:12345 -u x -p x $XMRIG_OPTS
./xmrMiner --url=stratum+tcp://127.0.0.1:12345 --launch=10x24 --bfactor=4 --bsleep=100 --user=x -p x --donate=0
