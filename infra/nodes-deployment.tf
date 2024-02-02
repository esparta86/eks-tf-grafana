

resource "aws_iam_role" "nodes" {
  name = "eks-node-group-nodes"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })

}

# this policy let EKS Worker to connect to EKS Master
# resource "aws_iam_role_policy_attachment" "nodes-AmazonEKSWorkerNodePolicy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
#   role       = aws_iam_role.nodes.name
# }

# # this policy provides a plugin called amzon-vpc-cni-k8s
# # this plugin help us to provide a private IPV4 or IPV6 address from our VPC to each POD
# resource "aws_iam_role_policy_attachment" "nodes-AmazonEKS_CNI_Policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
#   role       = aws_iam_role.nodes.name
# }


# # Provide read-only access to Amazon EC2 Container Registry repositories
# resource "aws_iam_role_policy_attachment" "nodes-AmazonEC2ContainerRegistryReadOnly" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
#   role       = aws_iam_role.nodes.name
# }

resource "aws_iam_role_policy_attachment" "policies_attachment" {
  for_each = {
    for policy_arn in toset(var.list_policies_eks_role_node): basename(policy_arn) => policy_arn
  }
  policy_arn = each.value
  role = aws_iam_role.nodes.name
}




# # We should filter only private networks that belong to EKS DEPLOYMENT
# data "aws_subnets" "private_subnets_deployment_ids" {
#   depends_on = [
#     aws_vpc.main_vpc, aws_subnet.eks_private_subnet, aws_subnet.eks_public_subnet
#   ]

#   filter {
#     name   = "vpc-id"
#     values = [aws_vpc.main_vpc.id]
#   }

#   filter {
#     name   = "tag:eks"
#     values = ["deployment"]
#   }

#   filter {
#     name   = "tag:tier"
#     values = ["Private"]
#   }

#   #   tags = {
#   #     "tier" = "Private"
#   #   }
# }





# # # Provisioning EKS NODE GROUP
# # # # Important all subnets associated to EKS must exists and the EKS cluster already was created
resource "aws_eks_node_group" "private-nodes" {

  depends_on = [
    aws_vpc.main_vpc, aws_subnet.eks_private_subnet, aws_subnet.eks_public_subnet, aws_eks_cluster.eks-deployment
  ]

  cluster_name    = aws_eks_cluster.eks-deployment.name
  node_group_name = "private-nodes-eks-deployment"
  node_role_arn   = aws_iam_role.nodes.arn
  subnet_ids      = aws_subnet.eks_private_subnet[*].id
  version = var.version_eks_deployment
  # data.aws_subnets.private_subnets_deployment_ids.ids

  capacity_type   = "ON_DEMAND"
  instance_types  = ["t2.small"]
  scaling_config {
    desired_size = 1
    max_size     = 4
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    "role" = "deployment"
  }

  timeouts {
    create = lookup(var.timeouts_node_group,"create",null)
    update = lookup(var.timeouts_node_group,"update",null)
    delete = lookup(var.timeouts_node_group,"delete",null)
  }

  # lifecycle {
  #   create_before_destroy = true
  #   ignore_changes = [
  #     scaling_config[0].desired_size
  #    ]
  # }


 tags = merge(var.default_tags,{
   "name" = "private-nodes-eks-deployment"
 })


}


