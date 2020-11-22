variable "bucket_extension" {
  description = "The extension for cloud storage used to label your S3 storage buckets (eg: example.com, my-name-at-gmail.com). This can be any unique name (it must not be taken already, globally).  commonly, it is a domain name you own, or an abbreviated email adress.  No @ symbols are allowed. See this doc for naming restrictions on s3 buckets - https://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html"
  type = string
}

variable "envtier" {
  description = "The environment tier eg: dev, prod"
  type = string
  default = "dev"
}

variable "resourcetier" {
  description = "The resource tier is an group of resources in dev or prod by colour. eg: green, blue, grey"
  type = string
  default = "grey"
}

variable "restore_defaults" {
  description = "If true, will reset all values to system defaults"
  type        = bool
  default     = false
}

variable "init" {
  description = "If true, will only ensure paths exist."
  type        = bool
  default     = false
}