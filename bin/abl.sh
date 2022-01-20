#!/bin/bash
set -eu
# CASE=mixing_len:with_penalty; ROUGH="0.0001"
# CASE=mixing_len:no_penalty; ROUGH="0.0001"

ROUGH=0.000456
SPONGE_STRENGTH=0.0

for CASE in buoy_test:no_vp_sponge; do
  for Ri in 0.01; do
    #"0" "0.01" "0.1" "1.0" "10.0"; do
abl -d buoy_test_sponge -c $CASE -n sponge -o 2 -w 1-00:00:00 --in-place False \
  -s mixing_len \
  -b moeng \
  -ri $Ri \
  -zw $ROUGH -z0 $ROUGH \
  -bb flux \
  -bt insulated \
  -p 0.0 \
  -ss $SPONGE_STRENGTH \
  $* &
# sleep 5
  done
done
