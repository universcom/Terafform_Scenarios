resource "openstack_compute_keypair_v2" "public_keypair" {
  name       = "my_public_key"
  public_key = file(var.public_key)
}

resource "openstack_compute_instance_v2" "controller" {
  count        = var.nodes.controller.count
  name         = "${var.nodes.controller.name}-${count.index + 1}"
  flavor_name  = var.nodes.controller.flavor
  boot_volume {
    source_type           = "image"
    image_id              = var.nodes.controller.image
    volume_size           = var.nodes.controller.volume_size
    delete_on_termination = true
  }
  key_pair     = openstack_compute_keypair_v2.public_keypair.name
  security_groups = [openstack_networking_secgroup_v2.internal_secgroup.name]
  network {
    port = openstack_networking_port_v2.controller_internal_port[count.index].id
  }
  network {
    port = openstack_networking_port_v2.controller_external_port[count.index].id
  }
  metadata = {
    role = var.nodes.controller.name
  }
}

resource "openstack_compute_instance_v2" "compute" {
  count        = var.nodes.compute.count
  name         = "${var.nodes.compute.name}-${count.index + 1}"
  flavor_name  = var.nodes.compute.flavor
  boot_volume {
    source_type           = "image"
    image_id              = var.nodes.compute.image
    volume_size           = var.nodes.compute.volume_size
    delete_on_termination = true
  }
  key_pair     = openstack_compute_keypair_v2.public_keypair.name
  security_groups = [openstack_networking_secgroup_v2.internal_secgroup.name]
  network {
    port = openstack_networking_port_v2.compute_internal_port[count.index].id
  }
  network {
    port = openstack_networking_port_v2.compute_external_port[count.index].id
  }
  metadata = {
    role = var.nodes.compute.name
  }
}