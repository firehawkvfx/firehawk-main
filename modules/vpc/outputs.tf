output "bastion_public_ip" {
  value = module.vpc.bastion_public_ip
}

output "bastion_graphical_public_ip" {
  value = module.vpc.bastion_graphical_public_ip
}