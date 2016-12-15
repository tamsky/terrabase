variable "cluster_name" { default = "test-cluster-N" }
variable "instance_count" { default = "3" }
variable "role_name" { default = "elasticsearch" }

data "aws_ami" "master_or_ssd_data_node" {
    most_recent = true

    filter {
        name   = "root-device-type"
        values = ["ebs"]
    }

    filter {
        name   = "owner-alias"
        values = ["amazon"]
    }

    filter {
        name   = "architecture"
        values = ["x86_64"]
    }

    filter {
        name   = "name"
        values = ["amzn-ami-hvm-*"]
    }

    name_regex = "^amzn-ami-hvm-[0-9.]+-x86_64-(s3|gp2|ebs)$" # Don't use release candidate ami's
    owners     = ["amazon"]
}


##
## cloud-config YAML, per instance:
##
data "template_file" "user-data" {
    count = "${var.instance_count}"
    template = "${file("user-data.tftemplate")}"
    vars {
        instance = "${count.index}"
        role_name = "${var.role_name}"
        environment = "${var.environment}"
        cluster_name = "${var.cluster_name}"
    }
}

resource "aws_instance" "elasticsearch" {
    count                   = "${var.instance_count}"
    ami                     = "${data.aws_ami.master_or_ssd_data_node.id}"

#   availability_zone       = <computed from subnet_id>
    ebs_optimized           = false
    iam_instance_profile    = "${aws_iam_role.elasticsearch.id}"
    instance_type           = "i2.xlarge"
    key_name                = "${var.vpc_default_ssh_key_name}-${var.environment}"
    monitoring              = false
    source_dest_check       = true
    subnet_id               = "${element(data.terraform_remote_state.core.private_subnets, count.index)}"
    user_data               = "${element(data.template_file.user-data.*.rendered, count.index)}"
    vpc_security_group_ids  = []

// when not testing, uncomment to protect from accidental termination:
// disable_api_termination  = true

    tags {
        "Name" = "${var.role_name} ${var.environment} ${count.index}"
        "environment" = "${var.environment}"
        "role" = "${var.role_name}"
        "instance" = "${count.index}"
    }
}

// Route53 DNS Records for instances
resource "aws_route53_record" "elasticsearch" {
    count = "${var.instance_count}"
    zone_id = "<ZONE_ID_STRING>" // ${var.environment}.example.com
    name = "${count.index}.elasticsearch.${var.environment}.example.com"
    type = "A"
    ttl = "300"
    records = ["${element(aws_instance.elasticsearch.*.private_ip,count.index)}"]
}


resource "aws_iam_instance_profile" "elasticsearch" {
    name = "${var.role_name}-${var.environment}"
    roles = [ "${aws_iam_role.elasticsearch.name}" ]
}

resource "aws_iam_role" "elasticsearch" {
    name = "${var.role_name}-${var.environment}"
    path = "/"
    # required policy, do not modify:
    assume_role_policy = "${file("../../global/iam/policies/ec2/ec2_assume_role.json")}"
}

# policy from
#   http://stackoverflow.com/questions/32103603/elasticsearch-cloud-aws-plugin-not-working-with-iam-role
# possibly simpler policy at:
#   https://www.elastic.co/guide/en/elasticsearch/plugins/2.0/cloud-aws-discovery.html#cloud-aws-discovery-permissions
resource "aws_iam_role_policy" "elasticsearch" {
    name = "${var.role_name}-${var.environment}"
    role = "${aws_iam_role.elasticsearch.id}"
    policy = "${file("../../global/iam/policies/ec2/ec2_describe_elastic_plugin.json")}"
}
