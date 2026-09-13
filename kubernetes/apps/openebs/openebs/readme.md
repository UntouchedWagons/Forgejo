
# OpenEBS

Most of the technical stuff was lifted from https://www.roosmaa.net/blog/2024/setting-up-zfs-on-talos/

A big thing to note is when creating the ZFS pool is to set legacy mounting:

```
zpool create -m legacy -f zfspv-pool /dev/sdb
```
