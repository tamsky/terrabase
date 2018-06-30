##
## IAM ROLE
##
resource "aws_iam_role" "iam_role" {
    name  = "${var.name}-${var.environment}"
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

##
## IAM INSTANCE PROFILE
##
resource "aws_iam_instance_profile" "instance_profile" {
    name  = "${var.name}-${var.environment}"
    path  = "/"
    roles = ["${var.name}-${var.environment}"]
}