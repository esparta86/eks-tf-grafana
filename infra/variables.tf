#  This file stores all variables to avoid stiky codes in tf files
variable "region" {
  default = "us-east-1"
}

variable "profile" {
  default = "personal"
}


# this variable has default tags

variable "default_tags" {
  default = {
    cloudprovider = "aws"
    owner         = "devops-team"
    Terraform     = "true"
    Environment   = "Development"
  }
  description = "Default tags name to tag in resources"
  type        = map(string)
}

# Name for deployment EKS cluster
variable "cluster_deployment_name" {
  default     = "eks_deployment01"
  description = "Cluster name"
  type        = string
}


variable "version_eks_deployment" {
  default     = "1.27"
  description = "version cluster"
  type        = string
}



variable "development_vpc_cidr" {
  description = "cidr for vpc"
  type        = string
  default     = "10.0.0.0/16"
}




# Name for deployment EKS cluster
variable "cluster_development_name" {
  default     = "eks_development01"
  description = "Cluster name"
  type        = string
}


variable "kube_config" {
  type = string
  default = "~/.kube/config"
}


variable "namespace_prometheus" {
  type = string
  default = "prometheus"
}


variable "list_policies_eks_role_node" {
  type = list(string)
  default = [ "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
  "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy" ]
}


# Private endpoints requires that VPC has this feature
variable "vpc_dns_hostnames" {
  type = bool
  default = true
}
# Private endpoints requires that VPC has this feature
variable "vpc_dns_support" {
 type = bool
 default = true
}

variable "cluster_endpoint_private_access" {
  type = bool
  default = true
  description = "Whether the Amazon EKS private API server endpoint is enabled"
}

variable "cluster_endpoint_public_access" {
  type = bool
  default = false
}


variable "k8s_service_ipv4_cidr" {
  type = string
  default = "192.168.0.0/20"
}


variable "cluster_security_group_name" {
  type = string
}

variable "create" {
  description = "Controls if EKS resources should be created (affects nearly all resources)"
  type        = bool
  default     = true
}

variable "create_security_group" {
  description = "Controls if EKS resources should be created (affects nearly all resources)"
  type        = bool
  default     = true
}


variable "cluster_security_group_additional_rules" {
  type = any
  default = {}
}


variable "timeouts_node_group" {
  type = map(string)
  default = {
    "create" = "1h",
    "update" = "2h",
    "delete" = "1h"
  }
}


variable "create-vms" {
  type = bool
  default = true
}

variable "cluster_security_group_rules_vms" {
  type = any
  default = {
    "ssh-anywhere" = {
       "type" = "ingress",
       "from_port" = 22,
       "to_port"   = 22,
       "protocol"  = "tcp",
       "cidr_blocks" = [ "0.0.0.0/0" ]
    }

    "all-traffic" = {
       "type" = "egress",
       "from_port" = 0,
       "to_port"   = 0,
       "protocol"  = "-1",
       "cidr_blocks" = [ "10.0.1.0/24","10.0.2.0/24" ]
    }
  }
}


variable "cluster_security_group_rules_bastion_server_vms" {
  type = any
  default = {
    "ssh-anywhere" = {
       "type" = "ingress",
       "from_port" = 22,
       "to_port"   = 22,
       "protocol"  = "tcp"
    }

    "all-traffic" = {
       "type" = "egress",
       "from_port" = 0,
       "to_port"   = 0,
       "protocol"  = "-1",
       "cidr_blocks" = [ "0.0.0.0/0" ]
    }
  }
}

variable "ami_linux" {
  type = string
  default = "ami-0cf10cdf9fcd62d37"
  # default = "ami-0c7217cdde317cfec"
}

variable "key_name" {
  type = string
  default = "ubuntu"
}
