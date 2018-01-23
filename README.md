# AWS K8S Infra

This is a set of Terraform modules for creating the underlying infrastructure for Kubernetes clusters on AWS. It creates the following resources:

* VPC
* Internet Gateway
* Subnet Pair (public/private)
* Route53 Hosted Zone (subdomain)
* S3 Bucket (state store)
* NAT Routes
* NAT Gateways
* NAT Elastic IPs
* Route Tables
* Security Groups

### Prerequisites

* Parent Route53 hosted zone
* Terraform 0.11.0+

For this example, we already have the `sym-k8s.ml` hosted zone configured in Route53. A new DNS zone `<env>.sym-k8s.ml` will be configured for this VPC.

### Deploying

> In this folder, you will find two scripts, [00-create.sh](./00-create.sh) and [99-destroy.sh](./99-destroy.sh), which can be used to easily deploy and destroy this infrastructure.

Let's start by creating a S3 bucket which will be used by Terraform as a remote state backend.

```bash
terraform init
terraform plan --target=module.remote_state
terraform apply --target=module.remote_state
```

The `apply` command creates a S3 bucket and generates a local `backend.tf` file which instructs Terraform to use this bucket as a remote state backend. However, before we can use this, we need to initialize the new backend and copy our local state file. We can do this with a single command.

```bash
terraform init --force-copy
```

With the remote state configured, we can deploy our infrastructure.

```bash
terraform plan
terraform apply
```

Alright! Now we should have a new VPC `dev.sym-k8s.ml` with 3 public and 3 private subnets, NAT gateways, route tables and security groups ready to go. Since we will be deploying Kubernetes clusters, there is one last step to make future deployments more easy.

Let's create a [subnets.yaml](./subnets.yaml) file which can be used by [Kops](https://github.com/kubernetes/kops), to generate Terraform templates of our Kubernetes clusters. Again, we can do this with a single command.

```bash
terraform output -json \
| docker run --rm -i ryane/gensubnets:0.1 \
| sed 's/^/  /' \
> subnets.yaml
```

That's it folks :)  
If you wish to move along and deploy a new Kubernetes cluster on this infrastructure, read the [README_KOPS.md](./README_KOPS.md) file.
