terragrunt = {
    include = {
        path = "../terragrunt-${get_env("USE_LOCAL_SOURCE","default")}-config.tfvars"
    }
    dependencies = {
        paths = [ "key_pairs" ]
    }
}
