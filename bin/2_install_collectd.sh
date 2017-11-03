#!/bin/bash

# Installs collectd
cd ~
sudo yum -y install collectd-python
sudo yum -y install collectd
wget https://raw.githubusercontent.com/awslabs/collectd-cloudwatch/master/src/setup.py
chmod u+x setup.py
sudo ./setup.py -m not_modify -I
sudo service collectd stop
sudo cp /etc/collectd.conf /etc/collectd.conf.bkp
sudo cp ~/aws-apm/config/collectd/collectd.conf /etc/collectd.conf
sudo cp ~/aws-apm/config/collectd/cw_plugin/collectd-cloudwatch.conf /etc/collectd-cloudwatch.conf
sudo cp ~/aws-apm/config/collectd/cw_plugin/cw_plugin.conf /opt/collectd-plugins/cloudwatch/config/plugin.conf
sudo cp ~/aws-apm/config/collectd/cw_plugin/whitelist.conf /opt/collectd-plugins/cloudwatch/config/whitelist.conf
sudo service collectd start
sudo chkconfig collectd on
