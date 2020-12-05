# Defines the default values to initialise vault vars with.

locals {
  defaults = tomap( {
    "deadline/deadline_version" = {
      "name" = "deadline_version",
      "description" = "The version of the deadline installer.",
      "default" = "10.1.9.2",
      "example_1" = "10.1.9.2",
    },
    "ansible/selected_ansible_version" = {
      "name" = "selected_ansible_version"
      "description" = "The version to use for ansible.  Can be 'latest', or a specific version.  due to a bug with pip and ansible we can have pip permissions and authentication issues when not using latest. This is because pip installs the version instead of apt-get when using a specific version instead of latest.  Resolution by using virtualenv will be required to resolve.",
      "default" = "latest",
      "example_1" = "latest",
      "example_2" = "2.9.2"
    },
    "system/syscontrol_gid" = {
      "name" = "syscontrol_gid",
      "description": "The group id (GID) for the syscontrol group",
      "default": "9003",
      "example_1": "9003",
    }
  } )
  dev = merge(local.defaults, tomap( {
    "aws/bucket_extension" = {
      "name" = "bucket_extension",
      "description": "The extension for cloud storage used to label your S3 storage buckets.  MUST BE UNIQUE TO THIS RESOURCE TIER (DEV, GREEN, BLUE). This can be any unique name (it must not be taken already, globally).  commonly, it is a domain name you own, or an abbreviated email adress.  No @ symbols are allowed. See this doc for naming restrictions on s3 buckets - https://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html",
      "default": "dev.${var.global_bucket_extension}",
      "example_1": "dev.example.com",
      "example_2": "green.example.com",
      "example_3": "dev-myemail-gmail-com"
    }
  } ) )
  green = merge(local.defaults, tomap( {
    "aws/bucket_extension" = {
      "name" = "bucket_extension",
      "description": "The extension for cloud storage used to label your S3 storage buckets.  MUST BE UNIQUE TO THIS RESOURCE TIER (DEV, GREEN, BLUE). This can be any unique name (it must not be taken already, globally).  commonly, it is a domain name you own, or an abbreviated email adress.  No @ symbols are allowed. See this doc for naming restrictions on s3 buckets - https://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html",
      "default": "green.${var.global_bucket_extension}",
      "example_1": "dev.example.com",
      "example_2": "green.example.com",
      "example_3": "dev-myemail-gmail-com"
    }
  } ) )
  blue = merge(local.defaults, tomap( {
    "aws/bucket_extension" = {
      "name" = "bucket_extension",
      "description": "The extension for cloud storage used to label your S3 storage buckets.  MUST BE UNIQUE TO THIS RESOURCE TIER (DEV, GREEN, BLUE). This can be any unique name (it must not be taken already, globally).  commonly, it is a domain name you own, or an abbreviated email adress.  No @ symbols are allowed. See this doc for naming restrictions on s3 buckets - https://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html",
      "default": "blue.${var.global_bucket_extension}",
      "example_1": "dev.example.com",
      "example_2": "green.example.com",
      "example_3": "dev-myemail-gmail-com"
    }
  } ) )
  main = tomap( {
    "aws/installers_bucket" = {
      "name" = "installers_bucket",
      "description" = "The S3 bucket name in the main account to store installers and software for all your AWS accounts.  The name must be globally unique.",
      "default" = "software.main.${var.global_bucket_extension}",
      "example_1" = "software.main.example.com",
      "example_3": "software-main-myemail-gmail-com"
    } 
  } )
}