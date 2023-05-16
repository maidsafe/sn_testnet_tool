variable "droplet_ssh_keys" {
  type    = list(number)
  default = [
    37243057, # Benno Zeeman
    38313409, # Roland Sherwin
    36971688, # David Irvine
    19315097, # Stephen Coyle
    29201567, # Josh Wilson
    29586082, # Gabriel Viganotti
    30643816, # Anselme Grumbach
    30113222, # Qi Ma
    30878672, # Chris O'Neil
    31216015, # QA
    34183228, # GH Actions Automation
  ]
}

variable "droplet_size" {
  default = "s-2vcpu-2gb"
}

variable "droplet_image" {
  default = "ubuntu-22-04-x64"
}

variable "region" {
  default = "lon1"
}

variable "node_count" {
  default = 30
  description = "The number of droplets to launch for the nodes"
}
