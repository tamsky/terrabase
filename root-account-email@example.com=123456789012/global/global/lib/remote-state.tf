data "aws_caller_identity" "global-global-lib" {}

##
# imports tfstate from backend as ${terraform_remote_state.global.output.<varname>}
##
data "terraform_remote_state" "global" {
    backend = "s3"
    config {
        key = "global/terraform.tfstate"
        bucket = "${data.aws_caller_identity.global-global-lib.account_id}-tfstate-global"
        region = "${var.tf_remote_state_s3_bucket_global_region}"        # must match terragrunt{remote_state{config{region=...}}}
        profile = "${var.tf_remote_state_s3_bucket_global_profile_name}" # must match terragrunt{remote_state{config{profile=...}}}
    }
}
