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
    },
    "system/deployuser_uid" = {
      "name" = "deployuser_uid",
      "description": "The UID of the deployuser for all hosts.  Ansible uses this user connect to provision with.",
      "default": "9004",
      "example_1": "9004",
    }
  } )
}