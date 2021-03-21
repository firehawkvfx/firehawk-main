inputs {
  vpcname     = "vaultvpc"
  projectname = "firehawk-main" # A tag to recognise resources created in this project
}

before_hook "before_hook_1" {
  commands = ["apply", "plan"]
  execute  = ["source", "./update_vars.sh"]
}
skip = true
