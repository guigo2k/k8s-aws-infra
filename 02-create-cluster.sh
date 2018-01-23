#!/usr/bin/env bash

TERRAFORM="$(command -v terraform)"
SHORTNAME="$1"

echo

if [[ -z ${TERRAFORM} ]]; then
  echo -e "\x1B[1;31m\nERROR: Terraform is not installed.\x1B[0m\n"
  exit 1
fi

if [[ -z ${SHORTNAME} ]]; then
  echo -en "\x1B[1;1mCLUSTER SHORTNAME: \x1B[0m"
  read SHORTNAME
fi

if [[ -z ${AWS_ACCESS_KEY_ID} ]]; then
  echo -en "\x1B[1;1mAWS_ACCESS_KEY_ID: \x1B[0m"
  read AWS_ACCESS_KEY_ID && export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}"
fi

if [[ -z ${AWS_SECRET_ACCESS_KEY} ]]; then
  echo -en "\x1B[1;1mAWS_SECRET_ACCESS_KEY: \x1B[0m"
  read AWS_SECRET_ACCESS_KEY && export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}"
fi

echo -e "\n\x1B[1;1mReading infra state... \x1B[0m(can take few minutes)"
export SSH_KEY="~/.ssh/symphony_devops.pub"
export VPC_ID="$(terraform output vpc_id)"
export HOSTED_ZONE="$(terraform output vpc_name)"
export CLUSTER_NAME="${SHORTNAME}.$(terraform output vpc_name)"
export ZONES=$(terraform output -json availability_zones | jq -r '.value|join(",")')
export KOPS_STATE_STORE="$(terraform output state_store)"

echo -e "\x1B[1;1mCreating Kops cluster...\x1B[0m"
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

# dump cluster_spec to file
echo -e "\x1B[1;1mUpdating cluster spec...\x1B[0m"
CLUSTER_SPEC="${CLUSTER_NAME}/cluster_spec.yaml"
kops get cluster ${CLUSTER_NAME} -o yaml \
| sed -ne '/subnets:/ {r subnets.yaml' -e ':a; n; /topology:/ {p; b}; ba}; p' \
> ${CLUSTER_SPEC} && echo -e '\n---\n' >> ${CLUSTER_SPEC}
kops get ig --name ${CLUSTER_NAME} -o yaml >> ${CLUSTER_SPEC}
kops replace -f ${CLUSTER_SPEC}
kops update cluster --target=terraform --out=${CLUSTER_NAME} ${CLUSTER_NAME}

# create 'backend.tf' file
echo -e "\x1B[1;1mCreating backend file...\x1B[0m"
cat backend.tf \
| sed "s|key.*|key    = \"${CLUSTER_NAME}.tfstate\"|g" \
> ${CLUSTER_NAME}/backend.tf

# create 'clusters.tf' file
echo -e "\x1B[1;1mUpdating infrastructure...\x1B[0m"
declare -a CLUSTERS=($(cat clusters.tf | grep "kubernetes.io" | awk '{print $1}'))
CLUSTERS[$((${#CLUSTERS[@]} + 1))]="\"kubernetes.io/cluster/${CLUSTER_NAME}\""
cat <<EOF > clusters.tf
variable "clusters" {
  type    = "map"
  default = {
$(for C in ${CLUSTERS[@]}; do echo "    ${C} = \"shared\""; done)
  }
}
EOF

# update infra
${TERRAFORM} apply --auto-approve

# deploy cluster
cd ${CLUSTER_NAME}
${TERRAFORM} init --force-copy && echo
${TERRAFORM} apply --auto-approve
cd ..
