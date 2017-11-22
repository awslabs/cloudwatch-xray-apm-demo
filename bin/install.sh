#!/bin/bash

# install cloudwatch logs
cd ~/aws-apm
./bin/tasks/1_install_cw_logsd.sh

# install collectd
cd ~/aws-apm
./bin/tasks/2_install_collectd.sh

# install xray daemon
cd ~/aws-apm
./bin/tasks/3_install_xrayd.sh

