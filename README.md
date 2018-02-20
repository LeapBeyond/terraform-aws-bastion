# terraform-aws-bastion
Example of using a 'bastion' VPC with a 'private' VPC that has instances hidden behind a NAT gateway.
This is related to the simpler ["VPC with public and private subnet"](https://github.com/LeapBeyond/terraform-aws-vpc)
example.

This set of scripts is used to set up an example of this scenario, launching an EC2
instance in each of the subnets, and deploying SSH keys so that you can SSH to the
"public" host, and from there to the "private" host, but the private host itself does
not have a public IP. Both hosts are able to reach out to the internet for things like
patching and software installation, and the "private" hosts are behind a NAT router.

## Usage
Using these scripts assume you have [Terraform](https://terraform.io)
installed and are familiar with it, and that you are running on some sort of Unix.
It also assumes that you have an AWS account to target the scripts against, and
a suitably empowered user set up to create VPCs, networking stuff, and EC2 instances.

To begin with, create the `bootstrap/env.rc` file from the template,
then execute the `bootstrap/bootstrap.sh`. If all goes well, you should wind up with some PEM
files in the `data` directory, and some new key pairs in the AWS account. You should also
verify that the S3 bucket and DynamoDB table got created.

Next, from within the `platform-scripts` directory, create the `terraform.tfvars` from the template
and update the `backend.tf`. Finally do a `terraform init` (if you have not already) followed by `terraform apply`.

After a certain amount of grinding, you should see some output from the scripts, e.g.:

```
bastion_private_dns = ip-172-21-20-59.eu-west-2.compute.internal
bastion_public_dns = ec2-35-178-47-224.eu-west-2.compute.amazonaws.com
connect_string = ssh -i vpc_test_bastion.pem ec2-user@ec2-35-178-47-224.eu-west-2.compute.amazonaws.com
nat_ip = 35.177.79.24
protected_private_dns = ip-172-21-10-45.eu-west-2.compute.internal
```

The `gobastion.sh` script should allow you to ssh to the bastion host. From there, you should
be able to ssh to the protected host:

```
ec2-user@ip-172-21-20-59 ~]$ ssh -i .ssh/vpc_test_protected.pem ec2-user@ip-172-21-10-45.eu-west-2.compute.internal
ec2-user@ip-172-21-10-45 ~]$ dig +short myip.opendns.com @resolver1.opendns.com
35.177.79.24
```

The final step should return the address of the NAT gateway, demonstrating that the instance is hidden behind that gateway.

And there you have it! A host in a subnet which can reach the internet, but not be accessed from outside, and protected by a NAT gateway.


## Cleanup
To cleanup, execute `terraform destroy` from within the `platform-scripts` directory, and then from within the `bootstrap-scripts/terraform`
directory. You may also want to remove the `data/*.pem` files.
