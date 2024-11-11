#todo - vmtags variable, disk size, vlan, static ip config to meta_data, destroy, get IP (inventory)
# destroy maybe set absent state variable - run playbook - apply - done
# could add a re-provision option to delete and re-create
terraform {
  cloud { 
    
    organization = "Scale_Computing" 

    workspaces { 
      name = "hypercore" 
    } 
  } 

  required_providers {
    ansible = {
      version = "~> 1.3.0"
      source  = "ansible/ansible"
    }
  }
}

locals {
  user_data_base64 = base64encode(templatefile("${path.module}/cloud-config-full.yaml", {}))
}

variable "meta_data" {
  type = string
  description = "Cloud-init configuration for VM provisioning"
  default = <<-EOF
    dsmode: local
    local-hostname: "{{ vmname }}"
  EOF
}

locals {
  vm_count = 5 #scaling up works - down doesn't delete vms - todo - could pass this var into some playbook to do cleanup
  vmnames = [for i in range(1, local.vm_count + 1) : "tfansible-demo${i}"]
}

resource "ansible_playbook" "manage_hypercore_vm" {
  for_each = toset(local.vmnames)

  ansible_playbook_binary = "ansible-playbook"
  playbook                = "clonevm-playbook.yml"
  name                    = "localhost"
  verbosity               = 0
  replayable              = true #playbook is idempotent - can run every apply

  extra_vars = {
    vmname             = each.key  #map to var.vm_name in tgmain
    inventory_hostname = "szt15b-01.lab.local"
    scale_user         = "terraform"
    scale_pass         = "admin"
    user_data_base64   = local.user_data_base64
    meta_data          = var.meta_data
    cores              = var.cpu_count
    ramGB              = var.memory #- need to compare units
    image_url          = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
    image_path         = "/Users/davedemlow/tmp/"
    url2template_image_url  = "{{ image_url }}"
    url2template_machine_type = "vTPM+UEFI"
    url2template_operating_system = "os_other"
    url2template_vm_name    = "{{ vm_name | default(image_url | split('/') | last) }}"
    tags = "todo"
    vm_state          =  "present"  #set absent and terraform apply to delete vms
  }
}

# resource "ansible_host" "host" {
#   name   = "somehost"
#   groups = ["somegroup"]
#   variables = {
#     greetings   = "from host!"
#     some        = "variable"
#     yaml_hello  = local.decoded_vault_yaml.hello
#     yaml_number = local.decoded_vault_yaml.a_number

# #     # using jsonencode() here is needed to stringify 
# #     # a list that looks like: [ element_1, element_2, ..., element_N ]
# #     yaml_list = jsonencode(local.decoded_vault_yaml.a_list)
#    }
# }

# resource "ansible_group" "group" {
#   name     = "somegroup"
#   children = ["somechild"]
#   variables = {
#     hello = "from group!"
#   }
# }

