##
## ALLOW-EGRESS
##
output "security-group-allow-egress" {
  value = "${aws_security_group.allow-egress.id}"
}

resource "aws_security_group" "allow-egress" {
  name   = "${var.environment}-allow-egress"
  vpc_id = "${module.vpc.vpc_id}"

  tags = {
    Name        = "allow-egress"
    environment = "${var.environment}"
  }
}

resource "aws_security_group_rule" "allow-egress_egress_all" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.allow-egress.id}"
}

##
## INTERNAL-HAPROXY (use on target group instances receiving traffic from ALB on port 80)
##
output "security-group-internal-haproxy" {
  value = "${aws_security_group.internal-haproxy.id}"
}

resource "aws_security_group" "internal-haproxy" {
  name   = "${var.environment}-internal-haproxy"
  vpc_id = "${module.vpc.vpc_id}"

  tags = {
    Name        = "internal-haproxy"
    environment = "${var.environment}"
  }
}

resource "aws_security_group_rule" "internal-haproxy_ingress_80_tcp" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  # NOTE, this is the ELB security group, not "self"
  source_security_group_id = "${aws_security_group.internal-haproxy-alb.id}"

  security_group_id = "${aws_security_group.internal-haproxy.id}"
}

##
## EXTERNAL-HAPROXY (use on target group instances receiving traffic from ALB on port 80)
##
output "security-group-external-haproxy" {
  value = "${aws_security_group.external-haproxy.id}"
}

resource "aws_security_group" "external-haproxy" {
  name   = "${var.environment}-external-haproxy"
  vpc_id = "${module.vpc.vpc_id}"

  tags = {
    Name        = "external-haproxy"
    environment = "${var.environment}"
  }
}

resource "aws_security_group_rule" "external-haproxy_ingress_80_tcp" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  # NOTE, this is the ELB security group, not "self"
  source_security_group_id = "${aws_security_group.external-elb.id}"

  security_group_id = "${aws_security_group.external-haproxy.id}"
}

resource "aws_security_group_rule" "external-haproxy_egress_all" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.external-haproxy.id}"
}

##
## INTERNAL-HAPROXY-ALB (apply only to ALBs, not instances)
##
output "security-group-internal-haproxy-alb" {
  value = "${aws_security_group.internal-haproxy-alb.id}"
}

resource "aws_security_group" "internal-haproxy-alb" {
  name   = "${var.environment}-internal-haproxy-ALB"
  vpc_id = "${module.vpc.vpc_id}"

  tags = {
    Name        = "internal-haproxy-alb"
    environment = "${var.environment}"
  }
}

# allow the entire VPC access to the internal-haproxy-alb on tcp/443:
resource "aws_security_group_rule" "internal-haproxy-alb-port_443_tcp" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  cidr_blocks              = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.internal-haproxy-alb.id}"
}
resource "aws_security_group_rule" "internal-haproxy-alb_egress_allow_80_tcp" {
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  # allow egress to internal-haproxy instances:
  source_security_group_id = "${aws_security_group.internal-haproxy.id}"

  security_group_id = "${aws_security_group.internal-haproxy-alb.id}"
}

##
## EXTERNAL-ELB (apply only to external ELBs, not instances)
##
output "security-group-external-elb" {
  value = "${aws_security_group.external-elb.id}"
}

resource "aws_security_group" "external-elb" {
  name   = "${var.environment}-external-elb"
  vpc_id = "${module.vpc.vpc_id}"

  tags = {
    Name        = "external-elb"
    environment = "${var.environment}"
  }
}


resource "aws_security_group_rule" "external-elb_ingress_80_tcp" {
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.external-elb.id}"
}

resource "aws_security_group_rule" "external-elb_ingress_443_tcp" {
  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.external-elb.id}"
}

resource "aws_security_group_rule" "external-elb_egress_all" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  # TODO(mtamsky):
  # remove cidr_blocks, and convert to use port 80,443 and external-haproxy:
  # source_security_group_id = "${aws_security_group.external-haproxy.id}"

  security_group_id = "${aws_security_group.external-elb.id}"
}

##
## JUMPBOX
##
output "security-group-jumpbox" {
  value = "${aws_security_group.jumpbox.id}"
}

resource "aws_security_group" "jumpbox" {
  name   = "${var.environment}-jumpbox"
  vpc_id = "${module.vpc.vpc_id}"

  tags = {
    Name        = "jumpbox"
    environment = "${var.environment}"
  }
}

resource "aws_security_group_rule" "jumpbox_ingress_22_tcp" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.jumpbox.id}"
}

resource "aws_security_group_rule" "jumpbox_egress_all" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.jumpbox.id}"
}

##
## Allow SSH protocol from jump
##
output "security-group-allow-SSH-from-jump" {
  value = "${aws_security_group.allow-SSH-from-jump.id}"
}

resource "aws_security_group" "allow-SSH-from-jump" {
  name   = "${var.environment}-allow-SSH-from-jump"
  vpc_id = "${module.vpc.vpc_id}"

  tags = {
    Name        = "allow-SSH-from-jump"
    environment = "${var.environment}"
  }
}

resource "aws_security_group_rule" "ssh-from-jump_ingress_ssh" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "-1"
  source_security_group_id = "${aws_security_group.jumpbox.id}"

  security_group_id = "${aws_security_group.allow-SSH-from-jump.id}"
}

