# kubernetes-awx
Repository to deploy Ansible AWX to kubernetes cluster

## Installation
### 1. Create AWX volume
`kubectl apply -f awx-volume.yml`

### 2. Execute ansible installation playbook
```
cd installer
ansible-playbook -i inventory install.yml
```

## Notes
1. By default, playbook tries to deploy the `stable/postgresql` image and it is deprecated. Code has been modified to deploy `bitnami/postgresql`image.
2. CPU and Memory resources has been scaled down since its a testing installation. To reduce resources use `kubectl edit deployment.apps/awx -n awx` and search for cpu and memory properties.
3. Metallb annotation has been configured in order to use a LoadBalancer service.

## References
This repository is based on Ansible's official deployment guide (https://github.com/ansible/awx)

## Known Issues
1. If postgres pod stays in CrashLoop state, verify its pv configuration. Currently using synology NFS with properties (no-mapping), using filesystem storage class (instead of NFS) with 1024:1001 owner and 777 permissions.
2. If AWX pod stays in pending state, verify its project folder. Currently using synology NFS mounted on all k8s nodes. The folder must be owned by 1000:1001 with 755 permissions.
3. If the message "Failed to access license information" appears when trying to login, the permissions on projects folder is wrong. Fix it and redeploy the pods using the ansible installation.
4. If the message "Redis is configured to save RDB snapshots, but is currently not able to persist on disk" appears on postgres pod, apply the workaround:
  1. Connect to the awx-redis docker with the redis user: `docker exec -it --user redis <dockerid> /bin/bash`
  2. Change the permissions to /data: `chmod 777 /data`
  3. *This is not a definitive solution, since in the next restart the same issue will appear.* 
