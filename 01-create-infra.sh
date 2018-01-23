#!/usr/bin/env bash

TERRAFORM="$(command -v terraform)"

echo

if [[ -z ${TERRAFORM} ]]; then
  echo -e "\x1B[1;31m\nERROR: Terraform is not installed.\x1B[0m\n"
  exit 1
fi

if [[ -z ${AWS_ACCESS_KEY_ID} ]]; then
  echo -en "\x1B[1;1mAWS_ACCESS_KEY_ID: \x1B[0m"
  read AWS_ACCESS_KEY_ID && export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}"
fi

if [[ -z ${AWS_SECRET_ACCESS_KEY} ]]; then
  echo -en "\x1B[1;1mAWS_SECRET_ACCESS_KEY: \x1B[0m"
  read AWS_SECRET_ACCESS_KEY && export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}"
fi

echo

# Initialize Terraform
${TERRAFORM} get
${TERRAFORM} init

# Create remote state store
${TERRAFORM} apply --auto-approve --target=module.remote_state
${TERRAFORM} init --force-copy

# Deploy infrastructure
${TERRAFORM} apply --auto-approve

# Create subnets template
${TERRAFORM} output -json \
| docker run --rm -i ryane/gensubnets:0.1 \
| sed 's/^/  /' \
> subnets.yaml
