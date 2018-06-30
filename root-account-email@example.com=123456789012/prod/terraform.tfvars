# This file is meant to only be included, not used directly.

terragrunt {
    # Configure Terragrunt to automatically store tfstate files in an S3 bucket, with locking
    remote_state = {
        backend = "s3"
        config {
            profile = "example"   # selects a credential within ~/.aws/credentials

            # bucket names that contain '+++' or end with '.' are illegal
            bucket = "example-terraform-${get_env("AWS_ACCOUNT_ID","+++")}-${get_env("ENVIRONMENT",".")}"
            key = "${path_relative_to_include()}/terraform.tfstate"
            region = "us-west-2"   # Oregon is the bestest closest region
            encrypt = true
        }
    }
    terraform {
        # Can be speed up local development:
        #
        # extra_arguments "init_args" {
        #     commands = [
        #         "init"
        #     ]

        #     arguments = [
        #         "-get-plugins=true",
        #         "-plugin-dir=/tmp/terraform/plugins"
        #     ]
        # }

# Deploy from local checkout: (roles w/subdirs may need to use additional '../')
#         source = "file::${get_env("PWD","ERROR")}/../../..//aws-blueprints/${path_relative_to_include()}"
# Deploy from github repo, 'master' branch:
        source = "git::git@github.com:example/terraform//aws-blueprints/${path_relative_to_include()}?ref=master"
    }
}
