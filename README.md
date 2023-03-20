# Databricks Workspace Deploy using Terraform

이 Repo는 [databricks terraform provider](https://registry.terraform.io/providers/databricks/databricks/latest/docs)를 이용해서 다양한 데이터브릭스 리소스를 AWS 계정에 배포하고 관리하는 예제를 포함합니다. 

### Repo 구성 
각 폴더별로 수록된 배포 스크립트는 다음 시나리오를 담고 있습니다.

- db_no_vpce : custom VPC 에 databricks workspace를 배포합니다. [AWS quickstart](https://aws-quickstart.github.io/quickstart-databricks-unified-data-analytics-platform/) 과 동일한 
- db_bp_3vpce : custom VPC 에 databricks workspace를 배포합니다. 일반적으로 [권고되는 regional endpoint 구성 설정](https://aws-quickstart.github.io/quickstart-databricks-unified-data-analytics-platform/) 배포를 따라 db_no_vpce 구성에 하기 3개의 resource 가 추가로 배포되어 보안 강화 및 데이터 전송 비용 절감을 위한 구성에 적합합니다. 

    + S3 VPC gateway endpoint
    + STS VPC interface endpoint
    + Kinesis VPC interface endpoint
- uc : unity catalog metastore 에 관련된 S3와 IAM role들을 생성합니다. <font color=red>*WIP*</font>

- privatelink: Dataplane - Control Plane 간의 연결구간은 AWS privatelink 를 사용하여 보안을 강화하는 배포 구성입니다. <font color=red>*WIP*</font>

### 변수값 설정 

폴더내의 input.tfvars 파일을 배포하려는 Databricks 접속 정보와 AWS access key/secret key 정보로 수정합니다. 

```
env_name = "databricks"
user_name = "[firstname.lastname]"
region = "ap-northeast-2"
databricks_account_id = "[databricks 의 account id account console서 확인]"
databricks_account_username="[databricks account owner email]"
databricks_account_password="[password]"
cross_account_arn="arn:aws:iam::2808xxx0xx9:role/role_name" # todos : 우선은 미리 role 만들어서 ARN입력 
aws_access_key_id="[aws access key id]"
aws_secret_acces_key="[secret key]"
databricks_aws_account_id="414351767826" # do not edit
```

local.tf 파일에는 배포 구성과 관련된 정보로 수정합니다. 
```
locals {
  vpc_cidr = "10.10.0.0/16" # modify this for VPC 
  root_bucket_name = "databricks-uniquebkt-rootbucket" # modify this for unique root dbfs s3 bucket name
  prefix = "databricks-workspace" # modify this for resource naming 
  tags = {
    Owner = "databricks-${var.user_name}"
    Environment = "${var.env_name}"

    }
  force_destroy = true #destroy root bucket when deleting stack?
}
```

### 수행 방법 
1. input.tfvars 파일과 local.tf 파일상의 각 정의된 변수값을 수정합니다. 
2. <code>terraform init </code> 을 수행해서 terraform과 provioder를 초기화 합니다. 
3. <code>terraform apply -var-file=input.tfvars</code> 를 수행해서 resouce를 배포합니다. 
