# F5 Distributed Cloud Site Mesh Group (AWS/GCP)

Login
```
aws sso login
gcloud auth application-default login
```

## Capabilities demonstrated

**Site Mesh Group**

Data plane path is formed between AWS CE and GCP CE directly

![Site Mesh Group](assets/site-mesh-group.png)


**L3 network stitching (Global Network)**

Disparate network segments (with non-overlapping IP ranges) can be connected via Global Network. Subnets which are the CEs are not directly connected to can be discovered manually by specifying static routes on each CE site.

SSH to AWS VM and perform a curl test from AWS VM towards httpbin container running on GCP VM
```
$(terraform output -json aws_vms| jq -r .[0].ssh_cmd)
```

Perform a curl test from AWS VM towards httpbin container running on GCP VM by hitting the GCP VM IP address directly.
```
$ while true; do date; curl --max-time 2 10.0.2.2/ip; sleep 1; done
Wed Sep 27 05:05:44 UTC 2023
{
  "origin": "192.168.64.70"
}
Wed Sep 27 05:05:45 UTC 2023
{
  "origin": "192.168.64.70"
}
```

**Enhanced Firewall Policies**

Perform a ping test from AWS VM towards GCP VM. This will fail as the firewall policies only allows HTTP traffic
```
$ ping -w 5 -v 10.0.2.2
PING 10.0.2.2 (10.0.2.2) 56(84) bytes of data.

--- 10.0.2.2 ping statistics ---
5 packets transmitted, 0 received, 100% packet loss, time 4078ms
```

![Firewall Logs](assets/firewall-logs.png)

**TCP Load Balancing**

