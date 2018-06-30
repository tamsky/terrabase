resource "aws_route53_zone" "apex_zone" {
  name = "aws.example.com"
}
output "apex_zone_id" {
  value = "${aws_route53_zone.apex_zone.zone_id}"
}
output "apex_zone_name" {
  value = "${aws_route53_zone.apex_zone.name}"
}

//
// Delegation to prod in apex:
//
resource "aws_route53_record" "aws-prod-ns" {
  zone_id = "${aws_route53_zone.apex_zone.zone_id}"
  name = "prod.${aws_route53_zone.apex_zone.name}"
  type = "NS"
  ttl = "300"
  records = [
      "${aws_route53_zone.aws-prod.name_servers.0}",
      "${aws_route53_zone.aws-prod.name_servers.1}",
      "${aws_route53_zone.aws-prod.name_servers.2}",
      "${aws_route53_zone.aws-prod.name_servers.3}"
  ]
}

// PROD zone
resource "aws_route53_zone" "aws-prod" {
  name = "prod.${aws_route53_zone.apex_zone.name}"
}
output "prod_zone_id" {
  value = "${aws_route53_zone.aws-prod.zone_id}"
}
output "prod_zone_name" {
  value = "${aws_route53_zone.aws-prod.name}"
}


##  //
##  // Delegation to dev in apex:
##  //
##  resource "aws_route53_record" "dev-ns" {
##    zone_id = "${aws_route53_zone.apex_zone.zone_id}"
##    name = "dev.${aws_route53_zone.apex_zone.name}"
##    type = "NS"
##    ttl = "300"
##    records = [
##        "${aws_route53_zone.aws-dev.name_servers.0}",
##        "${aws_route53_zone.aws-dev.name_servers.1}",
##        "${aws_route53_zone.aws-dev.name_servers.2}",
##        "${aws_route53_zone.aws-dev.name_servers.3}"
##    ]
##  }
##  
##  // DEV zone
##  resource "aws_route53_zone" "aws-dev" {
##    name = "dev.${aws_route53_zone.apex_zone.name}"
##  }
##  output "dev_zone_id" {
##    value = "${aws_route53_zone.aws-dev.zone_id}"
##  }
##  output "dev_zone_name" {
##    value = "${aws_route53_zone.aws-dev.name}"
##  }
