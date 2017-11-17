# aws-apm
This app was used during the demo for the ARC315 session on re:Invent at 11/29/2017.

Here is the overall architecture diagram for this demo:
![alt text](https://github.com/awslabs/cloudwatch-xray-apm-demo/blob/master/img/arc_diagram.png)

When you follow the installation instructions, the following will be installed on your instance:
1. The sample app (my_app) from this git repo.
2. Collectd with the following plugins enabled:
  2.1 ![cloudwatch plugin](https://github.com/awslabs/collectd-cloudwatch).
  2.2 ![statsd plugin](https://collectd.org/wiki/index.php/Plugin:StatsD).
3. ![Cloudwatch Logs Agent](http://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/QuickStartEC2Instance.html).
4. ![X-Ray Daemon](http://docs.aws.amazon.com/xray/latest/devguide/xray-daemon.html).

When you run this application, it will log data into a log file, send metrics to collectd and traces to the X-Ray daemon every second. 

> **Note:** Since cloudwatch logs agent will be forwarding those logs to CloudWatch, collectd will be sending those metrics to CloudWatch and X-Ray daemon will be sending the traces to X-Ray, you will be charged for all the data you send to CloudWatch an X-Ray.

## 1) Requirements

### 1.1) EC2 instance
This application has only been tested on the latest Amazon Linux AMI. The instance needs to have access to the internate in order to install all the packages needed and send data to CloudWatch and X-Ray.

This demo runs on an EC2 instance and a t2.micro instance can handle it. 

### 1.2) IAM permissions

Make sure your EC2 uses an IAM role with the following permissions:

IAM permissions for CollectD:
```json
{
    "Version":"2012-10-17",
    "Statement":[
        {
            "Effect":"Allow",
            "Action":[
                "cloudwatch:PutMetricData",
                "cloudwatch:PutDashboard"
            ],
            "Resource":[
                "*"
            ]
        }
    ]
}
```

IAM permissions for the CloudWatch Logs Agent:
```json
{
    "Version":"2012-10-17",
    "Statement":[
        {
            "Effect":"Allow",
            "Action":[
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:putMetricFilter",
                "logs:DescribeLogStreams"
            ],
            "Resource":[
                "arn:aws:logs:*:*:*"
            ]
        }
    ]
}
```

IAM permissions for the X-Ray Agent:
```json
{
    "Version":"2012-10-17",
    "Statement":[
        {
            "Effect":"Allow",
            "Action":[
                "xray:PutTraceSegments",
                "xray:PutTelemetryRecords"
            ],
            "Resource":[
                "*"
            ]
        }
    ]
}
```

## 2) Installation
To install this demo, SSH to your EC2 instance and follow the type the commands bellow:

```bash
sudo yum update -y
sudo yum install -y git
sudo yum install -y gcc
sudo yum install -y ruby-devel
gem install bundler
cd ~ && git clone https://github.com/awslabs/cloudwatch-xray-apm-demo.git aws-apm && cd aws-apm && git checkout initial-version && mkdir logs && bundle install
cd ~/aws-apm
./bin/install.sh
```

## 3) Running the App

To run the app:
```bash
cd ~/aws-apm
bundle exec samples/apps/my_app.rb
```
You can stop it by typing ``Ctrl+C``.

To run it on the background:
```bash
cd ~/aws-apm
nohup bundle exec samples/apps/my_app.rb &
```
You can stop it by running ``pkill -f my_app.rb``.

### 3.1) Checking that the app is running
Check the appliation's log:
```bash
tail -100f ~/aws-apm/logs/my_app.log
```

### 3.2) Checking that collectd is sending metrics to CloudWatch
Check collectd logs:
```bash
tail -100f /var/log/collectd.log
```
### 3.3) Checking that the cloudwatch logs agant is log entries to CloudWatch
Check the cloudwatch logs agent log:
```bash
tail -100f /var/log/awslogs.log
```
### 3.4) Checking that the xray daemon is sending traces to X-Ray
Check the xray daemon logs:
```bash
tail -100f /var/log/xray/xray.log
```

## 4. UDP vs Logging Lattency Script
This script demonstrates how much lattency logging can introduce in your apps compared to sending metrics via UDP. The script will log n lines and also send n0 metrics to collectd via UDP.
>**Note:** n is one of the input parameters you can send to the script. The first parameter is the udp port to send the metrics to (collectd listens on port 8125), the second one is the number of lines to log and udp packages to send.

For example, to log 1,000,000 lines and send 1,000,000 metrics via udp:
```bash
cd ~
bundle exec samples/latency/latency.rb 8125 1_000_000
```

At the end, you will see a report like this:
```bash
Logging 1000000 lines ...
Sending 1000000 messages via UDP to localhost on port 8125 ...

-------------------------------------------------------------------------
|     task     |     total time (sec)     | Throughput (operations/sec) |
-------------------------------------------------------------------------
     log               14.162302              70609.989817            
     udp               8.078506              123785.264256   
```

>**Note:** You can check the logged lines at ``~/aws-apm/logs/lattency_test.log``. The udp packages will not be sent to CloudWatch because they are not whitelisted.


## 5.References
1. CloudWatch custom metrics
    1. [Collectd](https://collectd.org/)
    2. Statsd - [hisory](https://codeascraft.com/2011/02/15/measure-anything-measure-everything/) and [source code](https://github.com/etsy/statsd)
    3. Collectd [statsd plugin](https://collectd.org/wiki/index.php/Plugin:StatsD)
    4. Collectd cloudwatch plugin - [blog post](https://aws.amazon.com/blogs/aws/new-cloudwatch-plugin-for-collectd/) and [source code](https://github.com/awslabs/collectd-cloudwatch)
2. CloudWatch Logs
    1. CloudWatch Logs Agent [reference docs](http://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/AgentReference.html) and [quick start guide](http://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/EC2NewInstanceCWL.html)
    2. [CloudWatch Logs Subscriptions](http://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/Subscriptions.html)
    3. [Centralized Logging Solution on AWS](https://aws.amazon.com/answers/logging/centralized-logging/)
3. AWS X-Ray
    1. [segment documents](http://docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html)
    2. [Getting Started](http://docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html)
    3. [SDKs](https://aws.amazon.com/documentation/xray/)