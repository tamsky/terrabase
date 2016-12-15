# iam_policy.tftemplate

## Purpose

IAM policy template to be rendered to assemble fragments into a IAM policy.
## Vars

* iam\_policy\_statements - A list of policy fragments joined by commas (since it's all parts of a JSON list)

## Example Usage

This renders two policy fragments into one output:

```
resource "template_file" "myservice-artifacts-s3-policy" {
    template = "${file("iam/policies/iam_policy.tftemplate")}"

    vars {
        iam_policy_statements="${template_file.myservice-artifacts-s3-policy-full-access-fragment.rendered},${template_file.myservice-artifacts-s3-policy-getobject-fragment.rendered}"
    }
}
```

# ec2_assume_role.json

## Purpose

IAM role policy to apply to iam\_roles that allows instances to set
their role.  Example: Grafana has direct support for this for viewing
CloudWatch metrics.

More info at http://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRole.html


## Usage

We need to output a resource aws\_iam\_role "assume\_role" in global,
after which we can use it wherever.  Still TBD if this is useful. 

```
resource "aws_iam_role_policy" "foo" {
    name = "foo-${var.environment}"
    role = "${${terraform_remote_state.global.output.aws_iam_role.assume_role_id}"
    policy = "${file(\"${path.module}/foo_iam_role_policy.json\")}"
}

resource "aws_iam_instance_profile" "foo" {
    name = "Foo-${var.environment}"
    roles = ["${aws_iam_role.foo.name}"]
}

resource "aws_instance" "foo" {
    [etc...]
    iam_instance_profile = "${aws_iam_instance_profile.foo.id}"
}
```
