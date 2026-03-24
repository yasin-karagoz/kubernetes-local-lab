output "postgres_connection_string" {
  description = "Connection string for the app_user (use in your application)"
  value       = "postgresql://${var.postgres_user}:${var.postgres_password}@localhost:${var.postgres_port}/${postgresql_database.app.name}?sslmode=disable"
  sensitive   = true
}

output "postgres_host" {
  description = "Postgres host"
  value       = "localhost"
}

output "postgres_port" {
  description = "Postgres host port"
  value       = var.postgres_port
}

output "postgres_database" {
  description = "Application database name"
  value       = postgresql_database.app.name
}

output "postgres_user" {
  description = "Application database user"
  value       = postgresql_role.app_user.name
}

output "pgadmin_url" {
  description = "pgAdmin UI — open in your browser"
  value       = "http://localhost:${var.pgadmin_port}"
}

output "pgadmin_credentials" {
  description = "pgAdmin login credentials"
  value       = "Email: ${var.pgadmin_email} / Password: ${var.pgadmin_password}"
  sensitive   = true
}
