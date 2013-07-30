svn-scripts
==============

Various utility scripts for use with Subversion

authz-ldap-sync
-----------------------

A very simple but incredibly useful little script that does one thing only --
reads in every AuthZ-style ini file in a given directory, iterates through the
list of groups defined in the [groups] section of the file, and, if the group
name matches a group name in LDAP, updates the group membership list from LDAP.

This is a very cheap, simple way to keep SVN access in sync with LDAP groups.
Management of the rest of the ini file is up to the user.
