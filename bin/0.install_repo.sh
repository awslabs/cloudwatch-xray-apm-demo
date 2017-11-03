#!/bin/bash

# Installs this repo so you can run the examples
sudo yum update -y
sudo yum install -y git
sudo yum install -y gcc
sudo yum install -y ruby-devel
gem install bundler
cd ~ && git clone https://github.com/awslabs/cloudwatch-xray-apm-demo.git aws-apm && cd aws-apm && git checkout initial-version && mkdir logs && bundle install

# install cloudwatch logs
cd ~/aws-apm
./bin/1_install_cw_logsd.sh

# install collectd
cd ~/aws-apm
./bin/2_install_collectd.sh

# install xray daemon
cd ~/aws-apm
./bin/3_install_xrayd.sh