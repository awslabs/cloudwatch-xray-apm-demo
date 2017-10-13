#!/bin/bash

# Installs this repo so you can run the examples
sudo yum update -y
sudo yum install -y git
sudo yum install -y gcc
sudo yum install -y ruby-devel
gem install bundler
cd ~ && git clone https://github.com/marcosortiz/aws-apm.git && cd aws-apm && git checkout dev && mkdir logs && bundle install