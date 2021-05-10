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
2. CPU and Memory resources has been scaled down since its a testing installation.
3. Metallb annotation has been configured in order to use a LoadBalancer service.

## References
This repository is based on Ansible's official deployment guide (https://github.com/ansible/awx)
