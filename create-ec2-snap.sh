#!/bin/bash
#
# create-ec2-snap.sh - create and manage AWS EC2 snapshots for backups
#
# Copyright (c) 2015 Gabriel M. O'Brien
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

## set default variables
v=true		# verbose output
keep=7		# number of old backups to keep
volumeid=NULL	# default volume-id (this ensures an error if not set)
ownerid=NULL	# default owner-id (this ensure and error if not set)

## don't edit below this line

# get our options
while getopts qk:v:o: opt; do
  case $opt in
  q)
      v=false
      ;;
  k)
      keep=$OPTARG 
      ;;
  v)
      volumeid=$OPTARG 
      ;;
  o)
      ownerid=$OPTARG 
      ;;
  esac
done
shift $((OPTIND - 1))

if [ "$volumeid" == "NULL" ] || [ "$ownerid" == "NULL" ]; then
  printf "ERROR: -o <owner-id> and/or -v <volume-id> not set\n"
  exit 65
fi

# set timestamp
stamp=`date +%FT%T%z`

## set some functions

# get a list of current snapshot ids and sort oldest -> newest
# - sort by timestamp column
# - only return the snapshot-id column
_get_snapids () {
  aws ec2 describe-snapshots --owner-id $ownerid \
    --filters Name=volume-id,Values=$volumeid \
    | sort -t$'\t' -k7 \
    | cut -f6
}

# create new snapshot
_create_snap () {
  sync	# flush buffers to disk (probably not necessary)
  aws ec2 create-snapshot --volume-id $volumeid \
    --description "created by `basename $0` @ $stamp" > /dev/null
}

# delete snapshot
_delete_snap () {
  aws ec2 delete-snapshot --snapshot-id $1
}

# create new snapshot
_create_snap && $v && printf "New snapshot created for volume $volumeid\n"

# find out how many backup directories are in the root
snapcount=`_get_snapids | wc -l`
diff=$(expr $snapcount - $keep)

# figure out if we need to delete any old snapshots and then do it
if [ "$diff" -gt "0" ]; then
  $v && printf 'Removing %s old snapshot(s):\n' $diff
  for snap in `_get_snapids | head -n $diff`; do
    _delete_snap $snap
    $v && printf '  %s\n' $snap
  done
else
  $v && printf 'No old snapshots to remove (found %s).\n' $snapcount
fi

