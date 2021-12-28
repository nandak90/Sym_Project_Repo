#Defining the provider
provider "aws" {
    project = "Symbiosis-Portal"
}

#Creating a Virtual Private Cloud
resource "aws_vpc" "sym_vpc" {
    cidr_block  = "10.0.0.0/16"
    tags = {
        Name = "SYM_VPC"
  }
}

#Creating Subnets
resource "aws_subnet" "public_web_subnet_1" {
  tags = {
    Name = "Public Subnet 1"
  }
  vpc_id     = aws_vpc.sym_vpc.id
  cidr_block = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone = "ap-southeast-1"
}

resource "aws_subnet" "public_web_subnet_2" {
    tags = {
    Name = "Public Subnet 2"
  }
    vpc_id     = aws_vpc.sym_vpc.id
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = true
    availability_zone = "ap-southeast-2"
}

#Creating private DB Subnet
resource "aws_subnet" "private_db_subnet" {
    tags = {
    Name = "DB Subnet"
  }
    vpc_id     = aws_vpc.sym_vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "ap-northeast-1"
}

#Setting up an internet gateway
resource "aws_internet_gateway" "sym_vpc_igw" {
  tags = {
    Name = "SYM VPC Internet Gateway"
  }
  vpc_id = aws_vpc.sym_vpc.id
}

resource "aws_route_table" "sym_vpc_public" {
    tags = {
    Name = "Sym Public Route Table"
  }
    vpc_id = aws_vpc.sym_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.sym_vpc_igw.id
    }
}

resource "aws_route_table_association" "sym_vpc_ap_southeast_1_public" {
    subnet_id = aws_subnet.public_web_subnet_1.id
    route_table_id = aws_route_table.sym_vpc_public.id
}

resource "aws_route_table_association" "sym_vpc_ap_southeast_2_public" {
    subnet_id = aws_subnet.public_web_subnet_2.id
    route_table_id = aws_route_table.sym_vpc_public.id
}

#Creating a Security Group for the Web
resource "aws_security_group" "web_sg"{
    tags = {
    Name = "Web Security Group"
  }
    name = "web_sg"
    description = "Allow HTTP inbound traffic"
    vpc_id = aws_vpc.sym_vpc.id

    ingress {
    protocol = "tcp"
    from_port = 80
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

    egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Creating a Security Group for the Database
resource "aws_security_group" "db_sg"{
    tags = {
    Name = "DB Security Group"
  }
    name = "web_sg"
    description = "Allow HTTP inbound traffic"
    vpc_id = aws_vpc.sym_vpc.id
    ingress {
    protocol = "tcp"
    from_port = 5432
    to_port = 5432
    security_groups = [aws_security_group.web_sg.id]
  }

#Create Web Server
resource "aws_launch_configuration" "web" {
  name_prefix = "symweb-"

  image_id = "ami-0b28dfc7adc325ef4"
  instance_type = "t2.xlarge"
  key_name = "Sym Web Server"

  security_groups = [ aws_security_group.web_sg.id ]
  associate_public_ip_address = true

  USER_DATA

  lifecycle {
    create_before_destroy = true
  }
}

#Create RDS instance
resource "aws_db_instance" "sym_db" {
    allocated_storage = 20
    identifier = "symdatabase"
    storage_type = "gp2"
    engine = "postgres"
    engine_version = "11.0"
    instance_class = "db.m4.large"
    name = "symdb"
    username = "admin"
    password = "******"
    parameter_group_name = "default.postgres.11.0"
}

resource "aws_security_group" "elb_http_sg" {
  name = "elb_http"
  description = "HTTP traffic pass to instances through ELB"
  vpc_id = aws_vpc.sym_vpc.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Allow HTTP through ELB SG"
  }
}

resource "aws_elb" "elb_web" {
  name = "elb-web"
  security_groups = [
    aws_security_group.elb_http_sg.id
  ]
  subnets = [
    aws_subnet.public_web_subnet_1.id,
    aws_subnet.public_web_subnet_2.id
  ]

  cross_zone_load_balancing   = true

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "HTTP:80/"
  }

  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = "80"
    instance_protocol = "http"
  }
}

resource "aws_autoscaling_group" "web_asgroup" {
  name = "${aws_launch_configuration.web.name}-asg"

  min_size = 1
  desired_capacity = 2
  max_size = 4
  
  health_check_type = "ELB"
  load_balancers = [
    aws_elb.elb_web.id
  ]

  launch_configuration = aws_launch_configuration.web_asgroup.name

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

  metrics_granularity = "1Minute"

  vpc_zone_identifier = [
    aws_subnet.public_web_subnet_1.id,
    aws_subnet.public_web_subnet_2.id
  ]

  #Below to redeploy without an outage
  lifecycle {
    create_before_destroy = true
  }

  tag {
    key = "Name"
    value = "web_asgroup"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "web_as_policy" {
  name = "web_as_policy"
  scaling_adjustment = 1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = aws_autoscaling_group.web_asgroup.name
}

resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_high" {
  alarm_name = "web_cpu_alarm_high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "60"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asgroup.name
  }

  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions = [ aws_autoscaling_policy.web_cpu_alarm_high.arn ]
}

resource "aws_autoscaling_policy" "web_cpu_alarm_low" {
  name = "web_cpu_alarm_low"
  scaling_adjustment = -1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = aws_autoscaling_group.web_asgroup.name
}

resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_low" {
  alarm_name = "web_cpu_alarm_down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "10"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_as_group.name
  }

  alarm_description = "This will monitor EC2 instance CPU utilization"
  alarm_actions = [ aws_autoscaling_policy.web_cpu_alarm_low.arn ]
}

output "elb_dns_name" {
  value = aws_elb.elb_web.dns_name
}
