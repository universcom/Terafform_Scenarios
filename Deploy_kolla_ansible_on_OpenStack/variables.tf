variable "nodes" {
  type = map(object({
    name            = string
    flavor          = string
    image           = string
    volume_size     = number
    count           = number
  }))
  default = {
    controller = {
      name            = "controller"
      flavor          = "m1.medium"
      image           = "Ubuntu 20.04"
      volume_size     = 20
      count           = 3
    }
    compute = {
      name            = "compute"
      flavor          = "m1.large"
      image           = "Ubuntu 20.04"
      volume_size     = 20
      count           = 2
    }
  }
}

variable "public_key" {
  type    = string
  default = "~/.ssh/id_rsa.pub"
}

variable "openstack_api_ports" {
  type    = list(number)
  default = [5000, 35357, 8774, 9292, 9696, 8776, 8777]
}


variable "openstack_horizon_ports" {
  type    = list(number)
  default = [80,443]
}

variable "external_network_id" {
  type    = string
}