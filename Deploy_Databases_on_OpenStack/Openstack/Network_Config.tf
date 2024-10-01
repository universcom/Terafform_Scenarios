## Config network steps:
## 1) create a router
## 2) create network and its subnet
## 3) attach network to router
## 4) config security group (open required ports and define required protocols)
## 5) create suite interfaces for attach to instances and associate security group
## 6) define required floating IPs

#####create Router#####
resource "openstack_networking_router_v2" "DBaaS_router" {
  name                = "routerDBaaS-${var.customer_project_name}"
  admin_state_up      = true
  external_network_id = "${var.external_network_id}"
}

#####Create network#####
resource "openstack_networking_network_v2" "DBaaS_network" {
  depends_on = [openstack_networking_router_v2.DBaaS_router]
  name              = "networkDBaaS-${var.customer_project_name}"
  admin_state_up    = "true"
}

#####Create subnet#####
resource "openstack_networking_subnet_v2" "DBaaS_subnet" {
  depends_on = [openstack_networking_network_v2.DBaaS_network]
  name       = "subnetDBaaS-${var.customer_project_name}"
  network_id = "${openstack_networking_network_v2.DBaaS_network.id}"
  cidr       = "${var.cidr_network}"
  allocation_pool{
    start = "${var.cidr-start_ip}"
    end   = "${var.cidr-end_ip}"
  }
  dns_nameservers = "${var.dns}"
  ip_version = 4
}

#####attach network to router#####
resource "openstack_networking_router_interface_v2" "DBaaS_router_interface_1" {
  depends_on = [openstack_networking_subnet_v2.DBaaS_subnet]
  router_id = "${openstack_networking_router_v2.DBaaS_router.id}"
  subnet_id = "${openstack_networking_subnet_v2.DBaaS_subnet.id}"
}

##### define security group #####
resource "openstack_compute_secgroup_v2" "DBaaS_secgroup_MYSQL" {
  depends_on = [openstack_networking_router_interface_v2.DBaaS_router_interface_1]
  name        = "DBaaS_secgroup_MYSQL_${var.customer_project_name}"
  description = "DBaaS security group for MYSQL database"
}

#####define firewall rules to open required ports#####
resource "openstack_networking_secgroup_rule_v2" "DBaaS_secgrouprule_MYSQL"{
  depends_on = [openstack_compute_secgroup_v2.DBaaS_secgroup_MYSQL]
  count = length(var.ingress_ports_mysql)
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = split("/",var.ingress_ports_mysql[count.index])[1]
  port_range_min    = split("/",var.ingress_ports_mysql[count.index])[0] == "1" ? "1" : split("/",var.ingress_ports_mysql[count.index])[0]
  port_range_max    = split("/",var.ingress_ports_mysql[count.index])[0] == "1" ? "65535" : split("/",var.ingress_ports_mysql[count.index])[0]
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_compute_secgroup_v2.DBaaS_secgroup_MYSQL.id}"
}

######define VIP interfaces ######
resource "openstack_networking_port_v2" "DBaaS_VIP_interface" {
  depends_on = [openstack_compute_secgroup_v2.DBaaS_secgroup_MYSQL]
  name = "DBaaS_port_VIP"
  network_id = openstack_networking_network_v2.DBaaS_network.id
  admin_state_up = true
  port_security_enabled = false
  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.DBaaS_subnet.id
  }
}


######define instance interfaces ######
resource "openstack_networking_port_v2" "DBaaS_interfaces" {
  depends_on = [openstack_compute_secgroup_v2.DBaaS_secgroup_MYSQL]
  for_each = toset(var.instance_list)
  name           = "DBaaS_port_${each.value}"
  network_id     = openstack_networking_network_v2.DBaaS_network.id
  admin_state_up = true
  security_group_ids = [
    openstack_compute_secgroup_v2.DBaaS_secgroup_MYSQL.id
  ]
  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.DBaaS_subnet.id
  }
  allowed_address_pairs {
    ip_address = tostring(openstack_networking_port_v2.DBaaS_VIP_interface.all_fixed_ips[0])
  }
}

#####define VIP floating IPs#####
resource "openstack_networking_floatingip_v2" "DBaaS_VIP_floatingIP"{
  depends_on = [openstack_networking_router_interface_v2.DBaaS_router_interface_1]
  pool = "${var.external_network_name}"
}

#####define required floating IPs#####
resource "openstack_networking_floatingip_v2" "DBaaS_floatingIP" {
  depends_on = [openstack_networking_router_interface_v2.DBaaS_router_interface_1]
  for_each = toset(var.instance_list)
  tags = [each.value]
  pool = "${var.external_network_name}"
}

output "VIP_address" {
  value = openstack_networking_port_v2.DBaaS_VIP_interface.all_fixed_ips[0]
}