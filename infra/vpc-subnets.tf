
resource "aws_vpc" "main_vpc" {
  cidr_block = var.development_vpc_cidr
  enable_dns_hostnames = var.vpc_dns_hostnames
  enable_dns_support = var.vpc_dns_support

  tags = merge(var.default_tags, {
    Name = "main"
  })
}



data "aws_availability_zones" "available" {
  filter {
    name   = "zone-name"
    values = ["us-east-1a", "us-east-1b"]
  }
}



# cidrsubnet("10.0.0.0/16",8,1)
# "10.0.1.0/24"
# > cidrsubnet("10.0.0.0/16",8,2)
# "10.0.2.0/24"
resource "aws_subnet" "eks_private_subnet" {
  count             = length(data.aws_availability_zones.available.names)
  vpc_id            = aws_vpc.main_vpc.id
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  cidr_block        = cidrsubnet(var.development_vpc_cidr, 8, count.index + 1)

  tags = merge(var.default_tags, {
    "Name"                            = "eks-private-subnet-${count.index}-${element(data.aws_availability_zones.available.names, count.index)}"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/demo"      = "owned"
    "tier"                            = "Private"
    "eks"                             = "deployment"
  })

}




# We are using data sources to know how many subnets has been created so far
# To create new public subnets is required to know the total subnets
# related to deployment eks and private tag
data "aws_subnets" "list_private_subnets_deployment_eks_ids" {
  depends_on = [
    aws_vpc.main_vpc, aws_subnet.eks_private_subnet
  ]

  filter {
    name   = "vpc-id"
    values = [aws_vpc.main_vpc.id]
  }

  filter {
    name   = "tag:eks"
    values = ["deployment"]
  }

  filter {
    name   = "tag:tier"
    values = ["Private"]
  }

  # tags = {
  #   "eks" = "deployment"
  # }
}



# data.list_private_subnets_deployment_eks_ids stores all subnets created that has the tag: eks: deployment and tier: Private
resource "aws_subnet" "eks_public_subnet" {

  depends_on = [
    aws_vpc.main_vpc, aws_subnet.eks_private_subnet
  ]

  count             = length(data.aws_availability_zones.available.names)
  vpc_id            = aws_vpc.main_vpc.id
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  # We can not use just cidrsubnet(var.development_vpc_cidr, 8, count.index + 1) because it will produce an overlapping 
  # the CIDR Block have to start in the next jump from the last CIDR used by the eks_private subnets
  cidr_block = cidrsubnet(var.development_vpc_cidr, 8, length(data.aws_subnets.list_private_subnets_deployment_eks_ids.ids) + count.index + 1)
  tags = merge(var.default_tags, {
    "Name"                            = "eks-public-subnet-${count.index}-${element(data.aws_availability_zones.available.names, count.index)}"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/demo"      = "owned"
    "tier"                            = "Public"
    "eks"                             = "deployment"
    "kubernetes.io/cluster/${var.cluster_deployment_name}" = "shared"
  })

}





