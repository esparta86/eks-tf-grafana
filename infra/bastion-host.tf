
resource "aws_security_group" "ssh-sg-group-vm-public" {
    count = var.create-vms ? 1 : 0
    name = "ssh-sg-group-vm-public"
    vpc_id = aws_vpc.main_vpc.id

    tags = merge(var.default_tags,{
      "Name" = "ssh-sg-group-vm-public"
    })

    lifecycle {
      create_before_destroy = true
    }
}


resource "aws_security_group_rule" "ssh-rule-vms" {
    for_each = { for k,v in
    var.cluster_security_group_rules_vms : k => v if var.create-vms }

    from_port = each.value.from_port
    protocol = each.value.protocol
    security_group_id = aws_security_group.ssh-sg-group-vm-public[0].id
    to_port = each.value.to_port
    type = each.value.type
    cidr_blocks = each.value.cidr_blocks
}

resource "aws_security_group" "web-server-sg-bastion" {
  count = var.create-vms ? 1 : 0
  name = "ssh-web-server-group"
  vpc_id = aws_vpc.main_vpc.id

  tags = merge(var.default_tags,{
    "Name" = "sg-bastion-ssh"
  })

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_security_group_rule" "ssh-rule-bastion-server-vms" {
    for_each = { for k,v in
    var.cluster_security_group_rules_bastion_server_vms : k => v if var.create-vms }

    from_port = each.value.from_port
    protocol = each.value.protocol
    security_group_id = aws_security_group.web-server-sg-bastion[0].id
    to_port = each.value.to_port
    type = each.value.type
    source_security_group_id = aws_security_group.ssh-sg-group-vm-public[0].id
}


resource "aws_instance" "bastion_instance_private" {
  ami = var.ami_linux
  instance_type = "t2.small"
  subnet_id = aws_subnet.eks_private_subnet[0].id
  vpc_security_group_ids = [ aws_security_group.web-server-sg-bastion[0].id ]
  key_name = var.key_name

  user_data = file("${path.module}/user-data/setup-bastion.sh")


  tags = merge(var.default_tags,{
    "Name" = "bastion_instance_private"
  })

  depends_on = [ aws_security_group.web-server-sg-bastion ]

}

resource "aws_instance" "vm_instance_public" {
  ami = var.ami_linux
  instance_type = "t2.small"
  subnet_id = aws_subnet.eks_public_subnet[0].id
  vpc_security_group_ids = [ aws_security_group.ssh-sg-group-vm-public[0].id ]
  key_name = var.key_name
  associate_public_ip_address = true


  tags = merge(var.default_tags,{
    "Name" = "vm_instance_public"
  })

}
