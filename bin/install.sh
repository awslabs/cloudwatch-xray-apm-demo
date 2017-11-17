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

# Create log group and metric filters
export AWS_DEFAULT_REGION=us-east-1
aws logs create-log-group --log-group-name aws-apm-demo/my_app
aws logs put-metric-filter \
  --log-group-name aws-apm-demo/my_app \
  --filter-name FactorialLatency \
  --filter-pattern '[recorded_at, severity, flag="my_app.metrics", k1, v1, k2, v2]' \
  --metric-transformations \
  'metricName=log.latency.factorial-average,metricNamespace=collectd,metricValue=$v1'

aws logs put-metric-filter \
  --log-group-name aws-apm-demo/my_app \
  --filter-name FibonacciLatency \
  --filter-pattern '[recorded_at, severity, flag="my_app.metrics", k1, v1, k2, v2]' \
  --metric-transformations \
  'metricName=log.latency.fibonacci-average,metricNamespace=collectd,metricValue=$v2'

# Create cloudwatch dashboard
EC2_INSTANCE_ID="`wget -qO- http://169.254.169.254/latest/meta-data/instance-id`"
DASHBOARD_BODY=$(cat <<EOF
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
                    [ "collectd", "statsd.latency.factorial-average", "PluginInstance", "NONE", "Host", "${EC2_INSTANCE_ID}", { "period": 1 } ]
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
                    [ "collectd", "statsd.latency.fibonacci-average", "PluginInstance", "NONE", "Host", "${EC2_INSTANCE_ID}", { "period": 1 } ]
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
                    [ "collectd", "log.latency.factorial-average", { "period": 1 } ]
                ],
                "region": "us-east-1",
                "period": 300,
                "title": "log.factorial (s)"
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
                    [ "collectd", "log.latency.fibonacci-average", { "period": 1 } ]
                ],
                "region": "us-east-1",
                "period": 300,
                "title": "log.fibonacci (s)"
            }
        }
    ]
}
EOF
)
aws cloudwatch put-dashboard \
    --dashboard-name MyApp \
    --dashboard-body "${DASHBOARD_BODY}"