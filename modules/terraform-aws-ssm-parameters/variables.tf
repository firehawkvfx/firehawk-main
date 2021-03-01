variable "environment" {
  description = "The environment.  eg: dev/prod"
  type        = string
}
variable "resourcetier" {
  description = "The resource tier uniquely defining the deployment area.  eg: dev/green/blue/main"
  type        = string
}
variable "pipelineid" {
  description = "The pipelineid uniquely defining the deployment instance if using CI.  eg: dev/green/blue/main"
  type        = string
}
variable "onsite_public_ip" {
  description = "The public IP of your onsite connection used to connect to the cloud infra. Google 'what is my ip' for the value.  \nIf you do not have a static IP, terraform may need to update more frequently."
  type        = string
}
variable "onsite_private_subnet_cidr" {
  description = "The private subnet IP range used for your onsite hosts.  Your router will usually use DHCP to place hosts within this range. eg: 192.168.29.0/24"
  type        = string
}
variable "global_bucket_extension" {
  description = "The suffix used for all S3 cloud storage buckets created by the deployment and for encrypted terraform state.  \nThis must be a globally unique name, like a domain name you own, or derived from an email addess with no special characters. \neg: example.com \n eg2: myemailatgmaildotcom"
  type        = string
}
