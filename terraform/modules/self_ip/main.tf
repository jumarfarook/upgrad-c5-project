# --------------------------------------------------------
# Self ip address using http
# --------------------------------------------------------

data "http" "self_ip_address" {
  url = "https://api.ipify.org/"
}

locals {
  self_ip_address = "${trimspace(data.http.self_ip_address.body)}/32"
}