Perform iperf test, with GCP VM as the server, and AWS VM as the client. See [Performance Tests](#performance-tests) for examples.

**HTTP Load Balancing**

Get the IP address of the AWS CE inside ENI
```
$ terraform output xc_aws_ce_inside_ips
```

Perform a curl test from AWS VM towards an XC HTTP LB on the AWS CE, which proxies the traffic to the GCP VM
```
$ curl --resolve nginx.example.com:80:<AWS_CE_INSIDE_IP> nginx.example.com/ip
{
  "origin": "192.168.64.164"
}
```

## Performance Tests

Tests below were performed with the following machine/instance types:
```
xc_aws_ce_instance_type = "m5.4xlarge"
xc_gcp_ce_machine_type  = "n1-standard-16"
aws_vm_instance_type = "t3.xlarge"
gcp_vm_machine_type  = "n1-standard-4"
```

**Over L3 VPN**

Server (GCP VM)
```
$ iperf3 -s
-----------------------------------------------------------
Server listening on 5201
-----------------------------------------------------------
Accepted connection from 192.168.64.164, port 35676
[  5] local 10.0.2.2 port 5201 connected to 192.168.64.164 port 35680
[ ID] Interval           Transfer     Bitrate
[  5]   0.00-1.00   sec   256 MBytes  2.15 Gbits/sec
[  5]   1.00-2.00   sec   282 MBytes  2.36 Gbits/sec
[  5]   2.00-3.00   sec   252 MBytes  2.11 Gbits/sec
[  5]   3.00-4.00   sec   254 MBytes  2.13 Gbits/sec
[  5]   4.00-5.00   sec   268 MBytes  2.25 Gbits/sec
[  5]   5.00-6.00   sec   275 MBytes  2.30 Gbits/sec
[  5]   6.00-7.00   sec   302 MBytes  2.53 Gbits/sec
[  5]   7.00-8.00   sec   288 MBytes  2.41 Gbits/sec
[  5]   8.00-9.00   sec   277 MBytes  2.32 Gbits/sec
[  5]   9.00-10.00  sec   273 MBytes  2.29 Gbits/sec
[  5]  10.00-10.04  sec  8.55 MBytes  1.64 Gbits/sec
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate
[  5]   0.00-10.04  sec  2.67 GBytes  2.28 Gbits/sec                  receiver
-----------------------------------------------------------
Server listening on 5201
-----------------------------------------------------------
```

Client (AWS VM)
```
$ iperf3 -c 10.0.2.2
Connecting to host 10.0.2.2, port 5201
[  5] local 192.168.64.164 port 35680 connected to 10.0.2.2 port 5201
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-1.00   sec   271 MBytes  2.27 Gbits/sec  681   1.61 MBytes
[  5]   1.00-2.00   sec   282 MBytes  2.37 Gbits/sec    3   1.26 MBytes
[  5]   2.00-3.00   sec   249 MBytes  2.09 Gbits/sec   44    798 KBytes
[  5]   3.00-4.00   sec   255 MBytes  2.14 Gbits/sec    0    970 KBytes
[  5]   4.00-5.00   sec   269 MBytes  2.25 Gbits/sec   74   1.09 MBytes
[  5]   5.00-6.00   sec   276 MBytes  2.32 Gbits/sec    0   1.23 MBytes
[  5]   6.00-7.00   sec   304 MBytes  2.55 Gbits/sec    0   1.36 MBytes
[  5]   7.00-8.00   sec   286 MBytes  2.40 Gbits/sec  286   1.09 MBytes
[  5]   8.00-9.00   sec   276 MBytes  2.32 Gbits/sec    0   1.22 MBytes
[  5]   9.00-10.00  sec   269 MBytes  2.25 Gbits/sec    0   1.34 MBytes
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-10.00  sec  2.67 GBytes  2.30 Gbits/sec  1088             sender
[  5]   0.00-10.04  sec  2.67 GBytes  2.28 Gbits/sec                  receiver

iperf Done.
```

**Over XC TCP LB**

Server (GCP VM) behind an XC TCP load balancer on the CE (AWS)
```
$ iperf3 -s
-----------------------------------------------------------
Server listening on 5201
-----------------------------------------------------------
Accepted connection from 10.0.1.2, port 49153
[  5] local 10.0.2.2 port 5201 connected to 10.0.1.2 port 32770
[ ID] Interval           Transfer     Bitrate
[  5]   0.00-1.00   sec   177 MBytes  1.48 Gbits/sec
[  5]   1.00-2.00   sec   256 MBytes  2.15 Gbits/sec
[  5]   2.00-3.00   sec   216 MBytes  1.81 Gbits/sec
[  5]   3.00-4.00   sec   240 MBytes  2.01 Gbits/sec
[  5]   4.00-5.00   sec   188 MBytes  1.58 Gbits/sec
[  5]   5.00-6.00   sec   163 MBytes  1.36 Gbits/sec
[  5]   6.00-7.00   sec   169 MBytes  1.42 Gbits/sec
[  5]   7.00-8.00   sec   170 MBytes  1.43 Gbits/sec
[  5]   8.00-9.00   sec   174 MBytes  1.46 Gbits/sec
[  5]   9.00-10.00  sec   171 MBytes  1.43 Gbits/sec
[  5]  10.00-10.04  sec  6.27 MBytes  1.31 Gbits/sec
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate
[  5]   0.00-10.04  sec  1.88 GBytes  1.61 Gbits/sec                  receiver
```

Client (AWS VM)
```
# Add an entry in /etc/hosts to resolve iperf.example.com to the AWS CE inside ENI IP (192.168.0.166 in this example)
$ grep iperf.example.com /etc/hosts
192.168.0.166 iperf.example.com

$ iperf3 -c iperf.example.com
Connecting to host iperf.example.com, port 5201
[  5] local 192.168.64.164 port 33094 connected to 192.168.0.166 port 5201
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-1.00   sec   195 MBytes  1.63 Gbits/sec    0   2.37 MBytes
[  5]   1.00-2.00   sec   254 MBytes  2.13 Gbits/sec   14   1.87 MBytes
[  5]   2.00-3.00   sec   211 MBytes  1.77 Gbits/sec   11   1.38 MBytes
[  5]   3.00-4.00   sec   239 MBytes  2.00 Gbits/sec   52   1.04 MBytes
[  5]   4.00-5.00   sec   188 MBytes  1.57 Gbits/sec    0   1.13 MBytes
[  5]   5.00-6.00   sec   164 MBytes  1.37 Gbits/sec    0   1.20 MBytes
[  5]   6.00-7.00   sec   169 MBytes  1.41 Gbits/sec    0   1.28 MBytes
[  5]   7.00-8.00   sec   170 MBytes  1.43 Gbits/sec    0   1.35 MBytes
[  5]   8.00-9.00   sec   174 MBytes  1.46 Gbits/sec   54   1.02 MBytes
[  5]   9.00-10.00  sec   171 MBytes  1.44 Gbits/sec    0   1.11 MBytes
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-10.00  sec  1.89 GBytes  1.62 Gbits/sec  131             sender
[  5]   0.00-10.04  sec  1.88 GBytes  1.61 Gbits/sec                  receiver

iperf Done.
```