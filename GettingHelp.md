# Documentation #
## Usage ##
Vuser has a built in help system that can be viewed with the _help_ keyword.
```
vuser help
vuser help extension_name
```

## Manuals ##
Vuser, vsoapd and most of the extensions include documentation in the perldoc for the extension. On some systems, you can use `man` instead of `perldoc`.

**Examples:**
```
perldoc vuser
perldoc vsoapd
perldoc VUser::Google::Apps
```

**Note:** On debian-based systems, you may have to install the `perl-doc` package.
```
apt-get install perl-doc
```

The _man_ keyword will return the manual for the extension.

**Examples:**
```
vuser man Email
vuser man Google::Apps
```

## Wiki ##
The [wiki](http://code.google.com/p/vuser/w/list) has additional documentation and tips for using and extending vuser.

## Issue Tracker ##
Check the [issue tracker](http://code.google.com/p/vuser/issues/list) and see if your problem is a known issue.

# Further Help #
There are a couple of places you can go to get help with vuser or vuser modules.

  * [vuser-users Google group](http://groups.google.com/group/vuser-users)
  * #vuser IRC channel on Freenode