



resource "aws_iam_role" "eks-role" {
  name = "eks-cluster-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

#  This policy let kubernetes to manage resources on your behalf
# some tasks permited
# autoscaling read and update the configuration
# ec2 work with volumens and network resources that are associated to amazon EC2 nodes
# elasticloadbalancing let k8s works with ELB and add nodes to them as targets.
# iam let k8s control plane can dynamically provision ELB requested by K8S services
resource "aws_iam_role_policy_attachment" "eks-amazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-role.name
}




# Retrieving all subnets with tag eks=deployment
data "aws_subnets" "subnetsids" {
  depends_on = [
    aws_vpc.main_vpc, aws_subnet.eks_private_subnet, aws_subnet.eks_public_subnet
  ]
  filter {
    name   = "vpc-id"
    values = [aws_vpc.main_vpc.id]
  }

  tags = {
    "eks" = "deployment"
  }
}


#Provisioning the EKS cluster deployment
resource "aws_eks_cluster" "eks-deployment" {

  depends_on = [
    aws_vpc.main_vpc, aws_subnet.eks_private_subnet, aws_subnet.eks_public_subnet, aws_iam_role_policy_attachment.eks-amazonEKSClusterPolicy
  ]

  name    = var.cluster_deployment_name
  version = var.version_eks_deployment
  role_arn = aws_iam_role.eks-role.arn

  vpc_config {
    # subnet_ids = data.aws_subnets.subnetsids.ids
    subnet_ids = aws_subnet.eks_private_subnet[*].id
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access = var.cluster_endpoint_public_access
  }

  kubernetes_network_config {
    service_ipv4_cidr = var.k8s_service_ipv4_cidr
    ip_family = "ipv4"
  }

  encryption_config {
    provider {
      key_arn = aws_kms_key.eks.arn
    }
    resources = [ "secrets" ]
  }


  timeouts {
    create = "1h"
    delete = "1h"
  }


}


resource "aws_kms_key" "eks" {
    description = "eks secret key for ${var.cluster_deployment_name}"
    deletion_window_in_days = 7
    enable_key_rotation = true
}

###############################
##### security groups ##########
################################
locals {
  cluster_sg_name = coalesce(var.cluster_security_group_name,"${var.cluster_deployment_name}-sg-cluster")
  create_cluster_sg = var.create && var.create_security_group

  cluster_security_group_rules = { for k,v in {
       ingress_nodes_443 = {
        description  = "Node groups to cluster API"
        protocol     = "tcp"
        from_port    = 443
        to_port      = 443
        type         = "ingress"
        source_node_security_group = true
       }
    } : k => v if var.create_security_group
  }

}
resource "aws_security_group" "cluster" {
  count = local.create_cluster_sg ? 1 : 0
  name  = local.cluster_sg_name
  vpc_id = aws_vpc.main_vpc.id

  tags = merge(var.default_tags,{
    "Name" = local.cluster_sg_name
  }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "cluster" {
    for_each = { for k,v in merge(
        local.cluster_security_group_rules,
        var.cluster_security_group_additional_rules
    ) : k=>v if local.create_cluster_sg }

    from_port = each.value.from_port
    protocol = each.value.protocol
    security_group_id = aws_security_group.cluster[0].id
    to_port = each.value.to_port
    type = each.value.type
    cidr_blocks = [ aws_vpc.main_vpc.cidr_block]

#     source_security_group_id = lookup(each.value, "source_security_group_id",
#   lookup(each.value, "source_node_security_group", false)) ? local.node_security_group_id : null
}
