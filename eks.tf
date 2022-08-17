##main-tf
provider "aws" {
    region = "us-east-1"
}

##########################################################################################################################################
##EKS-cluster
resource "aws_iam_role" "iam-cluster" {
  name = "test-cluster-cluster"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },a
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "iam-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.iam-cluster.name
}

resource "aws_iam_role_policy_attachment" "iam-cluster-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.iam-cluster.name
}

resource "aws_security_group" "sg-cluster" {
  name        = "test-cluster-cluster"
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "test-cluster"
  }
}

resource "aws_security_group_rule" "sg-cluster-ingress-workstation-https" {
  cidr_blocks       = [local.workstation-external-cidr]
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.sg-cluster.id
  to_port           = 443
  type              = "ingress"
}

resource "aws_eks_cluster" "test-cluster" {
  name     = test-cluster
  role_arn = aws_iam_role.iam-cluster.arn
  version  = "1.22"

  vpc_config {
    security_group_ids = [aws_security_group.sg-cluster.id]
    subnet_ids         = aws_subnet.public-subnet-1[*].id
    subnet_ids         = aws_subnet.public-subnet-2[*].id
  }

  depends_on = [
    aws_iam_role_policy_attachment.iam-cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.iam-cluster-AmazonEKSVPCResourceController,
  ]
}

##################################################################################################################################################

##Node-Group
# EKS Worker Nodes Resources
#  * IAM role allowing Kubernetes actions to access other AWS services
#  * EKS Node Group to launch worker nodes
#

resource "aws_iam_role" "test-ng" {
  name = "terraform-eks-test-ng"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "test-ng-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.test-ng.name
}

resource "aws_iam_role_policy_attachment" "test-ng-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.test-ng.name
}

resource "aws_iam_role_policy_attachment" "test-ng-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.test-ng.name
}



resource "aws_eks_node_group" "demo-ng" {
  cluster_name    = aws_eks_cluster.test_eks
  node_group_name = "demo-ng"
  node_role_arn   = aws_iam_role.test-ng.arn
  subnet_ids      = aws_subnet.private-subnet-1[*].id
  subnet_ids      = aws_subnet.private-subnet-2[*].id
  disc_size       = 10
  instance_types  = ["t2.micro"]


  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 1
  }

  update_config {
    max_unavailable = 2
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.test-ng-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.test-ng-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.test-ng-AmazonEC2ContainerRegistryReadOnly,
  ]
}

###################################################################################################################################################

##Creating VPC
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  instance_tendancy = "default"
  enable_dns_hostname = true

  tags = {
    name = "test_vpc"
  }
}

#Creating Internet Gateway
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags = {
    name = "test_igw"
  }
}

#Creating 2 Public Subnet
resource "aws_subnet" "public-subnet-1" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "10.0.0.0/24"
  availability_zone  = "us-east-1a"
  map_publicip_on_launch = true

  tags = {
      name = "public subnet 1"
  }
}

resource "aws_subnet" "public-subnet-2" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "10.0.1.0/24"
  availability_zone  = "us-east-1b"
  map_publicip_on_launch = true

  tags = {
     name = "public subnet 2"
   }
}

##Create Rout Table For Public Subnet
resource "aws_route_table" "public-route-table" {
  vpc_id = "${aws_vpc.vpc.id}"
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.internet_gateway.id}"
  }

  tags  = {
    name = "public route table"
  }
}

#Adding Public Subnet to Route Table
resource "aws_route_table_association" "public-subnet-1-route-table-association" {
  subnet_id      = "${aws_subnet.public-subnet-1.id}"
  route_table_id = "${aws_route_table.public-route-table.id}"
}

resource "aws_route_table_association" "public-subnet-2-route-table-association" {
  subnet_id      = "${aws_subnet.public-subnet-2.id}"
  route_table_id = "${aws_route_table.public-route-table.id}"
}

#Creating 2 Private Subnet
resource "aws_subnet" "private-subnet-1" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "10.0.2.0/24"
  availability_zone_id = "us-east-1a"
  map_publicip_on_launch = false

tags = {
   name = "private_subnet-1"
  }
}

resource "aws_subnet" "private-subnet-2" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "10.0.3.0/24"
  availability_zone_id = "us-east-1b"
  map_publicip_on_launch = false

tags = {
   name = "private_subnet-2"
  }
}

resource "aws_subnet" "private-subnet-3" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "10.0.4.0/24"
  availability_zone_id = "us-east-1a"
  map_publicip_on_launch = false

tags = {
   name = "private_subnet-3"
  }
}

resource "aws_subnet" "private-subnet-4" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "10.0.5.0/24"
  availability_zone_id = "us-east-1b"
  map_publicip_on_launch = false

tags = {
   name = "private_subnet-4"
  }
}

