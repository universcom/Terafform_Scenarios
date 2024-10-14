provider "openstack" {
  auth_url    = var.auth_url
  tenant_name = var.tenant_name
  user_name   = var.user_name
  password    = var.password
  region      = var.region
}


resource "openstack_compute_instance_v2" "controller" {
  count        = var.nodes.controller.count
  name         = "${var.nodes.controller.name}-${count.index + 1}"
  flavor_name  = var.nodes.controller.flavor
  image_name   = var.nodes.controller.image
  key_pair     = var.nodes.controller.key_pair
  security_groups = var.nodes.controller.security_groups
  network {
    name = var.nodes.controller.networks[0]
  }
  metadata = {
    role = var.nodes.controller.name
  }
}

resource "openstack_compute_instance_v2" "compute" {
  count        = var.nodes.compute.count
  name         = "${var.nodes.compute.name}-${count.index + 1}"
  flavor_name  = var.nodes.compute.flavor
  image_name   = var.nodes.compute.image
  key_pair     = var.nodes.compute.key_pair
  security_groups = var.nodes.compute.security_groups
  network {
    name = var.nodes.compute.networks[0]
  }
  metadata = {
    role = var.nodes.compute.name
  }
}

resource "openstack_compute_instance_v2" "deploy" {
  count        = var.nodes.deploy.count
  name         = "${var.nodes.deploy.name}-${count.index + 1}"
  flavor_name  = var.nodes.deploy.flavor
  image_name   = var.nodes.deploy.image
  key_pair     = var.nodes.deploy.key_pair
  security_groups = var.nodes.deploy.security_groups
  network {
    name = var.nodes.deploy.networks[0]
  }
  metadata = {
    role = var.nodes.deploy.name
  }
}

output "controller_ips" {
  value = [for instance in openstack_compute_instance_v2.controller : {
    name = instance.name
    ip   = instance.access_ip_v4
  }]
}

output "compute_ips" {
  value = [for instance in openstack_compute_instance_v2.compute : {
    name = instance.name
    ip   = instance.access_ip_v4
  }]
}

output "deploy_ip" {
  value = [for instance in openstack_compute_instance_v2.deploy : {
    name = instance.name
    ip   = instance.access_ip_v4
  }]
}