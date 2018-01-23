# AWS K8S Clusters

> To follow this tutorial, you must have completed the steps described in [README.md](./README.md).

Now that you have the infrastructure ready, let's deploy a Kubernetes cluster. We start by exporting our AWS credentials.

```bash
export AWS_ACCESS_KEY_ID="<aws_access_key_id>"
export AWS_SECRET_ACCESS_KEY="<aws_secret_access_key>"
```

With that in place, let's export the variables we are going to use with [Kops](https://github.com/kubernetes/kops).
```bash
export SSH_KEY="~/.ssh/symphony_devops.pub"
export VPC_ID="$(terraform output vpc_id)"
export HOSTED_ZONE="$(terraform output vpc_name)"
export CLUSTER_NAME="my-cluster.$(terraform output vpc_name)"
export ZONES=$(terraform output -json availability_zones | jq -r '.value|join(",")')
export KOPS_STATE_STORE="$(terraform output state_store )"
```

Now we can use [Kops](https://github.com/kubernetes/kops) to generate the Terraform templates for our cluster.

```
kops create cluster \
--vpc ${VPC_ID} \
--zones ${ZONES} \
--master-zones ${ZONES} \
--master-size m4.2xlarge \
--node-count 3 \
--node-size m4.4xlarge \
--networking calico \
--dns-zone ${HOSTED_ZONE} \
--ssh-public-key ${SSH_KEY} \
--topology private \
--target=terraform \
--out=${CLUSTER_NAME} \
--bastion \
${CLUSTER_NAME}
```

> For more information about Kops options, read the documentation on [https://github.com/kubernetes/kops/blob/master/docs/cli/kops_create_cluster.md](https://github.com/kubernetes/kops/blob/master/docs/cli/kops_create_cluster.md).


The command above creates a new directory `${CLUSTER_NAME}` with all the files needed to deploy your Kubernetes cluster via Terraform. However, we must instruct Kops to use our newly created subnets istead of trying to create new ones.

```
# dump cluster_spec to file
kops get cluster ${CLUSTER_NAME} -o yaml \
| sed -ne '/subnets:/ {r subnets.yaml' -e ':a; n; /topology:/ {p; b}; ba}; p' \
> ${CLUSTER_NAME}/cluster_spec.yaml <<(echo -e '\n---\n')
kops get ig --name ${CLUSTER_NAME} -o yaml >> ${CLUSTER_NAME}/cluster_spec.yaml

# update cluster_spec from file
kops replace -f ${CLUSTER_NAME}/cluster_spec.yaml
kops update cluster --target=terraform --out=${CLUSTER_NAME} ${CLUSTER_NAME}
```

There is one last step before we can deploy our cluster. Since we use a remote state store (S3), we must also create a `backend.tf` within the `${CLUSTER_NAME}` directory.
```
cat backend.tf \
| sed "s|key.*|key = ${CLUSTER_NAME}.tfstate|g" \
> ${CLUSTER_NAME}/backend.tf
```

That's it guys! Now we can change directory and deploy our Kubernets cluster via Terraform.

```
cd ${CLUSTER_NAME}
terraform init
terraform plan
terraform apply
```

It will take a few minutes, but eventually, your new cluster will be up and running. You can hit the api endpoint at `echo "https://api.${CLUSTER_NAME}"`, but first you will need to get the credentials by running:

```
kops get secrets kube --type secret -oplaintext
```


Now, let's install a few addons :)

```
# Install Kubernetes dashboard
kubectl create -f https://raw.githubusercontent.com/kubernetes/kops/master/addons/kubernetes-dashboard/v1.7.1.yaml
```

```
# Install Kubernetes monitoring (Heapster)
kubectl create -f https://raw.githubusercontent.com/kubernetes/kops/master/addons/monitoring-standalone/v1.7.0.yaml
```
