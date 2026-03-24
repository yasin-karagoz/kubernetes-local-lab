variable "project_name" {
  description = "Prefix used for all Docker resource names"
  type        = string
  default     = "local-postgres"
}

# --- Postgres ---
variable "postgres_version" {
  description = "Postgres Docker image tag"
  type        = string
  default     = "16"
}

variable "postgres_port" {
  description = "Host port for Postgres (mapped from container port 5432)"
  type        = number
  default     = 5432
}

variable "postgres_user" {
  description = "Postgres superuser username"
  type        = string
  default     = "admin"
}

variable "postgres_password" {
  description = "Postgres superuser password"
  type        = string
  sensitive   = true
  default     = "localpassword"
}

variable "postgres_db" {
  description = "Default database created on first boot"
  type        = string
  default     = "postgres"
}

# --- pgAdmin ---
variable "pgadmin_version" {
  description = "pgAdmin Docker image tag"
  type        = string
  default     = "latest"
}

variable "pgadmin_port" {
  description = "Host port for pgAdmin UI"
  type        = number
  default     = 5050
}

variable "pgadmin_email" {
  description = "pgAdmin login email"
  type        = string
  default     = "admin@local.dev"
}

variable "pgadmin_password" {
  description = "pgAdmin login password"
  type        = string
  sensitive   = true
  default     = "admin"
}
