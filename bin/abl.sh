#!/bin/bash
set -eu
# CASE=mixing_len:with_penalty; ROUGH="0.0001"
# CASE=mixing_len:no_penalty; ROUGH="0.0001"

ROUGH=0.01
SPONGE_STRENGTH=0.0

for CASE in gabls1:small; do
  for Ri in 0.01; do
    #"0" "0.01" "0.1" "1.0" "10.0"; do
abl -d gabls1 -c $CASE -n test -o 2 -w 1-00:00:00 --in-place False \
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
