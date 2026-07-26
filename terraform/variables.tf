variable "yourname" {
  description = "Your name, lowercase, no spaces. Makes resource names unique."
  type        = string
}
 
variable "location" {
  description = "Azure region to deploy into."
  type        = string
  default     = "East US"
}
 
variable "vm_count" {
  description = "How many Linux VMs to build. Two gives you a real fleet."
  type        = number
  default     = 2
}
 
variable "vm_size" {
  description = "Azure VM size. B1s is the cheapest burstable size."
  type        = string
  default     = "Standard_B1s"
}
 
variable "admin_username" {
  description = "The admin login created on each VM. Ansible connects as this user."
  type        = string
  default     = "azureadmin"
}
 
variable "ssh_public_key_path" {
  description = "Path to the PUBLIC key Terraform installs on the VMs."
  type        = string
  default     = "~/.ssh/ansible_lab.pub"
}
 
variable "ssh_private_key_path" {
  description = "Path to the PRIVATE key Ansible uses to connect."
  type        = string
  default     = "~/.ssh/ansible_lab"
}
 
variable "tags" {
  type = map(string)
  default = {
    project     = "ansible-hardening"
    environment = "dev"
    managed_by  = "terraform"
  }
}

