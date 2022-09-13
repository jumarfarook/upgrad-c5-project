output "ipaddress" {
  description = "self ip address"
  value       = "${trimspace(data.http.self_ip_address.body)}/32"
}