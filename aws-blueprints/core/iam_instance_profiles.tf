resource "aws_iam_role" "default" {
    name  = "default-${var.environment}"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "default-ec2-policy" {
    role = "${aws_iam_role.default.name}"
    policy_arn = "${data.terraform_remote_state.iam.iam_policy_default_ec2_policy_arn}"
}


resource "aws_iam_instance_profile" "default" {
    name  = "default-${var.environment}"
    path  = "/"
    role = "${aws_iam_role.default.name}"
}

output "default_iam_role_arn" {
    value = "${aws_iam_role.default.arn}"
}
output "default_iam_instance_profile_arn" {
    value = "${aws_iam_instance_profile.default.arn}"
}
output "default_iam_instance_profile_name" {
    value = "${aws_iam_instance_profile.default.name}"
}
