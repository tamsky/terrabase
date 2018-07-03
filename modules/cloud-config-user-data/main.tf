# variables that build fqdn hostname in user-data:
variable "name" {} # role name?
variable "environment" {}
variable "vpc_dns_zone_name" {}     # INTERNAL_DNS_ZONE
# variable "public_dns_zone_name" {}  # EXTERNAL_DNS_ZONE

variable "cloud_init_readonly_s3_bucket_name_prefix" { default = "" }

variable "fqdn" { default = "" }
variable "additional_users_yml" { default = "" }
variable "additional_script" { default = [
        "99-cloud-config-user-data-default.sh",
        "#!/bin/bash\nexit 0\n"
    ]
}

# allow us to support generating a default windows cloud-init:
variable "use_powershell" { default = false }

# consul master related variables
variable "this_is_a_consul_master_node" { default = "false" }  # (string) "true" when master
variable "expected_master_node_count" { default = "" }
# consul master end

variable "slack_hook_url" { default = "" }

#############
# user data #
#############

## Static Files
# data "template_file" "etc-initd-consul" {
#     template = "${file("${path.module}/files/etc-init.d-consul.tftemplate")}"
# }

data "template_file" "install-consul" {
    template = "${file("${path.module}/files/install-consul.sh.tftemplate")}"
    vars {
        name = "${var.name}"
        environment = "${var.environment}"
        expected_master_node_count = "${var.expected_master_node_count}"
        this_is_a_consul_master_node = "${var.this_is_a_consul_master_node}"
    }
}

data "template_file" "linux-common" {
    template = "${file("${path.module}/files/setup-vars+hostname.sh.tftemplate")}"
    vars {
        name = "${var.name}"
        environment = "${var.environment}"
        vpc_dns_zone_name = "${var.vpc_dns_zone_name}"
        slack_hook_url = "${var.slack_hook_url}"
    }
}

data "template_file" "windows-common" {
    template = "${file("${path.module}/files/setup-vars+hostname.ps1.tftemplate")}"
    vars {
        name = "${var.name}"
        environment = "${var.environment}"
        vpc_dns_zone_name = "${var.vpc_dns_zone_name}"
        slack_hook_url = "${var.slack_hook_url}"
    }
}

data "template_file" "cloud-config" {
    template = "${file("${path.module}/files/cloud-init.tftemplate")}"
    vars {
        name = "${var.name}"
        environment = "${var.environment}"
        # Imports a raw file into a template var:
        rsyslog_b64 = "${base64encode(file("${path.module}/files/rsyslog.conf"))}"
        MAYBE_MORE_CLOUD_CONFIG_USERS = "${ (var.additional_users_yml == "") ? "" : var.additional_users_yml}"
        MAYBE_SOME_FQDN_CLOUD_CONFIG_YAML = "${ (var.fqdn == "") ? "

preserve_hostname: true

" : "

preserve_hostname: false
fqdn: ${var.fqdn}

"}"

    }
}


# Render a multi-part cloudinit config
#
# http://stackoverflow.com/questions/34095839/cloud-init-what-is-the-execution-order-of-cloud-config-directives
#
# Within the individual generated script directories, the scripts are
# run by cloud-init in the order given by the python "sorted()" builtin.
# Hence the 00, 01, 02 prefix on the script filenames.
data "template_cloudinit_config" "linux" {
    gzip          = true   # help prevent going over the 16KB limit
    base64_encode = true   # required by terraform-providers/terraform-provider-aws/issues/754

    part {
        content_type = "text/cloud-config"
        content      = "${data.template_file.cloud-config.rendered}"
    }
    part {
        content_type = "text/x-shellscript"
        content      = "${data.template_file.linux-common.rendered}"
        filename     = "00-setup-vars+hostname.sh"
    }
    part {
        content_type = "text/x-shellscript"
        content      = "${file("${path.module}/files/setup-dnsmasq.sh")}"
        filename     = "01-setup-dnsmasq.sh"
    }
    part {
        content_type = "text/x-shellscript"
        content      = "${data.template_file.install-consul.rendered}"
        filename     = "02-install-consul.sh"
    }

    # conditional part
    part {
        content_type = "text/x-shellscript"
        content      = "${var.additional_script[1]}"
        filename     = "${var.additional_script[0]}"
    }
}

data "template_cloudinit_config" "windows" {
    gzip          = true   # enable if we go over the 16KB limit
    base64_encode = true

    part {
        content_type = "text/x-powershell"
        content      = "${data.template_file.windows-common.rendered}"
    }
}

output "cloud-config-linux-user-data-size-bytes" {
    value = "${length(data.template_cloudinit_config.linux.rendered)}"
}
