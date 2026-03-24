# Unit tests — command = plan, no Docker required
# Run with: terraform test -filter=tests/unit.tftest.hcl

mock_provider "docker" {}

mock_provider "postgresql" {}

# --- Container configuration ---

run "postgres_port_mapping" {
  command = plan

  assert {
    condition     = docker_container.postgres.ports[0].internal == 5432
    error_message = "Postgres internal port must be 5432"
  }
}

run "postgres_port_matches_variable" {
  command = plan

  variables {
    postgres_port = 5433
  }

  assert {
    condition     = docker_container.postgres.ports[0].external == 5433
    error_message = "Postgres external port should match variable"
  }
}

run "pgadmin_port_matches_variable" {
  command = plan

  variables {
    pgadmin_port = 8080
  }

  assert {
    condition     = docker_container.pgadmin.ports[0].external == 8080
    error_message = "pgAdmin external port should match variable"
  }
}

run "containers_share_network" {
  command = plan

  assert {
    condition     = contains([for n in docker_container.postgres.networks_advanced : n.name], docker_network.postgres.name)
    error_message = "Postgres must be on the project network"
  }
}

run "pgadmin_on_same_network" {
  command = plan

  assert {
    condition     = contains([for n in docker_container.pgadmin.networks_advanced : n.name], docker_network.postgres.name)
    error_message = "pgAdmin must be on the same network as Postgres"
  }
}

run "postgres_has_healthcheck" {
  command = plan

  assert {
    condition     = length(docker_container.postgres.healthcheck) > 0
    error_message = "Postgres container must have a healthcheck"
  }
}

run "postgres_data_volume_mounted" {
  command = plan

  assert {
    condition     = contains([for v in docker_container.postgres.volumes : v.container_path], "/var/lib/postgresql/data")
    error_message = "Postgres data volume must be mounted at /var/lib/postgresql/data"
  }
}

run "project_name_prefix_applied" {
  command = plan

  variables {
    project_name = "myproject"
  }

  assert {
    condition     = docker_container.postgres.name == "myproject-postgres"
    error_message = "Postgres container name should use project_name prefix"
  }
}

# --- Database configuration ---

run "app_role_is_not_superuser" {
  command = plan

  assert {
    condition     = postgresql_role.app_user.superuser == false
    error_message = "app_user must not be a superuser"
  }
}

run "app_role_can_login" {
  command = plan

  assert {
    condition     = postgresql_role.app_user.login == true
    error_message = "app_user must be able to login"
  }
}

run "readonly_role_cannot_login" {
  command = plan

  assert {
    condition     = postgresql_role.readonly.login == false
    error_message = "readonly role should not login directly — it is a group role"
  }
}

run "app_database_has_correct_encoding" {
  command = plan

  assert {
    condition     = postgresql_database.app.encoding == "UTF8"
    error_message = "App database encoding must be UTF8"
  }
}
