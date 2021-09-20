#!/bin/bash
set -eu
# CASE=mixing_len:with_penalty; ROUGH="0.0001"
# CASE=mixing_len:no_penalty; ROUGH="0.0001"

CASE=buoy_test:variable_properties
# CASE=buoy_test:no_variable_properties
ROUGH=0.000456; Ri=0.25

abl -d buoy -c $CASE -n penalty -o 1 -w 7-00:00:00 --in-place False \
  -s mixing_len \
  -b noslip \
  -ri $Ri \
  -zw $ROUGH -z0 $ROUGH \
  -p -1e-9 \
  $*
