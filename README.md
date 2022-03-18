# kubernetes-awx
Repository to deploy Ansible AWX to kubernetes cluster

## Installation
### 1. Create AWX volume
`kubectl apply -f awx-volume.yml`

Since I'm using a 3-node k8s cluster, I need to use an HA storage class. In this case, I've created a directory on my NFS server and assigned 1001:1001 as user owner and group.

### 2. Create the AWX namespace
In order to isolate AWX resources from other projects, I create a dedicated namespace with the following command:
```
kubectl apply -f awx-namespace.yaml
```

### 3. Create the AWX Operator
Since version 18, AWX's preferred installation method is to use a Kubernetes Operator. 
Download the last version of the operator at (https://github.com/ansible/awx-operator/releases) with the following command:

```
wget https://github.com/ansible/awx-operator/archive/refs/tags/0.18.0.tar.gz
tar -xzvf 0.18.0.tar.gz
cd awx-operator-0.18.0
export NAMESPACE=awx
make deploy
```

Wait a couple of minutes and verify the operator has been successfully deployed with:
```
kubectl get all -n awx
```

Finally, set the current namespace to the AWX namespace:
```
kubectl config set-context --current --namespace=$NAMESPACE
```

### 4. Create the AWX Instance
Once the operator is up & running, deploy an AWX instance with the following command:

```
kubectl apply -f awx-instance.yaml
```

The instance deployment will take some minutes and you can check the progress by reading the operator's log with `kubectl logs -f deployment.apps/awx-operator-controller-manager -c awx-manager`.
Along with the AWX instance, the operator will also deploy a postgresql container.

Again, verify the instance has been deployed correctly with:
```
kubectl get all -n awx
```

### 5. Obtain the admin password
When AWX pod is fully deployed, you can get the admin password with the following command:
```
kubectl get secrets -n awx
kubectl get secret <resourcename>-admin-password -o jsonpath="{.data.password}" -n awx | base64 --decode
```

Access the UI using your network configuration and test it.

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
