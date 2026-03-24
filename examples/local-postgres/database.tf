# This file manages the contents of Postgres using the postgresql provider.
# The provider connects to the running container and creates databases, roles, and schemas.
# All resources here depend implicitly on the container being up.

# --- Application database ---
resource "postgresql_database" "app" {
  name  = "appdb"
  owner = postgresql_role.app_user.name

  # Sensible defaults for a local app database
  encoding          = "UTF8"
  lc_collate        = "en_US.utf8"
  lc_ctype          = "en_US.utf8"
  connection_limit  = -1 # unlimited
  allow_connections = true

  depends_on = [postgresql_role.app_user]
}

# --- Roles ---

# Application role — owns the app database and its objects
resource "postgresql_role" "app_user" {
  name     = "app_user"
  login    = true
  password = var.postgres_password

  # Can create tables, views, sequences inside its own database
  # but cannot create new databases or roles
  create_database = false
  create_role     = false
  superuser       = false
}

# Read-only role — useful for reporting tools, read replicas, BI dashboards
resource "postgresql_role" "readonly" {
  name  = "readonly"
  login = false # used as a group role, assigned to individual users
}

# --- Schema ---
resource "postgresql_schema" "app" {
  name     = "app"
  database = postgresql_database.app.name
  owner    = postgresql_role.app_user.name

  depends_on = [postgresql_database.app]
}

# --- Grants ---

# Give app_user full access to the app schema
resource "postgresql_grant" "app_user_schema" {
  database    = postgresql_database.app.name
  role        = postgresql_role.app_user.name
  schema      = postgresql_schema.app.name
  object_type = "schema"
  privileges  = ["CREATE", "USAGE"]

  depends_on = [postgresql_schema.app]
}

# Give readonly role read access to all tables in the app schema
resource "postgresql_grant" "readonly_tables" {
  database    = postgresql_database.app.name
  role        = postgresql_role.readonly.name
  schema      = postgresql_schema.app.name
  object_type = "table"
  privileges  = ["SELECT"]

  depends_on = [postgresql_schema.app]
}
