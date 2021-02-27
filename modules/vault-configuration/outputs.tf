output "Instructions" {
  value = <<EOF
  Upon succesfully applying the defaults to vault, you should immediately create an admin token, and cease to use the root token from this point onward:
  vault token create -policy=admins

  If enabled, you can use your remote graphical bastion to configure non default values in the vault in the vault ui with the installed firefox browser at https://vault.service.consul:8200
  Alternatively, you can forward the vault web service to another client via ssh (Recommended) 
EOF
}