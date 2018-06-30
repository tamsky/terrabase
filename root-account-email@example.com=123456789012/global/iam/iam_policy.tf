##
## BEGIN Managed Policies
##

output "iam_policy_default_ec2_policy_arn" {
    value = "${aws_iam_policy.default_ec2_policy.arn}"
}
resource "aws_iam_policy" "default_ec2_policy" {
    name        = "default-ec2-policy"
    path        = "/"
    description = "Managed by Terraform. default-ec2-policy"
    policy      = "${file("policies/ec2/ec2_default_policy.json")}"
}

# output "iam_policy_packer" {
#     value = "${aws_iam_policy.packer.arn}"
# }
# resource "aws_iam_policy" "packer" {
#     name        = "packer"
#     path        = "/"
#     description = "Managed by Terraform. Allows packer to get its groove on."
#     policy      = "${file("policies/ec2/packer.json")}"
# }


output "iam_policy_iam-allow-user-mfa-selfservice" {
    value = "${aws_iam_policy.iam-allow-user-mfa-selfservice.arn}"
}
data "template_file" "iam-allow-user-mfa-selfservice" {
    template = "${file("policies/iam/mfa_self_service.tftemplate")}"
    vars {
        account_id = "${data.aws_caller_identity.current.account_id}"
    }
}
resource "aws_iam_policy" "iam-allow-user-mfa-selfservice" {
    name        = "iam-allow-user-mfa-selfservice"
    path        = "/"
    description = "Managed by Terraform. Allows policy holder to configure and manage his or her own virtual MFA device from the AWS Management Console or using any of the command-line tools. The policy allows only MFA-authenticated users to deactivate and delete their own virtual MFA devices."
    policy      = "${data.template_file.iam-allow-user-mfa-selfservice.rendered}"
}


# From
#   http://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_users-self-manage-mfa-and-creds.html
#
# o Allows the user to see basic information about the account and
#   its users in the IAM console.
# o Allows individual IAM users to view and manage their own keys
# o Allows the user to manage his or her own user, password, access
#   keys, signing certificates, SSH public keys, and MFA information
#   in the IAM console.
# o Allows the user to see information about MFA devices, and which
#   are associated with his or her IAM user entity.
# o Allows the user to provision or manage his or her own MFA device.
# o Allows the user to deactivate only his or her own MFA device and
#   only if the user signed in using MFA.
resource "aws_iam_policy" "iam-allow-iam-services-for-own-iam-user-account" {
    name        = "allow-iam-services-for-own-iam-user-account"
    path        = "/"
    description = "This policy allows users to manage their own passwords and MFA devices."
    policy      = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowAllUsersToListAccounts",
            "Effect": "Allow",
            "Action": [
                "iam:ListAccountAliases",
                "iam:ListUsers",
                "iam:GetAccountPasswordPolicy",
                "iam:GetAccountSummary"
            ],
            "Resource": "*"
        },
        {
            "Sid": "AllowIndividualUserToSeeAndManageOnlyTheirOwnAccountInformation",
            "Effect": "Allow",
            "Action": [
                "iam:ChangePassword",
                "iam:CreateAccessKey",
                "iam:CreateLoginProfile",
                "iam:DeleteAccessKey",
                "iam:DeleteLoginProfile",
                "iam:GetAccessKeyLastUsed",
                "iam:GetLoginProfile",
                "iam:ListAccessKeys",
                "iam:UpdateAccessKey",
                "iam:UpdateLoginProfile",
                "iam:ListSigningCertificates",
                "iam:DeleteSigningCertificate",
                "iam:UpdateSigningCertificate",
                "iam:UploadSigningCertificate",
                "iam:ListSSHPublicKeys",
                "iam:GetSSHPublicKey",
                "iam:DeleteSSHPublicKey",
                "iam:UpdateSSHPublicKey",
                "iam:UploadSSHPublicKey"
            ],
            "Resource": "arn:aws:iam::*:user/$${aws:username}"
        },
        {
            "Sid": "AllowIndividualUserToListOnlyTheirOwnMFA",
            "Effect": "Allow",
            "Action": [
                "iam:ListVirtualMFADevices",
                "iam:ListMFADevices"
            ],
            "Resource": [
                "arn:aws:iam::*:mfa/*",
                "arn:aws:iam::*:user/$${aws:username}"
            ]
        },
        {
            "Sid": "AllowIndividualUserToManageTheirOwnMFA",
            "Effect": "Allow",
            "Action": [
                "iam:CreateVirtualMFADevice",
                "iam:DeleteVirtualMFADevice",
                "iam:EnableMFADevice",
                "iam:ResyncMFADevice"
            ],
            "Resource": [
                "arn:aws:iam::*:mfa/$${aws:username}",
                "arn:aws:iam::*:user/$${aws:username}"
            ]
        },
        {
            "Sid": "AllowIndividualUserToDeactivateOnlyTheirOwnMFAOnlyWhenUsingMFA",
            "Effect": "Allow",
            "Action": [
                "iam:DeactivateMFADevice"
            ],
            "Resource": [
                "arn:aws:iam::*:mfa/$${aws:username}",
                "arn:aws:iam::*:user/$${aws:username}"
            ],
            "Condition": {
                "Bool": {
                    "aws:MultiFactorAuthPresent": "true"
                }
            }
        }
     ]
}
POLICY
}
