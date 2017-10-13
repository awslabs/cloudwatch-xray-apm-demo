#!/bin/bash

# Installs cloudWatch Logs Daemon
cd ~
sudo yum install -y awslogs
sudo service awslogs stop
sudo cp /etc/awslogs/awslogs.conf /etc/awslogs/awslogs.conf.bkp
sudo cp ~/aws-apm/config/cw_logs/cw_logs.conf /etc/awslogs/awslogs.conf
sudo service awslogs start
sudo chkconfig awslogs on