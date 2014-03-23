#!/bin/bash
# Called by post-commit hook on primary, sends kick message to mirror(s)
# specified. This script exists to make it easy to add or change mirrors.

action="$1"
space="$2"
repo="$3"
rev="$4"

echo "$action $space $repo $rev" | nc -w1 -u svnmirror.example.com 8042
exit 0
