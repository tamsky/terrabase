#
# MAP OUTPUTS
#

output "environment_zone_id_map" {
    value = {
#        dev       = "${aws_route53_zone.aws-dev.zone_id}"
        prod      = "${aws_route53_zone.aws-prod.zone_id}"
#        ops       = "${aws_route53_zone.aws-ops.zone_id}"
        apex      = "${aws_route53_zone.apex_zone.zone_id}"
    }
}
output "environment_zone_name_map" {
    value = {
#        dev       = "${aws_route53_zone.aws-dev.name}"
        prod       = "${aws_route53_zone.aws-prod.name}"
#        ops       = "${aws_route53_zone.aws-ops.name}"
        apex      = "${aws_route53_zone.apex_zone.name}"
    }
}
