# use_powershell flag allows supporting both linux and windows from this module
#
# default value of use_powershell is false which == "0"
output "cloud-config-user-data-rendered" {
	value = "${
		lookup(
			map(
				"0", "${data.template_cloudinit_config.linux.rendered}",
				"1", "${data.template_cloudinit_config.windows.rendered}"
			), var.use_powershell, "UNKNOWN"
		)
	}"
}
