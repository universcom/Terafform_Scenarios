## lunch instance steps:
## 1)Define keypair
## 2)Get Image ID
## 3)Lunch instances
## 4)associate floating IP to instances

#####define keypair#####
resource "openstack_compute_keypair_v2" "DBaaS_admin_user_key" {
  name       = "${var.keypair_name}"
  public_key = "${var.keypair_value}"
}

##### Get image ID #####
data "openstack_images_image_v2" "DBaaS_Image_id" {
  name        = "${var.image}"
  most_recent = true
}

##### Lunch instances #####
resource "openstack_compute_instance_v2" "DBaaS_instance" {
  depends_on = [openstack_networking_floatingip_v2.DBaaS_floatingIP]
  for_each = toset(var.instance_list)
  name        = "${var.customer_project_name}-${each.value}"
  image_name  = "${var.image}"
  flavor_name = "${var.flavor}"
  key_pair    = openstack_compute_keypair_v2.DBaaS_admin_user_key.name
  network {
    port = openstack_networking_port_v2.DBaaS_interfaces[each.value].id
  }
  block_device {
    volume_size           = "${var.volmes_size_os_root}"
    destination_type      = "volume"
    delete_on_termination = true
    source_type           = "image"
    #uuid                  = "f95c41b9-8342-4a58-a9c8-479e1da25326"
    uuid                  = data.openstack_images_image_v2.DBaaS_Image_id.id
  }
}

#####associate floating ip to instances#####
resource "openstack_compute_floatingip_associate_v2" "DBaaS_floatingip-associte" {
  for_each = toset(var.instance_list)
  floating_ip = openstack_networking_floatingip_v2.DBaaS_floatingIP[each.value].address
  instance_id = openstack_compute_instance_v2.DBaaS_instance[each.value].id
}

#####associate floating ip to VIP#####
resource "openstack_networking_floatingip_associate_v2" "DBaaS_VIP_floatingip-associte" {
  floating_ip = openstack_networking_floatingip_v2.DBaaS_VIP_floatingIP.address
  port_id = openstack_networking_port_v2.DBaaS_VIP_interface.id
}
#####output required variable######
output "Instances_floating_IP" {
  depends_on = [openstack_compute_floatingip_associate_v2.DBaaS_floatingip-associte]
  value = openstack_compute_floatingip_associate_v2.DBaaS_floatingip-associte
}

output "instances" {
  depends_on = [openstack_compute_floatingip_associate_v2.DBaaS_floatingip-associte]
  value = openstack_compute_instance_v2.DBaaS_instance
}