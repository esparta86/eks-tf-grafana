
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(var.default_tags, {
    Name = "nat"
  })
}


#  I thing it's enoutgh create one NAT for all
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.eks_public_subnet[0].id

  tags = merge(var.default_tags, {
    Name = "nat-eks-public"
  })

  depends_on = [
    aws_internet_gateway.igw,
    aws_subnet.eks_public_subnet
  ]
}
