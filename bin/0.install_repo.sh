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

# Create log group and metric filters
export AWS_DEFAULT_REGION=us-east-1
aws logs put-metric-filter \
  --log-group-name aws-apm-demo/my_app \
  --filter-name FactorialLatency \
  --filter-pattern '[recorded_at, severity, flag="my_app.metrics", k1, v1, k2, v2]' \
  --metric-transformations \
  'metricName=log.latency.factorial-average,metricNamespace=collectd,metricValue=$v1,defaultValue=0'

aws logs put-metric-filter \
  --log-group-name aws-apm-demo/my_app \
  --filter-name FibonacciLatency \
  --filter-pattern '[recorded_at, severity, flag="my_app.metrics", k1, v1, k2, v2]' \
  --metric-transformations \
  'metricName=log.latency.fibonacci-average,metricNamespace=collectd,metricValue=$v2,defaultValue=0'

