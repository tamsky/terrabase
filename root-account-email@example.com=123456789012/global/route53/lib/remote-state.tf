data "aws_caller_identity" "global-route53-lib" {}

##
# imports tfstate from backend as ${terraform_remote_state.route53.output.<varname>}
##
data "terraform_remote_state" "route53" {
    backend = "s3"
    config {
        key = "route53/terraform.tfstate"
        bucket = "${data.aws_caller_identity.global-route53-lib.account_id}-tfstate-global"
        region = "${var.tf_remote_state_s3_bucket_global_region}"        # must match terragrunt{remote_state{config{region=...}}}
        profile = "${var.tf_remote_state_s3_bucket_global_profile_name}" # must match terragrunt{remote_state{config{profile=...}}}
    }
}
