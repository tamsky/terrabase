# https://aws.amazon.com/blogs/aws/new-vpc-endpoint-for-amazon-s3/
resource "aws_vpc_endpoint" "private-s3" {
    vpc_id = "${module.vpc.vpc_id}"
    service_name = "com.amazonaws.${var.vpc_region}.s3"
    route_table_ids = [
        "${module.vpc.public_route_table_ids}",
        "${module.vpc.private_route_table_ids}",
    ]
    policy = <<POLICY
{
    "Statement": [
        {
            "Action": "*",
            "Effect": "Allow",
            "Resource": "*",
            "Principal": "*"
        }
    ],
    "Version": "2008-10-17"
}
POLICY

}
