#!/bin/bash

set -xe

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Some dependent AWS modules (EKS, RDS) do not yet support Terraform 0.12,
# So we need to clone the repo, which has patched versions of the dependent
# modules locally installed.
if [ ! -d $DIR/modules/terraform-aws-astronomer-aws ]; then
  mkdir -p $DIR/modules || true
  cd $DIR/modules
  git clone https://github.com/astronomer/terraform-aws-astronomer-aws.git
  cd $DIR
fi
# We still need to publish the top-level umbrella chart. Right now,
# are only publishing each subchart individually (chart - helm terminology)
if [ ! -d $DIR/helm.astronomer.io ]; then
  git clone https://github.com/astronomer/helm.astronomer.io.git
fi

terraform init

# deploy EKS, RDS
terraform apply -var-file=$DIR/terraform.tfvars.sample --target=module.aws --auto-approve

# install Tiller in the cluster
terraform apply -var-file=$DIR/terraform.tfvars.sample --target=module.system_components --auto-approve

# install astronomer in the cluster
terraform apply -var-file=$DIR/terraform.tfvars.sample --target=module.astronomer --auto-approve

# write CNAME record based on the fetched internal LB name
terraform apply -var-file=$DIR/terraform.tfvars.sample --target=aws_route53_record.astronomer --auto-approve
