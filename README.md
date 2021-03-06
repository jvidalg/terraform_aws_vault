## AWS VPC :: EC2 AutoScaling + RDS MariaDB + Vault private cluster + S3

### AWS VPC

The project is divided into the 3 following main directories:

- **management** : this directory will be used to create you remote state S3 bucket and the dynamo database where the locks will be managed.
- **modules** : each set of components are separated by type, these can be used or nor according the project/environment needs.
- **envs** : here we place subdirectories for each environment such dev, test, prod, etc. This way we can customize each environment with different values in the variables and avoid duplicating code by just sourcing the modules.


#### EC2 Module(application)

This module is composed by a launch configuration & autoscaling group & autoscaling policy, amazon ami provisioned through user-data template, elastic load balancer and cloudwatch metric alarm.

#### RDS MariaDB Module(database)

Creates MariaDB instance and optionally its replica, manages the settings for the database parameters group and database subnet group.

#### Vault Module(vault_cluster)

Uses the official module from hashicorp to create a vault cluster within our infrastructure, this module is called from the vault_private in order to generate the vault cluster needed for the vault-consul cluster.

#### Vault Private Module(vault_private)

Uses the official module from hashicorp to create a private cluster within our infrastructure, the ami containing vault and consul is also the official provided by hashicorp and is built using Packer. The module is adapted to use our project structure and infrastructure.

#### Vault Security Group Rules (vault_sg_rules)

It creates the security group rules for vault_cluster, vault_cluster passes the parameter values for the rules generation.


#### S3 Module(storage)

It creates a simple S3 bucket that can be further customized for specific purposes in future.

#### Networking Module

Creates the VPC, subnets, routetables, internate gateway and setups communication among all the resources.

##### Structure:
```bash

.
├── README.md
├── envs
│   ├── dev
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── terraform.tfvars
│   │   └── variables.tf
│   └── test
├── management
│   └── terraform_backend
│       ├── main.tf
│       ├── terraform.tfstate
│       └── terraform.tfstate.backup
└── modules
    ├── application
    │   ├── main.tf
    │   ├── outputs.tf
    │   ├── userdata.tpl
    │   └── variables.tf
    ├── database
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    ├── networking
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    ├── storage
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    ├── vault_cluster
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    ├── vault_private
    │   ├── main.tf
    │   ├── outputs.tf
    │   ├── user-data-consul.sh
    │   ├── user-data-vault.sh
    │   └── variables.tf
    └── vault_sg_rules
        ├── main.tf
        └── variables.tf
```

![Architecture](https://github.com/jvidalg/terraform_aws_vault/blob/assets/terraform_demo.001.png?raw=true)
#####  Setup your AWS profile

###### Create environment variables
```bash
export AWS_ACCESS_KEY_ID = ""
export AWS_SECRET_ACCESS_KEY = ""
```
###### Create credentials file
```bash
mkdir $HOME/.aws
echo "[default]
aws_access_key_id=
aws_secret_access_key= " >> $HOME/.aws/credentials
```

#####  Build the AWS Vault-Consul AMI

This AWS AMI is required for the Private Vault cluster from this demo, you must follow the steps from repo [ec2-ami-vault-consul](https://github.com/jvidalg/ec2-ami-vault-consul)
If you do not have your instances built from this or another AMI containing Vault and Consul pre-installed and configured, your cluster will not operate as this demo is designed.

#####  Build your customized environment

You will need to set the terraform-state-storage-s3 & dynamodb-terraform-state-lock names in your main.tf from the environment you will be working on. for example envs/dev/main.tf

```hcl
terraform {
  backend "s3" {
    bucket         = "yourDesiredBucketName"
    key            = "envs/dev/terraform.tfstate"
    dynamodb_table = "yourDesiredDBLockName"
    region         = "us-east-1"
  }
}
```

#####  Build remote state S3 bucket and dynamo DB for locking

Before you build your bucket and DB for the state file management, you should edit the name of the S3 bucket by going to management/terraform_backend/main.tf

Your code should look more like this:

```hcl
resource "aws_s3_bucket" "terraform-state-storage-s3" {
    bucket = "yourDesiredBucketName"

resource "aws_dynamodb_table" "dynamodb-terraform-state-lock" {
  name = "yourDesiredDBLockName"
  hash_key = "LockID"
```

Then you can run below command:

```bash
cd management/terraform_backend
terraform init
terraform plan
terraform apply
```

Once the above commands complete successfully, you can proceed with the environment creation.

#####  Build your customized environment

You will need to set the terraform-state-storage-s3 & dynamodb-terraform-state-lock names in your main.tf from the environment you will be working on. for example envs/dev/main.tf

```hcl
terraform {
  backend "s3" {
    bucket         = "yourDesiredBucketName"
    key            = "envs/dev/terraform.tfstate"
    dynamodb_table = "yourDesiredDBLockName"
    region         = "us-east-1"
  }
}
```

Once the change is made, run following commands to make terraform pull required modules:

```bash
cd envs/dev
terraform init
```
If above commands are successful, run the plan and apply:

```bash
terraform plan
terraform apply
```

## TERRAFORM ENTERPRISE

If you are going to be running this project using Terraform Enterprise, several steps will vary.

#### Setup new VCS

Once you have created your organization and workspaces, a [VCS Provider](https://app.terraform.io/app/terraform_demo/settings/version-control/add) should be added, in this case will be github.

Your workspace has to be associated to the github VCS, you can do this by opening your workspace -> Settings -> Version Control -> github.
Select the repository from the drop-down, the VPC Branch: "master", and include submodules on clone. Then save.

#### Add a private key to pull repositories from github.

In order to allow terraform enterprise to access your github repository and perform pulls, you need to setup a private key for which its public key is registered in github.

On the main menu bar at the top, click on Settings -> Manage SSH Keys -> Add the name and private key.
Go back to your working workspace, click on Settings -> SSH Keys -> Under the drop-down select the key name your just added in previous steps. Click on Update.

#### Generate token for TFE CLI

In Terraform Enterprise there are values that you need to setup although you had set them up in terraform.tfvars(which might not be a good idea to push it to your public repository due to the sensitive data it can include), to avoid setting up one at a time or manually through the terraform console, it is recommended to generate a [Token](https://www.terraform.io/docs/enterprise/users-teams-organizations/users.html#api-tokens):

Click on your User Settings(top right corner) -> Tokens -> Add description and generate.

#### Upload terraform.tfvars to your workspace

Install the [terraform enterprise CLI](https://www.terraform.io/docs/enterprise/api/index.html):

```bash
git clone git@github.com:hashicorp/tfe-cli.git
cd tfe-cli/bin
echo "export PATH=$PWD:\$PATH" >> ~/.bash_profile
source ~/.bash_profile
```
Export your token from last step:

```bash
export ATLAS_TOKEN="${YOUR_TOKEN}"
```

```bash
tfe pushvars -name ${YOUR_ENV_PATH} -var-file terraform.tfvars
```
Sample:

```bash
tfe pushvars -name /Users/theuser/terraform-aws/envs/dev -var-file terraform.tfvars
```

#### Launch Queue Plan
#### Enable Destroy in Queue Plan
