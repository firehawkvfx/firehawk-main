inputs {
    vpcname="vaultvpc"
    projectname="firehawk-main" # A tag to recognise resources created in this project
}
execute {
    ["source", "./update_vars.sh"]
}
skip = true