resource "aws_security_group_rule" "ssh-from-jump_egress_all" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.allow-SSH-from-jump.id}"
}

# ##
# ## Allow RDP protocol from jump
# ##
# output "security-group-allow-RDP-protocol-from-jump" {
#   value = "${aws_security_group.allow-RDP-protocol-from-jump.id}"
# }
# 
# resource "aws_security_group" "allow-RDP-protocol-from-jump" {
#   name   = "${var.environment}-allow-RDP-protocol-from-jump"
#   vpc_id = "${module.vpc.vpc_id}"
# 
#   tags = {
#     Name        = "allow-RDP-protocol-from-jump"
#     environment = "${var.environment}"
#   }
# 
#   ingress {
#     from_port       = 3389
#     to_port         = 3389
#     protocol        = "tcp"
#     security_groups = ["${aws_security_group.jumpbox.id}"]
#   }
# }



##
## CONSUL-MEMBERS
##
output "security-group-consul-members" {
  value = "${aws_security_group.consul-members.id}"
}

resource "aws_security_group" "consul-members" {
  name        = "${var.environment}-consul-members"
  description = "allow consul services"
  vpc_id      = "${module.vpc.vpc_id}"

  tags = {
    Name        = "consul-members"
    environment = "${var.environment}"
  }
}

resource "aws_security_group_rule" "consul_ingress_8301_8302_tcp" {
  # nodes with this security group can receive traffic on
  #   tcp/8300 (consul server)
  #   tcp/8301-8302 (serf lan, serf wan)
  # from instances with this security group.
  type      = "ingress"
  from_port = 8300
  to_port   = 8302
  protocol  = "tcp"
  self      = true
  security_group_id = "${aws_security_group.consul-members.id}"
}

resource "aws_security_group_rule" "consul_ingress_8301_8302_udp" {
  # nodes with this security group can receive traffic on
  #   udp/8301-8302 (serf lan, serf wan)
  # from instances with this security group.
  type      = "ingress"
  from_port = 8301
  to_port   = 8302
  protocol  = "udp"
  self      = true
  security_group_id = "${aws_security_group.consul-members.id}"
}

resource "aws_security_group_rule" "consul_ingress_8400_tcp" {
  # nodes with this security group can receive traffic on
  #   tcp/8400 (consul rpc)
  # from instances with this security group.
  type      = "ingress"
  from_port = 8400
  to_port   = 8400
  protocol  = "tcp"
  self      = true
  security_group_id = "${aws_security_group.consul-members.id}"
}

resource "aws_security_group_rule" "consul_ingress_8500_tcp" {
  # nodes with this security group can receive traffic on
  #   tcp/8500 (consul http)
  # from instances with this security group.
  type      = "ingress"
  from_port = 8500
  to_port   = 8500
  protocol  = "tcp"
  self      = true
  security_group_id = "${aws_security_group.consul-members.id}"
}

resource "aws_security_group_rule" "consul_egress_vpc" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["${var.vpc_supernet_cidr_netblock_prefix}.${lookup(data.terraform_remote_state.global.vpc_environment_numbering_map, var.environment, "unknown")}.0.0/${var.vpc_supernet_cidr_netblock_length}"]

  security_group_id = "${aws_security_group.consul-members.id}"
}


# ##
# ## Example: postgres
# ##
# output "security-group-pg" {
#   value = "${aws_security_group.pg.id}"
# }

# resource "aws_security_group" "postgres-example" {
#   name   = "${var.environment}-postgres-example"
#   vpc_id = "${module.vpc.vpc_id}"

#   tags = {
#     Name        = "postgres-example"
#     environment = "${var.environment}"
#   }

#   ingress {
#     from_port = 5432
#     to_port   = 5432
#     protocol  = "tcp"
#     self      = true
#   }
# }

##
## ES (elasticsearch)
##
output "security-group-es" {
  value = "${aws_security_group.es.id}"
}

resource "aws_security_group" "es" {
  name   = "${var.environment}-es"
  vpc_id = "${module.vpc.vpc_id}"

  tags = {
    Name        = "es"
    environment = "${var.environment}"
  }
}

resource "aws_security_group_rule" "es_ingress_9200_tcp" {
  type                     = "ingress"
  from_port                = 9200
  to_port                  = 9200
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.es-users.id}"

  security_group_id = "${aws_security_group.es.id}"
}

resource "aws_security_group_rule" "es_self_9200-9400_tcp" {
  type      = "ingress"
  from_port = 9200
  to_port   = 9400
  protocol  = "tcp"
  self      = true

  security_group_id = "${aws_security_group.es.id}"
}

resource "aws_security_group_rule" "es_egress_all" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.es.id}"
}

##
## ES-USERS (elasticsearch)
##
output "security-group-es-users" {
  value = "${aws_security_group.es-users.id}"
}

resource "aws_security_group" "es-users" {
  name   = "${var.environment}-es-users"
  vpc_id = "${module.vpc.vpc_id}"

  tags = {
    Name        = "es-users"
    environment = "${var.environment}"
  }
}

# TODO(mtamsky): I don't think we want this because then we will need to
# specify all egress rules for es-users, including consul.
resource "aws_security_group_rule" "es-users_egress_9200_tcp" {
  type                     = "egress"
  from_port                = 9200
  to_port                  = 9200
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.es.id}"

  security_group_id = "${aws_security_group.es-users.id}"
}
