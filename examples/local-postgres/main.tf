terraform {
  required_version = ">= 1.9.0"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1.22"
    }
  }

  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "docker" {}

# The postgresql provider connects to Postgres once the container is running.
# It uses the root credentials to manage databases and roles.
provider "postgresql" {
  host     = "localhost"
  port     = var.postgres_port
  username = var.postgres_user
  password = var.postgres_password
  sslmode  = "disable"

  # Wait for the container to be ready before making connections
  connect_timeout = 15
}

# --- Network ---
# Isolated Docker network so Postgres and pgAdmin can talk to each other
resource "docker_network" "postgres" {
  name = "${var.project_name}-network"
}

# --- Postgres image ---
resource "docker_image" "postgres" {
  name         = "postgres:${var.postgres_version}"
  keep_locally = true # don't remove image on destroy
}

# --- Postgres container ---
resource "docker_container" "postgres" {
  name  = "${var.project_name}-postgres"
  image = docker_image.postgres.image_id

  restart = "unless-stopped"

  env = [
    "POSTGRES_USER=${var.postgres_user}",
    "POSTGRES_PASSWORD=${var.postgres_password}",
    "POSTGRES_DB=${var.postgres_db}",
  ]

  ports {
    internal = 5432
    external = var.postgres_port
  }

  networks_advanced {
    name = docker_network.postgres.name
  }

  healthcheck {
    test         = ["CMD-SHELL", "pg_isready -U ${var.postgres_user}"]
    interval     = "5s"
    timeout      = "5s"
    retries      = 5
    start_period = "10s"
  }

  # Keep data when the container is recreated
  volumes {
    volume_name    = docker_volume.postgres_data.name
    container_path = "/var/lib/postgresql/data"
  }
}

# Persistent volume so data survives terraform destroy/apply cycles
resource "docker_volume" "postgres_data" {
  name = "${var.project_name}-postgres-data"
}

# --- pgAdmin image ---
resource "docker_image" "pgadmin" {
  name         = "dpage/pgadmin4:${var.pgadmin_version}"
  keep_locally = true
}

# --- pgAdmin container ---
resource "docker_container" "pgadmin" {
  name  = "${var.project_name}-pgadmin"
  image = docker_image.pgadmin.image_id

  restart = "unless-stopped"

  env = [
    "PGADMIN_DEFAULT_EMAIL=${var.pgadmin_email}",
    "PGADMIN_DEFAULT_PASSWORD=${var.pgadmin_password}",
    "PGADMIN_CONFIG_SERVER_MODE=False",       # single-user desktop mode
    "PGADMIN_CONFIG_MASTER_PASSWORD_REQUIRED=False",
  ]

  ports {
    internal = 80
    external = var.pgadmin_port
  }

  networks_advanced {
    name = docker_network.postgres.name
  }

  depends_on = [docker_container.postgres]
}
