resource "aws_iam_server_certificate" "my-cert" {
  name = "my-cert-issued-on-19700101"
  certificate_body = "${file("keypairs/my_cert_issued_by_someca_on_19700101/my-cert.crt")}"
  certificate_chain = "${file("keypairs/my_cert_issued_by_someca_on_19700101/my-cert.crt-chain")}"
  private_key = "${file("keypairs/my_cert_issued_by_someca_on_19700101/my-cert.key")}"
}

output "my_cert_arn" {
  value = "${aws_iam_server_certificate.my-cert.arn}"
}
