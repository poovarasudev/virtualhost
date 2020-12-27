Virtualhost Manage Script for Ubuntu
===========

This Bash Script allows create or delete apache/nginx virtual hosts on Ubuntu on a quick way.

## Installation ##

1. Download the script
2. Apply permission to execute:

```
$ chmod +x /path_to/virtualhost-nginx.sh
```

## Usage ##

Command line syntax:

```bash
$ sudo sh /path_to/virtualhost-nginx.sh [create | delete] [domain] [optional host_directory]
```

### Examples ###

to create a new virtual host:

```bash
$ sudo sh /path_to/virtualhost-nginx.sh create test.dev
```
to create a new virtual host with custom directory name:

```bash
$ sudo sh /path_to/virtualhost-nginx.sh create test.dev test_dir
```
to delete a virtual host

```bash
$ sudo sh /path_to/virtualhost-nginx.sh delete test.dev
```

to delete a virtual host with custom directory name:

```
$ sudo sh /path_to/virtualhost-nginx.sh delete test.dev test_dir
```
