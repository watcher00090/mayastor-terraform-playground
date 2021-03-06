# kubeadm cluster in AWS with Mayastor

This repository creates the necessary infrastructure including VMs and then uses kubeadm to initialize and configure the cluster. Then it proceeds to deploy Mayastor.

## Prerequisities

* aws account
* installed and configured `aws` CLI tool (`aws configure`)
* installed `terraform` at least 0.13 version
* working ssh client and ssh agent

We recommend to set a `cluster_name` variable in `terraform.tfvars`. Otherwise you'll get a randomly generated string like `relaxed-ocelot`. You can also want to add some tags to created resources. (Most except implicitly generated resources will have the additional tags and `cluster_name` in `Name` tag. Also resources will get `terraform-kubeadm:cluster = <cluster_name>` and `terraform-kubeadm:node = (master|worker-X)` tags by default.) You might also want to change `aws_region` variable. See `variables.tf` for other tunables.
```
cluster_name = "mayastor-test"
tags = {"jenkins-job":"123"}
```

Check the `ssh_public_keys` variable to set up access to EC2 instances. You **must** configure at least one key named `key1` which is of RSA type (this is AWS limitation). (Default uses public key from `~/.ssh/id_rsa.pub` which suits most users).

## Steps

1. `terraform init`
2. `terraform apply`
3. Terraform will create a kubeconfig file for you in the working directory with the same name as your cluster name. In order to use it with kubectl type `export KUBECONFIG=$(terraform output kubeconfig)`.
4. Check that the cluster exists: `kubectl cluster-info`
5. Play with Mayastor :-)

```
kubectl apply -f test-pod-fio-mayastor.yaml
# wait a bit for pod to be ready
kubectl get pods
NAME           READY   STATUS    RESTARTS   AGE
fio-mayastor   1/1     Running   0          67s
# run fio benchmark
kubectl exec -it fio-mayastor -- fio --name=benchtest --size=800m --filename=/volume/test --direct=1 --rw=randrw --ioengine=libaio --bs=4k --iodepth=16 --numjobs=1 --time_based --runtime=60
```

To destroy the whole cluster run: `terraform destroy`. (Make sure you've deleted fio pod, otherwise destroy will hang/fail: `kubectl delete -f test-pod-fio-mayastor.yaml`.)

You can also run `./bin/destroy-quick` which is faster due to skipping destroying resources that will be destroyed implicitly with tear down of the VMs.

## TODO

* Check that cluster can be grown by adding nodes / changing `num_workers`
* Use [aws-vpc](https://github.com/coreos/flannel/blob/v0.13.0/Documentation/aws-vpc-backend.md) flannel backend instead of overlay network.
* Upload and run scripts instead of passing script in user data - this greatly enhances debugability and allows operator to re-run and check what failed. (Like `../hcloud-kubeadm` does)
* Validate how problematic is --discovery-token-unsafe-skip-ca-verification in kubeadm join
* Figure out how to allocate hugepages using kernel commandline in AWS - setting it up with sysctl might fail due to memory fragmentation etc...
    - currently sysctl + reboot seem to work
* Consider using original aws-kubeadm (after some PRs)
* Name EC2 instances nicely (containing master,worker,...)
* Include cluster name in EC2 instances hostname.
* Get/emit ssh host keys for installed machines.
* Create destroy-quick script that will remove terraform state for all resources except k8s module as they will obviously get destroyed with infra.
* Deploy test fio pod by default (set by variable similar to `deploy_mayastor`)
* Move additional EBS allocation from `k8s` to `mayastor-dependencies` module
* Rename worker to node (for EC2 instances) to keep k8s terminology.
* Install metrics server (see `hcloud-kubeadm/modules/k8s/install-metrics-server.tf`)
* When developing terraform and master/node creation fails due to `user_data` script failure subsequent `terraform apply` runs will not fix it as instances are "done" and only `wait_for_bootstrap_to_finish` resource is recreated. One has to manually destroy `aws_instance` resources to fix.
* Remove sleep 10 in mayastor deployment and instead wait for readiness of `msn` and `msp` resources.
* Do not allocate secondary EBS device for instances that have another storage (e.g. i3.xlarge).

# Acknowledgements

`./modules/k8s` is inspired by [terraform kubeadm module](https://github.com/weibeld/terraform-aws-kubeadm)
