resource "aws_vpc_dhcp_options" "options" {
    domain_name = "${var.vpc_dns_zone_name}"

    # Also possible in AWS is the fixed resource ip of: 169.254.169.253
    domain_name_servers = ["127.0.0.1", "${var.vpc_supernet_cidr_netblock_prefix}.${lookup(data.terraform_remote_state.global.vpc_environment_numbering_map, var.environment, "unknown")}.0.2"]

    tags {
        environment = "${var.environment}"
    }
}

resource "aws_vpc_dhcp_options_association" "vpc" {
    vpc_id = "${module.vpc.vpc_id}"
    dhcp_options_id = "${aws_vpc_dhcp_options.options.id}"
}
