# Example — Local PostgreSQL

Provision a local PostgreSQL database and pgAdmin UI using Terraform.
No cloud account needed — runs entirely in Docker on your machine.

This example shows two things most tutorials skip:
1. Managing Docker infrastructure with Terraform (containers, networks, volumes)
2. Managing the **contents** of a database with Terraform (databases, roles, schemas, grants)

---

## What it creates

| Resource | Description |
|---|---|
| Docker network | Isolated network so Postgres and pgAdmin can reach each other |
| Postgres container | PostgreSQL 16 with a persistent data volume |
| pgAdmin container | Web UI for browsing and querying the database |
| Persistent volume | Data survives container restarts and recreations |
| `appdb` database | Application database owned by `app_user` |
| `app_user` role | Login role that owns the app database |
| `readonly` role | Group role with SELECT-only access (for reporting tools) |
| `app` schema | Schema inside `appdb` for application tables |

---

## Prerequisites

- Docker Desktop running
- Terraform >= 1.9.0 (`tfenv use 1.9.0`)

---

## Quick start

```bash
cd examples/local-postgres

terraform init
terraform apply
```

Access pgAdmin at `http://localhost:5050`

```
Email:    admin@local.dev
Password: admin
```

To connect to Postgres from a client (psql, DBeaver, etc.):

```
Host:     localhost
Port:     5432
Database: appdb
Username: admin
Password: localpassword
```

---

## Connect with psql

```bash
psql -h localhost -p 5432 -U admin -d appdb
```

Verify the schema and roles were created:

```sql
\dn          -- list schemas
\du          -- list roles
\l           -- list databases
```

---

## Variables

| Name | Default | Description |
|---|---|---|
| `project_name` | `local-postgres` | Prefix for all Docker resource names |
| `postgres_version` | `16` | Postgres image tag |
| `postgres_port` | `5432` | Host port for Postgres |
| `postgres_user` | `admin` | Postgres superuser |
| `postgres_password` | `localpassword` | Postgres superuser password |
| `postgres_db` | `postgres` | Default database on first boot |
| `pgadmin_port` | `5050` | Host port for pgAdmin UI |
| `pgadmin_email` | `admin@local.dev` | pgAdmin login email |
| `pgadmin_password` | `admin` | pgAdmin login password |

Override any variable in `terraform.tfvars`:

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars
```

---

## Outputs

```bash
terraform output              # show all (non-sensitive)
terraform output -raw pgadmin_url
terraform output -raw postgres_connection_string   # sensitive — shows full connection string
```

| Output | Description |
|---|---|
| `postgres_host` | Postgres hostname |
| `postgres_port` | Postgres port |
| `postgres_database` | App database name |
| `postgres_user` | App database user |
| `pgadmin_url` | pgAdmin UI URL |
| `postgres_connection_string` | Full connection string (sensitive) |

---

## Running tests

Unit tests (no Docker required — runs in seconds):

```bash
terraform test -filter=tests/unit.tftest.hcl
```

Integration tests (Docker must be running — creates real containers):

```bash
terraform test -filter=tests/integration.tftest.hcl
```

All tests:

```bash
terraform test
```

---

## How it works

**Two providers, one infrastructure**

This example chains two providers:

1. `kreuzwerker/docker` — creates the containers, network, and volume
2. `cyrilgdn/postgresql` — connects to the running Postgres container and manages databases, roles, schemas, and grants

The `postgresql` provider connects to `localhost:5432` using the superuser credentials. Everything in `database.tf` is managed as infrastructure code — the same pattern used by platform teams to manage production databases.

**Why a persistent volume?**

By default, container data is lost when a container is removed. The `docker_volume` resource creates a named Docker volume that persists independently of the container. Your data survives `terraform destroy && terraform apply`.

**Why a `readonly` role?**

The `readonly` role is a group role (login = false). In production you assign it to individual users: `GRANT readonly TO reporting_user`. This is the standard Postgres pattern for controlling read access without duplicating grants.

---

## Teardown

```bash
terraform destroy
```

This removes the containers and network. The persistent volume is also destroyed, which deletes all data. To keep the data, remove the volume from state before destroying:

```bash
terraform state rm docker_volume.postgres_data
terraform destroy
```

---

## File structure

```
local-postgres/
├── main.tf                    — providers, Docker containers, network, volume
├── database.tf                — postgresql provider: databases, roles, schemas, grants
├── variables.tf               — all input variables
├── outputs.tf                 — connection strings, URLs
├── terraform.tfvars.example   — copy to terraform.tfvars and fill in
├── .terraform-version         — pins Terraform to 1.9.0
└── tests/
    ├── unit.tftest.hcl        — plan-only tests, no Docker needed
    └── integration.tftest.hcl — apply tests, Docker must be running
```
