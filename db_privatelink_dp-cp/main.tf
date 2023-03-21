terraform {
  required_providers {
      databricks = {
          source = "databricks/databricks"
      }
      aws = {
          source = "hashicorp/aws"
      }
  }
}

variable "region" { 
  type = string
  default = "ap-northeast-2"
}

variable "databricks_account_id" {
  type = string
  description = "Databricks account id from accounts console"
}

variable "cross_account_arn" {
  type = string
  description = "ARN of cross-account role"
}

variable "databricks_account_username" {
  type = string
}    
variable "databricks_account_password" {
  type = string
}

variable "databricks_aws_account_id" {
  type = string
  description = "Databricks AWS account id"
  default = "280842790059"
}

variable "env_name" {
  type = string
  default = "databricks workspace"
}

variable "user_name" {
    type = string
    description = "firstname.lastname"
}

variable "aws_access_key_id" {
    type= string
  
}

variable "aws_secret_acces_key" {
    type = string    
  
}

provider "aws" {
    region = var.region
    access_key = var.aws_access_key_id
    secret_key = var.aws_secret_acces_key

}

provider "databricks" {
  alias    = "accounts"
  host     = "https://accounts.cloud.databricks.com"
  username = var.databricks_account_username
  password = var.databricks_account_password
}


provider "databricks" {
  alias    = "mws"
  host     = "https://accounts.cloud.databricks.com"
  account_id = var.databricks_account_id
  username = var.databricks_account_username
  password = var.databricks_account_password
}

