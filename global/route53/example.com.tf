resource "aws_route53_zone" "example_com" {
  name = "example.com"
}
output "zone_id" {
  value = "${aws_route53_zone.example_com.zone_id}"
}

//
// Delegation to prod.example.com in example.com:
//
resource "aws_route53_record" "prod-ns" {
  zone_id = "${aws_route53_zone.example_com.zone_id}"
  name = "prod.example.com"
  type = "NS"
  ttl = "3600"
  records = [
      "${aws_route53_zone.prod_example_com.name_servers.0}",
      "${aws_route53_zone.prod_example_com.name_servers.1}",
      "${aws_route53_zone.prod_example_com.name_servers.2}",
      "${aws_route53_zone.prod_example_com.name_servers.3}"
  ]
}

// PROD zone
resource "aws_route53_zone" "prod_example_com" {
  name = "prod.example.com"
}
output "prod_zone_id" {
  value = "${aws_route53_zone.prod_example_com.zone_id}"
}
