data "aws_caller_identity" "core-lib" {}

##
# imports tfstate from backend as ${data.terraform_remote_state.core.<varname>}
##
data "terraform_remote_state" "core" {
    backend = "s3"
    config {
        key = "core/terraform.tfstate"
        bucket = "${data.aws_caller_identity.core-lib.account_id}-tfstate-${var.environment}"
        region = "${var.vpc_region}"

        # profile here must match terragrunt{remote_state{config{profile=...}}}
        profile = "${var.tf_remote_state_s3_bucket_global_profile_name}"
    }
}

##
# imports tfstate from backend as ${data.terraform_remote_state.iam.<varname>}
##
data "terraform_remote_state" "iam" {
    backend = "s3"
    config {
        key = "iam/terraform.tfstate"
        bucket = "${data.aws_caller_identity.core-lib.account_id}-tfstate-global"
        region = "${var.vpc_region}"

        # profile here must match terragrunt{remote_state{config{profile=...}}}
        profile = "${var.tf_remote_state_s3_bucket_global_profile_name}"
    }
}

##
# imports tfstate from backend as ${data.terraform_remote_state.certs.<varname>}
##
data "terraform_remote_state" "certs" {
    backend = "s3"
    config {
        key = "certs/terraform.tfstate"
        bucket = "${data.aws_caller_identity.core-lib.account_id}-tfstate-global"
        region = "${var.vpc_region}"

        # profile here must match terragrunt{remote_state{config{profile=...}}}
        profile = "${var.tf_remote_state_s3_bucket_global_profile_name}"
    }
}

##
# imports tfstate from backend as ${data.terraform_remote_state.route53.<varname>}
##
data "terraform_remote_state" "route53" {
    backend = "s3"
    config {
        key = "route53/terraform.tfstate"
        bucket = "${data.aws_caller_identity.core-lib.account_id}-tfstate-global"
        region = "${var.vpc_region}"

        # profile here must match terragrunt{remote_state{config{profile=...}}}
        profile = "${var.tf_remote_state_s3_bucket_global_profile_name}"
    }
}
