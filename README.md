# create-ec2-snap.sh
create and manage AWS EC2 snapshots for backups

This script assumes that you have the Amazon AWS CLI installed and a sane IAM policy.  I will document this in more detail soon as well as providing usage examples.  There are several tools that solve this problem but I wanted to produce a stripped down minimal version for my own use case.

e.g:

{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": [
    	"ec2:DescribeVolumes",
    	"ec2:CreateSnapshot",
    	"ec2:DescribeSnapshots",
    	"ec2:DeleteSnapshot",
    	"ec2:CreateTags",
    	"ec2:DescribeTags"
    ]
    "Resource": "*"
  }
}
