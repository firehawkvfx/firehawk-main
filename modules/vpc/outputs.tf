output "bastion_public_ip" {
  value = module.vpc.bastion_public_ip
}

output "bastion_graphical_public_ip" {
  value = module.vpc.bastion_graphical_public_ip
}

output "this_key_pair_key_name" {
  description = "The key pair name."
  value       = concat(aws_key_pair.this.*.key_name, [""])[0]
}