# interpolation hints: 
#
# vpc_supernet_prefix = "${lookup(data.terraform_remote_state.global.vpc_environment_numbering_map, var.environment, "unknown")}"

# default SuperNet netblock length is /16:
variable "vpc_supernet_cidr_netblock_prefix" { default = "10" }  # IP first octet
variable "vpc_supernet_cidr_netblock_length" { default = "16" }


module "vpc" {
    source = "git::ssh://git@github.com/terraform-aws-modules/terraform-aws-vpc?ref=v1.37.0"

    name = "${var.vpc_name}"

    cidr = "${var.vpc_supernet_cidr_netblock_prefix}.${lookup(data.terraform_remote_state.global.vpc_environment_numbering_map, var.environment, "unknown")}.0.0/${var.vpc_supernet_cidr_netblock_length}"

    # specify some placeholder subnets
    # by doing so, the module also creates public and private route_tables for us.
    #
    # Due to https://github.com/hashicorp/terraform/issues/3888
    # We employ "Workaround 1" from https://github.com/hashicorp/terraform/issues/10857#issuecomment-268167035
    # to avoid computing length() on the computed `*_subnets` value.
    public_subnets  = [
        "${var.vpc_supernet_cidr_netblock_prefix}.${lookup(data.terraform_remote_state.global.vpc_environment_numbering_map, var.environment, "unknown")}.0.0/24",
        "${var.vpc_supernet_cidr_netblock_prefix}.${lookup(data.terraform_remote_state.global.vpc_environment_numbering_map, var.environment, "unknown")}.1.0/24",
        "${var.vpc_supernet_cidr_netblock_prefix}.${lookup(data.terraform_remote_state.global.vpc_environment_numbering_map, var.environment, "unknown")}.2.0/24",
    ]
#    public_subnets_count = 3

    private_subnets = [
        "${var.vpc_supernet_cidr_netblock_prefix}.${lookup(data.terraform_remote_state.global.vpc_environment_numbering_map, var.environment, "unknown")}.10.0/24",
        "${var.vpc_supernet_cidr_netblock_prefix}.${lookup(data.terraform_remote_state.global.vpc_environment_numbering_map, var.environment, "unknown")}.11.0/24",
        "${var.vpc_supernet_cidr_netblock_prefix}.${lookup(data.terraform_remote_state.global.vpc_environment_numbering_map, var.environment, "unknown")}.12.0/24",
    ]
#    private_subnets_count = 3

    enable_nat_gateway = "true"
    enable_dns_support = "true"
    enable_dns_hostnames = "true"

    azs = "${formatlist("%s%s",lookup(data.terraform_remote_state.global.vpc_environment_region_map, var.environment, "UNKNOWN"),split(",",lookup(data.terraform_remote_state.global.vpc_environment_azs_map, var.environment, "UNKNOWN")))}"

    tags = {
        environment = "${var.environment}"
    }
}

# TODO(mtamsky): move all fixed-value outputs (no references the module above)
#                to null_resource.triggers so that anyone else in this directory
#                that needs the value doesn't have to duplicate this code:
output "vpc_azs_list" {
    value = [ "${formatlist("%s%s",lookup(data.terraform_remote_state.global.vpc_environment_region_map, var.environment, "UNKNOWN"),split(",",lookup(data.terraform_remote_state.global.vpc_environment_azs_map, var.environment, "UNKNOWN")))}" ]
}
output "vpc_azs_list_count" {
    value = "${length(split(",",lookup(data.terraform_remote_state.global.vpc_environment_azs_map, var.environment, "UNKNOWN")))}"
}

output "vpc_network_prefix" {
    value = "${var.vpc_supernet_cidr_netblock_prefix}.${lookup(data.terraform_remote_state.global.vpc_environment_numbering_map, var.environment, "unknown")}"
}

output "supernet_cidr_prefix" {
    value = "${var.vpc_supernet_cidr_netblock_prefix}.${lookup(data.terraform_remote_state.global.vpc_environment_numbering_map, var.environment, "unknown")}"
}
output "supernet_cidr" {
    value = "${var.vpc_supernet_cidr_netblock_prefix}.${lookup(data.terraform_remote_state.global.vpc_environment_numbering_map, var.environment, "unknown")}.0.0/${var.vpc_supernet_cidr_netblock_length}"
}

# TODO(mtamsky): the following list of outputs should contain all module outputs from
# - https://github.com/terraform-aws-modules/terraform-aws-vpc#outputs
#
output "database_subnet_group" {
    value = "${module.vpc.database_subnet_group}"
    description = "ID of database subnet group"
}

output "database_subnets" {
    value = "${module.vpc.database_subnets}"
    description = "List of IDs of database subnets"
}

output "database_subnets_cidr_blocks" {
    value = "${module.vpc.database_subnets_cidr_blocks}"
    description = "List of cidr_blocks of database subnets"
}

output "default_network_acl_id" {
    value = "${module.vpc.default_network_acl_id}"
    description = "The ID of the default network ACL"
}

output "default_route_table_id" {
    value = "${module.vpc.default_route_table_id}"
    description = "The ID of the default route table"
}

output "default_security_group_id" {
    value = "${module.vpc.default_security_group_id}"
    description = "The ID of the security group created by default on VPC creation"
}

output "default_vpc_cidr_block" {
    value = "${module.vpc.default_vpc_cidr_block}"
    description = "The CIDR block of the VPC"
}

output "default_vpc_default_network_acl_id" {
    value = "${module.vpc.default_vpc_default_network_acl_id}"
    description = "The ID of the default network ACL"
}

output "default_vpc_default_route_table_id" {
    value = "${module.vpc.default_vpc_default_route_table_id}"
    description = "The ID of the default route table"
}

