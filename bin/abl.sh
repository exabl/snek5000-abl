#!/bin/bash
set -eu
# CASE=mixing_len:with_penalty; ROUGH="0.0001"
# CASE=mixing_len:no_penalty; ROUGH="0.0001"

ROUGH=0.0; Ri=6.0

for CASE in buoy_test:no_vp_sponge; do
  for SPONGE_STRENGTH in "0.01" "0.1" "1.0" "10.0"; do
abl -d buoy_test_sponge -c $CASE -n sponge -o 2 -w 1-00:00:00 --in-place False \
  -s mixing_len \
  -b noslip \
  -ri $Ri \
  -zw $ROUGH -z0 $ROUGH \
  -bb flux \
  -p 0.0 \
  -ss $SPONGE_STRENGTH \
  $* &
sleep 5
  done
done
