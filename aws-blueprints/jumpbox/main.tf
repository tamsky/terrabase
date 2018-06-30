variable "instance_count" { default = "1" }
variable "instance_type" { default = "t2.medium" }
variable "role_name" { default = "jumpbox" }

data "aws_ami" "ubuntu_server_ami" {
    most_recent       = true
    owners            = ["099720109477"] # Canonical, Inc.

    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
    }
}

resource "aws_eip" "main-static" {
    vpc = true
    instance = "${aws_instance.main.id}"
}

resource "aws_eip_association" "main-static" {
    allocation_id = "${aws_eip.main-static.id}"
    instance_id = "${aws_instance.main.id}"
}


resource "aws_instance" "main" {
    count = "${var.instance_count}"
    ami                         = "${data.aws_ami.ubuntu_server_ami.id}"
#   availability_zone           = <computed from subnet_id>
    monitoring                  = false
    key_name                    = "${var.vpc_default_ssh_key_name}-${var.environment}"
    subnet_id                   = "${element(data.terraform_remote_state.core.public_subnets, count.index)}"
    source_dest_check           = true
    vpc_security_group_ids      = [
        "${data.terraform_remote_state.core.security-group-jumpbox}",
        "${data.terraform_remote_state.core.security-group-consul-members}",
    ]
    iam_instance_profile        = "default-${var.environment}"

    ebs_optimized               = false # unsupported on t2 instance types
    instance_type               = "${var.instance_type}"
    root_block_device {
        volume_type           = "standard"
        volume_size           = 10
        delete_on_termination = true
    }

    associate_public_ip_address = true
    // NB: associate_public_ip_address = false
    // is a glorified noop, as the private/public flag for the subnet_id 
    // is what actually controls the outcome.
    //
    // details at: https://github.com/hashicorp/terraform/issues/8244

    // use DHCP by not providing a fixed private_ip:
    //    private_ip                  = ""
    
    // when done testing, uncomment to protect from accidental termination:
    // disable_api_termination     = true

    tags {
        "Name" = "${var.role_name} ${var.environment} ${count.index}"
        "environment" = "${var.environment}"
        "role" = "${var.role_name}"
        "instance" = "${count.index}"
        "fqdn" = "${count.index}.${var.role_name}.${var.vpc_dns_zone_name}"
    }

    user_data = "${module.cloud-config.cloud-config-user-data-rendered}"

    connection {
        type = "ssh"
        user = "ec2-user"
        agent = "true"
    }

    provisioner "remote-exec" {
        inline = [
            # test access
            "sudo id"
        ]
    }
    
}

// Individual Route53 DNS Records for ec2 instances
resource "aws_route53_record" "per-instance" {
  provider = "aws.route53"
  count = "${var.instance_count}"
  zone_id = "${lookup(data.terraform_remote_state.route53.environment_zone_map, var.environment, "MISSING")}"
  name = "${count.index}.${var.role_name}.${lookup(data.terraform_remote_state.route53.environment_zone_name_map, var.environment, "MISSING")}"
  type = "A"
  ttl = "300"
#  records = ["${element(aws_instance.main.*.public_ip,count.index)}"]
  records = ["${aws_eip.main-static.public_ip}"]
}

// instance 0 gets a shorter name:
resource "aws_route53_record" "main" {
  provider = "aws.route53"
  zone_id = "${lookup(data.terraform_remote_state.route53.environment_zone_map, var.environment, "MISSING")}"
  name = "${var.role_name}.${lookup(data.terraform_remote_state.route53.environment_zone_name_map, var.environment, "MISSING")}"
  type = "A"
  ttl = "300"
#  records = ["${aws_instance.main.0.public_ip}"]
  records = ["${aws_eip.main-static.public_ip}"]
}

#############
# user data #
#############

module "cloud-config" {
    source = "../../modules/cloud-config-user-data"
    name = "${var.role_name}"
    environment = "${var.environment}"
    vpc_dns_zone_name = "${var.vpc_dns_zone_name}"
}

output "cloud-init-size-bytes" {
    value = "${length(module.cloud-config.cloud-config-user-data-rendered)}"
}
