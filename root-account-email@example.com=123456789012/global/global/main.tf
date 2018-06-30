variable "vpc_environment_region_map" {
    type = "map"
    default = {
        dev = "us-west-2"
        ops = "us-west-2"
        prod = "us-west-2"
    }
}
output "vpc_environment_region_map" {
    value = "${var.vpc_environment_region_map}"
}

variable "vpc_environment_azs_map" {
    type = "map"
    default = {
        dev = "a,b,c"   # when in us-west-2
        ops = "a,b,c"   # when in us-west-2
        prod = "a,b,c"  # when in us-west-2
    }
}
output "vpc_environment_azs_map" {
    value = "${var.vpc_environment_azs_map}"
}

variable "vpc_environment_numbering_map" {
    type = "map"
    default = {
        prod           = "11"
#        stage          = "22"
        dev            = "33"
       ops             = "111"
    }
}

output "vpc_environment_numbering_map" {
    value = "${var.vpc_environment_numbering_map}"
}
