output "wordpress_url" {
  description = "WordPress website URL"
  value       = "http://${aws_instance.wordpress.public_ip}"
}
