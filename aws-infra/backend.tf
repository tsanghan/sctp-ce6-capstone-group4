terraform {
  backend "s3" {
    bucket = "sctp-ce6-tfstate"
    key    = "tsanghan-ce6-capstone-case-2.tfstate"
    region = "ap-southeast-1"
  }
}
