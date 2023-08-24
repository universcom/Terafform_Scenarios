#Customer project name
variable "customer_project_name" {
  type    = string
  default = ""
}

# UUID of external netowrk
variable "external_network_id" {
  type    = string
  default = ""
}

# Name of external netowrk
variable "external_network_name" {
  type    = string
  default = ""
}

#CIDR 
variable "cidr_network" {
  type    = string
  default = "192.168.10.0/24"
}

#Start ip for CIDR allocation pool
variable "cidr-start_ip" {
  type    = string
  default = "192.168.10.10"
}

#End ip for CIDR allocation pool
variable "cidr-end_ip" {
  type    = string
  default = "192.168.10.100"
}

#DNS for network 
variable "dns" {
  type    = list(string) #presented as a list
  default = ["8.8.8.8", "4.2.2.4"]
}

#keypair name 
variable "keypair_name" {
  type    = string
  default = ""
}

#keypair value
variable "keypair_value" {
  type    = string
  default = ""
}

#DBaaS image
variable "image" {
  type    = string
  default = "Ubuntu20.04"
}

#flavor for DBaaS instance
variable "flavor" {
  type    = string
  default = "C16_M4_D50"
}

#OS Volume Size (for CINDER_VOLUME_OS instances)
variable "volmes_size_os_root" {
  type = string
  default = "35"
  
}

#Opene ports for mysql Database
variable "ingress_ports_mysql" {
  type = list(string)
  default = [
  "22/tcp" , "3306/tcp" , "6032/tcp" , "6033/tcp" , "4444/tcp" ,
  "4567/tcp" , "4567/udp" , "4568/tcp", "1/icmp"
  ]
}

#Instance list
variable "instance_list" {
  type = list
  default = [
    "node1" ,
    "node2" ,
    "node3"
  ]
}

#output
output "instance_list" {
  value = var.instance_list
}