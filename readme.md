
General prep:

 * Adjust the Git repo url in `kubernetes/settings/configMap.yaml`
 * Adjust the domain name in `kubernetes/settings/configMap.yaml`
 * Adjust the base folder of backups in `kubernetes/components/volsync-nfs-backup/secret.yaml`
 * Adjust IP Pool in `kubernetes/apps/metallb-system/metallb-system-config/app/IPAddressPool.yaml`

# Creating the cluster itself

This all needs to be redone

## Bootstrapping

```sh
just go
```
