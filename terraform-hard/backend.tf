terraform {

  backend "s3" {
    bucket         = "react-ec2-hard-london"
    key            = "terraform.tfstate"
    region         = "eu-west-2"
    use_lockfile = true      # ✅ new way
    encrypt      = true
  }
}