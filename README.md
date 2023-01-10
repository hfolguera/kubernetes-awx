# kubernetes-awx
Repository to deploy Ansible AWX to kubernetes cluster

## Installation
### 1. Create AWX volume
```
kubectl apply -f awx-volume.yml
```

Since I'm using a 3-node k8s cluster, I need to use an HA storage class. In this case, I've created a directory on my NFS server and assigned 1001:1001 as user owner and group.

### 2. Create the AWX namespace
In order to isolate AWX resources from other projects, I create a dedicated namespace with the following command:
```
kubectl apply -f awx-namespace.yaml
```

### 3. Install the AWX Operator and deploy the AWX instance
Since version 18, AWX's preferred installation method is to use a Kubernetes Operator. 

Make sure you are deploying the last AWX Operator version. Update the `kustomization.yaml` file with the last tag.

Install the AWX operator and deploy an AWX instance with the following command:
```
kustomize build . | kubectl apply -f -
```

Check the awx-manager logs to verify the deployment has finished:
```
kubectl logs -f deployment.apps/awx-operator-controller-manager -n awx -c awx-manager
```

### 4. Obtain the admin password
When AWX pod is fully deployed, you can get the admin password with the following command:
```
kubectl get secrets -n awx
kubectl get secret awx-admin-password -o jsonpath="{.data.password}" -n awx | base64 --decode
kubectl get secret awx-admin-password -o jsonpath="{.data.password}" -n awx | base64 --decode > password
```

> **Note:** Make sure the password is stored in a file called `password` (which is excluded to git uploads through .gitignore) and it is used by the backup script

Access the UI using your network configuration and test it.


## Install AWX CLI
### 1. Install python3
```
yum install -y python3
```

### 2. Install AWX CLI
```
pip3 install awxkit
```

## Backup & Restore
The `backup.sh` script exports the AWX configuration for backup purposes. Sometimes is easier to destroy all the AWX deployment and recreate it instead of upgrading; but configuration must be kept if we don't want to lose all the hosts, groups and jobs already created.

To schedule a daily backup add the following line to your crontab:
```
0 0 * * * cd /root/kubernetes-awx; ./backup.sh
```


## Notes
1. CPU and Memory resources has been scaled down since its a testing installation. To reduce resources use `kubectl edit deployment.apps/awx -n awx` and search for cpu and memory properties.
2. Metallb annotation has been configured in order to use a LoadBalancer service.

## References
This repository is based on Ansible's official deployment guide (https://github.com/ansible/awx) and (https://github.com/ansible/awx-operator)

## Known Issues
1. If postgres pod stays in CrashLoop state, verify its pv configuration. Currently using synology NFS with properties (no-mapping), using filesystem storage class (instead of NFS) with 1024:1001 owner and 777 permissions.
2. If AWX pod stays in pending state, verify its project folder. Currently using synology NFS mounted on all k8s nodes. The folder must be owned by 1000:1001 with 755 permissions.
3. If the message "Failed to access license information" appears when trying to login, the permissions on projects folder is wrong. Fix it and redeploy the pods using the ansible installation.
4. If the message "Redis is configured to save RDB snapshots, but is currently not able to persist on disk" appears on postgres pod, apply the workaround:
  1. Connect to the awx-redis docker with the redis user: `docker exec -it --user redis <dockerid> /bin/bash`
  2. Change the permissions to /data: `chmod 777 /data`
  3. *This is not a definitive solution, since in the next restart the same issue will appear.* 
5. If the message "Failed to retrieve configuration" appears when trying to login, the permissions on projects folder is wrong. Connect to awx-web container and fix it manually with `chmod 755 /var/lib/awx/projects` and verify directory owner and group.
6. "Fatal glibc error: CPU does not support x86-64-v2"
  1. If you are running your host machine in a virtual environment (VMWare, proxmox, ...) you have to change Processor type to support x86-64-v2. Proxmox: Type=Host
  2. If you are running on bare metal, your CPU does not suport x86-64-v2 instructions
