variable "auth_url" {
    type = string
    default = ""
}
variable "project_admin_domain" {
    type = string
    default = "admin"
}
variable "user_domain_name" {
    type = string
    default = "Default"
}
variable "region" {
    type = string
    default = "RegionOne"
}
variable "tenant_name" {
    type = string
    default = ""
}
variable "tenant_id" {
    type = string
    default = ""

}
variable "user_name" {
    type = string
    default = "admin"
}
variable "password" {
    type = string
    default = ""
}


terraform {
required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.35.0"
    }
  }
}

# Configure the OpenStack Provider
provider "openstack" {
  user_name   = "${var.user_name}"
  tenant_name = "${var.tenant_name}"
  password    = "${var.password}"
  auth_url    = "${var.auth_url}"
  region      = "${var.region}"
}

output "terraform-provider" {
    value = "Connected with openstack at ${var.auth_url}"
  
}