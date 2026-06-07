output "web_server_public_ip" {
  description = "Public IP address of the web server"
  value       = aws_instance.web_server.public_ip
}

output "web_server_public_dns" {
  description = "Public DNS of the web server"
  value       = aws_instance.web_server.public_dns
}

output "db_server_private_ip" {
  description = "Private IP address of the database server"
  value       = aws_instance.db_server.private_ip
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "ssh_key_file" {
  description = "Path to the SSH private key file"
  value       = local_file.private_key.filename
}

output "ssh_command_web" {
  description = "SSH command to connect to web server"
  value       = "ssh -i ${local_file.private_key.filename} ubuntu@${aws_instance.web_server.public_ip}"
}

output "ssh_command_db" {
  description = "SSH command to connect to DB server (via web server as jump host)"
  value       = "ssh -i ${local_file.private_key.filename} -J ubuntu@${aws_instance.web_server.public_ip} ubuntu@${aws_instance.db_server.private_ip}"
}
