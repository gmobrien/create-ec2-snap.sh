# create-ec2-snap.sh
create and manage AWS EC2 snapshots for backups

This script can be used to automate routine backups of an Amazon Web Services EC2 instance using native [EC2 snapshots](http://docs.aws.amazon.com/cli/latest/reference/ec2/create-snapshot.html).  Its basic functionality provides the ability to create and maintain a rotation of snapshots, deleting snaps once more than a given number of older snapshots exist.

I am currently testing with Debian Wheezy backports, but the script is only dependent on BASH, the date command and the [AWS Command Line Interface](http://aws.amazon.com/cli/).  For Wheezy you will need to either install the AWC CLI from the tarball or use [pip](https://pip.pypa.io/en/latest/).  Both methods are documented on the Amazon site but the pip method is probably easiest:

```bash
apt-get install python-pip
pip install awscli
```

More detailed instructions can be found here: http://docs.aws.amazon.com/cli/latest/userguide/installing.html

In order for the script to work you need to know a few things about the account and volume you are going to use.

## Finding your volume-id and owner-id

In order to ensure that nothing too crazy happens this script requires that you specify the owner-id of the instance/volume in question and volume-id you are going to create and delete snapshots for.  The volume-id can be found by going to the [volumes page](https://console.aws.amazon.com/ec2/v2/home#Volumes) under "Elastic Block Store" in your EC2 admin console and finding the value for the volume you wish to create and manage snapshots for in the "Volume ID" column.

The owner-id is the same as your AWS Account ID.  If you do not know this information it can be found on the [AWS IAM Security Credentials page](https://console.aws.amazon.com/iam/home?#security_credential) under the "Account Identifiers" section.  It will be a 12 digit string separated by dashes.  Remove the dashes when specifying the -o option on the ```create-ec2-snap.sh``` command line.

## AWS IAM user and policy creation

In order to use this script you will require a properly configured identity and policy.

### Amazon documentation

Amazon provides a good guide on [getting started](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-set-up.html) with the AWS CLI, I recommend you take a look at it if you are unfamiliar.

### Detailed instructions

You will need to create an Identity and Access Management userid and policy which you will use to create your snapshots.  This can be done by following [this](https://console.aws.amazon.com/iam/) link.  Here you will first need to [create a user](https://console.aws.amazon.com/iam/home#users) via the dashboard, the name doesn't matter.

#### Don't forget your API key

This user is separate from your AWS login user account and is known by the API key information that will be shown to you upon creation.  You will want to record this info as it *can not* be modified or retrieved later on.  It will look something like this.

```
Access key ID example: AKIAIOSFODNN7EXAMPLE
Secret access key example: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

### Snapshot management policy creation

Secondly you will need to add a new policy which will allow you run the required AWS CLI commands to create and delete your snapshots.  This can be done by adding the following JSON to a [new policy](https://console.aws.amazon.com/iam/home#policies) which you will then associate with your account.

```json
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
```

#### Note

This is the minimal set of actions which will allow you to validly manage snapshots.  Unfortunately the snapshot actions do not currently allow you to limit them to a single resource (e.g.: your snapshot or EC2 instance), all snapshots your userid has access to can be managed.  On the flipside this means you can manage all your snapshots from a single host.

Finally you will need to associate this policy with the backup user you just crated.  You can choose to attach the policy directly to your user account or to a group that the user is a member of.

### AWS CLI configuration

I recommend setting up the AWS CLI for a non privileged account.  There is nothing in the script which requires any escalated operating system privileges.  In orer to do so you will should switch to the unix user and run ```aws configure```.  There are other ways of managing your AWS access keys and configuration, but I will leave that to the inquisitve reader.

Once you have the AWS CLI configured you can now run the ```create-ec2-snap.sh``` script.

