output "windows_public_ip" {
  value = aws_eip.windows_eip.public_ip
}

output "edge_public_ip" {
  value = aws_eip.edge_wan1_eip.public_ip
}