output "default_vpc_default_security_group_id" {
    value = "${module.vpc.default_vpc_default_security_group_id}"
    description = "The ID of the security group created by default on VPC creation"
}

output "default_vpc_enable_dns_hostnames" {
    value = "${module.vpc.default_vpc_enable_dns_hostnames}"
    description = "Whether or not the VPC has DNS hostname support"
}

output "default_vpc_enable_dns_support" {
    value = "${module.vpc.default_vpc_enable_dns_support}"
    description = "Whether or not the VPC has DNS support"
}

output "default_vpc_id" {
    value = "${module.vpc.default_vpc_id}"
    description = "Default VPC"
}

output "default_vpc_instance_tenancy" {
    value = "${module.vpc.default_vpc_instance_tenancy}"
    description = "Tenancy of instances spin up within VPC"
}

output "default_vpc_main_route_table_id" {
    value = "${module.vpc.default_vpc_main_route_table_id}"
    description = "The ID of the main route table associated with this VPC"
}

output "elasticache_subnet_group" {
    value = "${module.vpc.elasticache_subnet_group}"
    description = "ID of elasticache subnet group"
}

output "elasticache_subnet_group_name" {
    value = "${module.vpc.elasticache_subnet_group_name}"
    description = "Name of elasticache subnet group"
}

output "elasticache_subnets" {
    value = "${module.vpc.elasticache_subnets}"
    description = "List of IDs of elasticache subnets"
}

output "elasticache_subnets_cidr_blocks" {
    value = "${module.vpc.elasticache_subnets_cidr_blocks}"
    description = "List of cidr_blocks of elasticache subnets"
}

output "igw_id" {
    value = "${module.vpc.igw_id}"
    description = "Internet Gateway"
}

output "intra_route_table_ids" {
    value = "${module.vpc.intra_route_table_ids}"
    description = "List of IDs of intra route tables"
}

output "intra_subnets" {
    value = "${module.vpc.intra_subnets}"
    description = "List of IDs of intra subnets"
}

output "intra_subnets_cidr_blocks" {
    value = "${module.vpc.intra_subnets_cidr_blocks}"
    description = "List of cidr_blocks of intra subnets"
}

output "nat_ids" {
    value = "${module.vpc.nat_ids}"
    description = "List of allocation ID of Elastic IPs created for AWS NAT Gateway"
}

output "nat_public_ips" {
    value = "${module.vpc.nat_public_ips}"
    description = "List of public Elastic IPs created for AWS NAT Gateway"
}

output "natgw_ids" {
    value = "${module.vpc.natgw_ids}"
    description = "List of NAT Gateway IDs"
}

output "private_route_table_ids" {
    value = "${module.vpc.private_route_table_ids}"
    description = "List of IDs of private route tables"
}

output "private_subnets" {
    value = [ "${module.vpc.private_subnets}" ]
    description = "List of IDs of private subnets"
}

output "private_subnets_cidr_blocks" {
    value = [ "${module.vpc.private_subnets_cidr_blocks}" ]
    description = "List of cidr_blocks of private subnets"
}

output "public_route_table_ids" {
    value = [ "${module.vpc.public_route_table_ids}" ]
    description = "List of IDs of public Route tables"
}

output "public_subnets" {
    value = [ "${module.vpc.public_subnets}" ]
    description = "List of IDs of public subnets"
}

output "public_subnets_cidr_blocks" {
    value = [ "${module.vpc.public_subnets_cidr_blocks}" ]
    description = "List of cidr_blocks of public subnets"
}

output "redshift_subnet_group" {
    value = "${module.vpc.redshift_subnet_group}"
    description = "ID of redshift subnet group"
}

output "redshift_subnets" {
    value = "${module.vpc.redshift_subnets}"
    description = "List of IDs of redshift subnets"
}

output "redshift_subnets_cidr_blocks" {
    value = "${module.vpc.redshift_subnets_cidr_blocks}"
    description = "List of cidr_blocks of redshift subnets"
}

output "vgw_id" {
    value = "${module.vpc.vgw_id}"
    description = "VPN Gateway"
}

output "vpc_cidr_block" {
    value = "${module.vpc.vpc_cidr_block}"
    description = "The CIDR block of the VPC"
}

output "vpc_enable_dns_hostnames" {
    value = "${module.vpc.vpc_enable_dns_hostnames}"
    description = "Whether or not the VPC has DNS hostname support"
}

output "vpc_enable_dns_support" {
    value = "${module.vpc.vpc_enable_dns_support}"
    description = "Whether or not the VPC has DNS support"
}

output "vpc_endpoint_dynamodb_id" {
    value = "${module.vpc.vpc_endpoint_dynamodb_id}"
    description = "The ID of VPC endpoint for DynamoDB"
}

output "vpc_endpoint_dynamodb_pl_id" {
    value = "${module.vpc.vpc_endpoint_dynamodb_pl_id}"
    description = "The prefix list for the DynamoDB VPC endpoint."
}

output "vpc_endpoint_s3_id" {
    value = "${module.vpc.vpc_endpoint_s3_id}"
    description = "VPC Endpoints"
}

output "vpc_endpoint_s3_pl_id" {
    value = "${module.vpc.vpc_endpoint_s3_pl_id}"
    description = "The prefix list for the S3 VPC endpoint."
}

output "vpc_id" {
    value = "${module.vpc.vpc_id}"
    description = "The ID of the VPC"
}

output "vpc_instance_tenancy" {
    value = "${module.vpc.vpc_instance_tenancy}"
    description = "Tenancy of instances spin up within VPC"
}

output "vpc_main_route_table_id" {
    value = "${module.vpc.vpc_main_route_table_id}"
    description = "The ID of the main route table associated with this VPC"
}
