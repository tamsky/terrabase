# Required provider alias: aws.route53

resource "aws_route53_record" "localhost" {
  zone_id = "${lookup(data.terraform_remote_state.route53.environment_zone_id_map, var.environment, "MISSING")}"
  name = "localhost.${lookup(data.terraform_remote_state.route53.environment_zone_name_map, var.environment, "MISSING")}"
  type = "A"
  ttl = "3600"
  records = ["127.0.0.1"]
  provider = "aws.route53"
}

resource "aws_route53_record" "localhost6" {
  zone_id = "${lookup(data.terraform_remote_state.route53.environment_zone_id_map, var.environment, "MISSING")}"
  name = "localhost6.${lookup(data.terraform_remote_state.route53.environment_zone_name_map, var.environment, "MISSING")}"
  type = "AAAA"
  ttl = "3600"
  records = ["::1"]
  provider = "aws.route53"
}
