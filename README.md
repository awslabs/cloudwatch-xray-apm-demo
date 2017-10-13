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
                "cloudwatch:PutMetricData"
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
To install this demo, SSH to your EC2 instance and follow the steps bellow.

### 2.1 Install the App From This Repo
Run the following commands:
```bash
sudo yum update -y
sudo yum install -y git
sudo yum install -y gcc
sudo yum install -y ruby-devel
gem install bundler
cd ~ && git clone https://github.com/marcosortiz/aws-apm.git && cd aws-apm && git checkout dev && mkdir logs && bundle install
```

### 2.2 Install the CloudWatch Logs Agent
Run the following commands:
```bash
cd ~/aws-apm
./bin/1_install_cw_logsd.sh
```

### 2.3 Install CollectD
Run the following commands:
```bash
cd ~/aws-apm
./bin/2_install_collectd.sh
```
>**Note:** At some point, you will be asked to give a few inputs for the cloudwatch plugin. Please presse ENTER, choosing all the defaults

### 2.4 Install the X-Ray Daemon
Run the following commands:
```bash
cd ~/aws-apm
./bin/3_install_xrayd.sh
```

### 2.5 Create the CloudWatch Dashboard
1. On the concole, go to ![CloudWatch Dashboards](https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:)
2. Click **Create dashboard**.
3. Give it a name and click **Create dashboard**.
4. On the **Add to this dashboard** screen, click **cancel**.
5. Click **Actions** and then select **View/edit source**.
6. Copy and paste the dashboard source bellow into the text area and click **Update**.

Dashboard source:
```json
{
    "widgets": [
        {
            "type": "metric",
            "x": 0,
            "y": 0,
            "width": 6,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": true,
                "metrics": [
                    [ "collectd", "statsd.latency.factorial-average", "PluginInstance", "NONE", "Host", "i-043117c6d04ba94c0", { "period": 1 } ]
                ],
                "region": "us-east-1",
                "title": "udp.factorial (s)",
                "period": 300
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 6,
            "width": 6,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": true,
                "metrics": [
                    [ "collectd", "statsd.latency.fibonacci-average", "PluginInstance", "NONE", "Host", "i-043117c6d04ba94c0", { "period": 1 } ]
                ],
                "region": "us-east-1",
                "title": "udp.fibonacci (s)",
                "period": 300
            }
        },
        {
            "type": "metric",
            "x": 6,
            "y": 0,
            "width": 6,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": true,
                "metrics": [
                    [ "collectd", "log.factorial_time", { "period": 1 } ]
                ],
                "region": "us-east-1",
                "period": 300,
                "title": "log.factorial(ms)"
            }
        },
        {
            "type": "metric",
            "x": 6,
            "y": 6,
            "width": 6,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": true,
                "metrics": [
                    [ "collectd", "log.fibonacci_time", { "period": 1 } ]
                ],
                "region": "us-east-1",
                "period": 300,
                "title": "log.fibonacci(ms)"
            }
        },
        {
            "type": "text",
            "x": 12,
            "y": 0,
            "width": 9,
            "height": 12,
            "properties": {
                "markdown": "\n# Heading\n## Sub-heading\nParagraphs are separated by a blank line. Text attributes *italic*, **bold**, ~~strikethrough~~ .\n\nA [link](http://amazon.com). A link to this dashboard: [MyApp](#dashboards:name=MyApp).\n\n[button:Button link](http://amazon.com) [button:primary:Primary button link](http://amazon.com)\n\nTable | Header\n----|-----\nCloudWatch | Dashboards\n\n```\nText block\nssh my-host\n```\nList syntax:\n\n* CloudWatch\n* Dashboards\n  1. Graphs\n  1. Text widget\n"
            }
        }
    ]
}
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

## 5. X-Ray Service Map Script
This script demonstrates how can you instrument your apps on X-Ray even if you are using a programming language that doesn't have a X-Ray SDK yet.

If you followed the installation instructions above, you can run it with the following commands:
```bash
cd ~/aws-apm
ruby samples/???
```

## 6.References
1. CloudWatch custom metrics
  1.1 Collectd
  1.2 Statsd
  1.3 Collectd statsd plugin
  1.4 Collectd cloudwatch plugin
2. CloudWatch Logs
  2.1 CloudWatch Logs Agent
  2.2 CloudWatch Logs Subscriptions
  2.3 Centralized Logging Solution
3. X-Rays
  3.1 X-Ray trace documents
  3.2 Service map demo using the X-Ray daemon
  3.3 Quick start guide.
  3.4 X-Ray SDKs