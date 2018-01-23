#!/usr/bin/env bash

TERRAFORM="$(command -v terraform)"
CLUSTER_SHORTNAME="$1"

echo

if [[ -z ${TERRAFORM} ]]; then
  echo -e "\x1B[1;31m\nERROR: Terraform is not installed.\x1B[0m\n"
  exit 1
fi

if [[ -z ${CLUSTER_SHORTNAME} ]]; then
  echo -en "\x1B[1;1mCLUSTER_SHORTNAME: \x1B[0m"
  read CLUSTER_SHORTNAME
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
export CLUSTER_NAME="${CLUSTER_SHORTNAME}.$(terraform output vpc_name)"
export ZONES=$(terraform output -json availability_zones | jq -r '.value|join(",")')
export KOPS_STATE_STORE="$(terraform output state_store)"

# destroy cluster
cd ${CLUSTER_NAME}
${TERRAFORM} destroy
cd .. && echo

# delete kops cluster
kops delete cluster ${CLUSTER_NAME} --yes
[[ -d ${CLUSTER_NAME} ]] && rm -rf ${CLUSTER_NAME}

# update 'clusters.tf' file
echo -e "\n\x1B[1;1mUpdating infrastructure...\x1B[0m"
declare -a CLUSTERS=($(cat clusters.tf | grep "kubernetes.io" | grep -v "${CLUSTER_NAME}" | awk '{print $1}'))
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
