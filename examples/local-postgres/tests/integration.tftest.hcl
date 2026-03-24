# Integration tests — command = apply, Docker must be running
# Run with: terraform test -filter=tests/integration.tftest.hcl
#
# WARNING: This creates real Docker containers. They are destroyed after the test run.

run "postgres_container_is_running" {
  command = apply

  assert {
    condition     = docker_container.postgres.exit_code == null
    error_message = "Postgres container should be running"
  }
}

run "pgadmin_container_is_running" {
  command = apply

  assert {
    condition     = docker_container.pgadmin.exit_code == null
    error_message = "pgAdmin container should be running"
  }
}

run "postgres_url_is_correct" {
  command = apply

  assert {
    condition     = output.postgres_port == 5432
    error_message = "Postgres should be accessible on the default port"
  }
}

run "pgadmin_url_is_correct" {
  command = apply

  assert {
    condition     = output.pgadmin_url == "http://localhost:5050"
    error_message = "pgAdmin URL should use the default port"
  }
}
