
resource "openstack_networking_network_v2" "internal_network" {
  name           = "internal-net"
  admin_state_up = true
}

resource "openstack_networking_subnet_v2" "internal_subnet" {
  network_id     = openstack_networking_network_v2.internal_network.id
  cidr           = "192.168.100.0/24"
  ip_version     = 4
  name           = "internal-subnet"
  enable_dhcp    = true
  no_gateway     = true
}

resource "openstack_networking_network_v2" "external_network" {
  name           = "external-net"
  admin_state_up = true
}

resource "openstack_networking_subnet_v2" "external_subnet" {
  network_id     = openstack_networking_network_v2.external_network.id
  cidr           = "10.10.10.0/24"
  ip_version     = 4
  name           = "external-subnet"
  gateway_ip     = "10.10.10.1"
  enable_dhcp    = true
}

resource "openstack_networking_router_v2" "kolla_router" {
  name           = "kolla-router"
  admin_state_up = true
  external_gateway {
    network_id = var.external_network_id
  }
}

resource "openstack_networking_router_interface_v2" "external_router_interface" {
  router_id = openstack_networking_router_v2.kolla_router.id
  subnet_id = openstack_networking_subnet_v2.external_subnet.id
}

resource "openstack_networking_secgroup_v2" "kolla_secgroup" {
  name = "kolla-secgroup"
}

resource "openstack_networking_secgroup_rule_v2" "public_access_rules" {
  count = length(var.openstack_horizon_ports)
  security_group_id = openstack_networking_secgroup_v2.kolla_secgroup.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = element(var.openstack_horizon_ports, count.index)
  port_range_max    = element(var.openstack_horizon_ports, count.index)
  remote_ip_prefix  = "0.0.0.0/0"
}


resource "openstack_networking_secgroup_rule_v2" "public_openstack_api_rules" {
  count             = length(var.openstack_api_ports)
  security_group_id = openstack_networking_secgroup_v2.kolla_secgroup.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = element(var.openstack_api_ports, count.index)
  port_range_max    = element(var.openstack_api_ports, count.index)
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_v2" "internal_secgroup" {
  name = "internal-secgroup"
}

resource "openstack_networking_secgroup_rule_v2" "internal_access_rule" {
  security_group_id = openstack_networking_secgroup_v2.internal_secgroup.id
  direction         = "ingress"
  ethertype         = "-1"
  protocol          = "-1"
  remote_group_id   = openstack_networking_secgroup_v2.internal_secgroup.id
}

resource "openstack_networking_port_v2" "external_vip_port" {
  network_id      = openstack_networking_network_v2.external_network.id
  name            = "external_vip-port"
  security_groups = [
    openstack_networking_secgroup_v2.kolla_secgroup.id,
    openstack_networking_secgroup_v2.internal_secgroup.id
  ]
  admin_state_up  = true
}

resource "openstack_networking_port_v2" "internal_vip_port" {
  network_id      = openstack_networking_network_v2.internal_network.id
  name            = "internal-vip-port"
  security_groups = [
    openstack_networking_secgroup_v2.internal_secgroup.id
  ]
  admin_state_up  = true
}

resource "openstack_compute_floatingip_v2" "external_vip" {
  pool = var.external_network_id
}

resource "openstack_networking_floatingip_associate_v2" "external_vip_assoc" {
  floating_ip = openstack_compute_floatingip_v2.external_vip.address
  port_id = openstack_networking_port_v2.external_vip_port.id
}

resource "openstack_networking_port_v2" "controller_internal_port" {
  count      =  var.nodes.controller.count
  name       =  "internal_port_controller_${count.index + 1}"
  network_id =  openstack_networking_network_v2.internal_network.id
}

resource "openstack_networking_port_v2" "controller_external_port" {
  count      =  var.nodes.controller.count
  name       =  "external_port_controller_${count.index + 1}"
  network_id =  openstack_networking_network_v2.external_network.id
}

resource "openstack_networking_port_v2" "compute_internal_port" {
  count      =  var.nodes.compute.count
  name       =  "internal_port_compute_${count.index + 1}"
  network_id =  openstack_networking_network_v2.internal_network.id
}

resource "openstack_networking_port_v2" "compute_external_port" {
  count      =  var.nodes.compute.count
  name       =  "external_port_compute_${count.index + 1}"
  network_id =  openstack_networking_network_v2.external_network.id
}

resource "openstack_networking_port_v2" "internal_paired_port" {
  count      = var.nodes.controller.count
  name       = "internal_paired_port_${count.index + 1}"
  network_id = openstack_networking_network_v2.internal_network.id
  allowed_address_pairs {
    ip_address = openstack_networking_port_v2.internal_vip_port.fixed_ip_v4
  }
}

resource "openstack_networking_port_v2" "external_paired_port" {
  count      = var.nodes.controller.count
  name       = "external_paired_port_${count.index + 1}"
  network_id = openstack_networking_network_v2.external_network.id
  allowed_address_pairs {
    ip_address = openstack_networking_port_v2.external_vip_port.fixed_ip_v4
  }
}