svn-scripts
===========

Various utility scripts for use with Subversion

authz-ldap-sync
---------------

A very simple but incredibly useful little script that does one thing only --
reads in every AuthZ-style ini file in a given directory, iterates through the
list of groups defined in the [groups] section of the file, and, if the group
name matches a group name in LDAP, updates the group membership list from LDAP.

This is a very cheap, simple way to keep SVN access in sync with LDAP groups.
Management of the rest of the ini file is up to the user. Run this script every 15 minutes or half hour and you'll never need to manually modify SVN groups again!

sync-kicker
-----------

This process is inspired by [Subversion replication at Atlassian](http://blogs.atlassian.com/2008/11/subversion_replication_at_atla/). It is a method of keeping a master Subversion instance in sync with one or more read-only mirrors. It differ's from Atlassian's approach in that this method assumes use of `mod_dav_svn` to support multiple repositories at one or more different parent paths -- a useful pattern for a larger organization where repos (and access) can be separated by group or department.

Each repository is setup on the mirror(s) with svnsync as described in the post. Some SVN hooks are placed into each repository on both the master and mirrors.  An EventMachine server runs on each mirror listening on a specified UDP port. Whenever a new check-in is recived on a repository on the primary, a post-commit hook sends a UDP "ping" to the mirrors with the name of the space and repository. The servers then kick off a sync job using a saved Kerberos credential. Rudimentary locking ensures that multiple syncs of the same repository do not take place in parallel.
