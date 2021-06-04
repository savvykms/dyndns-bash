# dyndns-bash

This codebase consists of a Bash shell script with which to update a specified DNS A (alias) record contained within a specified AWS Route53 DNS zone with an optionally specified TTL (time-to-live) value (in seconds).

# Requirements

## Network requirements:

DNS resolution and reachability of one or more of the following domains is required (or alteration of this script to provide alternative method):
 - https://checkip.amazonaws.com/
 - https://api.ipify.org?format=text
 - https://api.my-ip.io/ip.txt

Keep in mind these services have their own terms of service; modify the `IP_FUNCS` array to select which ones you want.

## Software dependencies

Rough list of software required:
 - Bash
 - curl
 - AWS CLI

This was developed with the following versions initially:
 - GNU bash, version 4.4.20(1)-release (x86_64-pc-linux-gnu)
 - curl 7.58.0 (x86_64-pc-linux-gnu) libcurl/7.58.0 OpenSSL/1.1.1i zlib/1.2.11 libidn2/2.3.0 libpsl/0.19.1 (+libidn2/2.0.4) nghttp2/1.30.0 librtmp/2.3
 - OpenSSL 1.1.1i  8 Dec 2020
 - aws-cli/1.14.44 Python/3.6.9 Linux/4.4.0-19041-Microsoft botocore/1.16.19

## AWS permissions

The AWS principal(s) being used must have the `route53:ChangeResourceRecordSets` permissions for any DNS zones you wish to modify.

Example IAM Policy:
```
{
   "Version": "2012-10-17",
   "Statement": [
       {
           "Sid": "allow-dyndns-bash",
           "Effect": "Allow",
           "Action": "route53:ChangeResourceRecordSets",
           "Resource": "arn:aws:route53:::hostedzone/<YOUR_ZONE_ID_HERE>"
       }
   ]
}
```

# Invocation

Syntax:
```
bash dyndns.bash "<zone_id>" "<record_name> [ttl]"
```

For example:
```
bash dyndns.bash "XYZROUTE53ZONEID" "test.example.com"
```

# Configuration

To provide AWS credentials, use environment or file-driven AWS CLI configuration as documented by Amazon.
