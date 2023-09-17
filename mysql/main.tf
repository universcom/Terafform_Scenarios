#add module for provision Infrastructure
module "lunch_instances" {
  source = "../Infra_provisioner"
#  auth_url = var.auth_url
#  tenant_id = var.tenant_id
#  tenant_name = var.tenant_name
#  password = var.password
#  customer_project_name = var.customer_project_name
#  external_network_id = var.external_network_id
#  external_network_name = var.external_network_name
#  image = var.image
#  flavor = var.flavor
}
#variable "auth_url" {}
#variable "tenant_name" {}
#variable "tenant_id" {}
#variable "user_name" {}
#variable "password" {}
#variable "customer_project_name" {}
#variable "external_network_id" {}
#variable "external_network_name" {}
#variable "image" {}
#variable "flavor" {}