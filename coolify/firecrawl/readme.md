# Firecrawl — Coolify Self-Hosted Deployment

This repository contains a self-hosted [Firecrawl](https://github.com/firecrawl/firecrawl) deployment configured to run on [Coolify](https://coolify.io/) using Docker Compose.

The deployment includes:

* Firecrawl API
* Playwright browser service
* Redis
* RabbitMQ
* NUQ PostgreSQL
* Optional FoundationDB support
* Persistent PostgreSQL storage
* Coolify-managed HTTPS/reverse proxy

## Architecture

```text
                         Internet
                            │
                            ▼
                 ┌─────────────────────┐
                 │   Coolify Proxy     │
                 │      HTTPS          │
                 └──────────┬──────────┘
                            │
                            │ :3002
                            ▼
                 ┌─────────────────────┐
                 │   Firecrawl API    │
                 │       api          │
                 │      :3002          │
                 └──────┬──────┬──────┘
                        │      │
              ┌─────────┘      └────────────┐
              ▼                             ▼
       ┌─────────────┐               ┌─────────────┐
       │    Redis    │               │  RabbitMQ   │
       │    :6379    │               │    :5672    │
       └─────────────┘               └─────────────┘
              │
              │
       ┌──────┴──────────┐
       ▼                 ▼
┌───────────────┐ ┌──────────────────┐
│ Playwright    │ │ NUQ PostgreSQL   │
│ :3000         │ │      :5432       │
└───────────────┘ └──────────────────┘
                         │
                         ▼
                  Persistent Volume
```

## Requirements

You need:

* A server managed by Coolify
* A Git repository containing this Compose file
* A domain pointing to your Coolify server
* Sufficient CPU/RAM for Firecrawl and Playwright

The API is configured to use:

* 4 CPU
* 8 GB RAM

The Playwright service is configured to use:

* 2 CPU
* 4 GB RAM

Actual requirements depend heavily on crawl concurrency and browser workload.

## Deployment in Coolify

Create a new **Docker Compose** resource in Coolify.

Configure:

1. Git repository
2. Branch
3. Compose file
4. Domain for the `api` service

The Compose file does not expose host ports. Coolify's proxy should route the public domain to the `api` service on port `3002`.

### API service

Configure the public domain against:

```text
api:3002
```

For example:

```text
https://firecrawl.example.com
```

The external API base URL is therefore:

```text
https://firecrawl.example.com
```

Do not expose Redis, RabbitMQ, PostgreSQL, Playwright, or FoundationDB publicly.

## API Endpoints

The API uses Firecrawl's REST API.

Examples:

```text
POST /v2/scrape
POST /v2/search
POST /v2/crawl
GET  /v2/crawl/:id
POST /v2/map
POST /v2/agent
```

For example:

```bash
curl -X POST "https://firecrawl.example.com/v2/scrape" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://example.com"
  }'
```

The current Firecrawl API uses `/v2` endpoints.

## Authentication

This deployment does not require a Firecrawl Cloud API key simply to run the self-hosted server.

Authentication depends on how the self-hosted instance is configured.

If an authenticated setup is enabled, clients use:

```text
Authorization: Bearer <API_KEY>
```

For example:

```bash
curl -X POST "https://firecrawl.example.com/v2/scrape" \
  -H "Authorization: Bearer fc-YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://example.com"
  }'
```

Firecrawl's current API documentation uses the `Authorization: Bearer` header for API authentication.

### Important

`BULL_AUTH_KEY` is **not the normal public Firecrawl API key**. It is an internal/authentication-related configuration value used by the Firecrawl application.

Do not give clients the value of:

```text
BULL_AUTH_KEY
```

unless Firecrawl specifically requires it for the internal operation you are configuring.

## Coolify Environment Variables

The following defaults are already defined in the Compose file:

```text
NUQ_BACKEND=pg
ALLOW_LOCAL_WEBHOOKS=false
BLOCK_MEDIA=false
```

You therefore do not need to create these variables in Coolify unless you want to override them.

### PostgreSQL

Set a strong password:

```text
POSTGRES_USER=postgres
POSTGRES_PASSWORD=<strong-random-password>
POSTGRES_DB=postgres
```

The PostgreSQL database is persisted using:

```text
nuq-postgres-data
```

mounted at:

```text
/var/lib/postgresql/data
```

Do not remove this volume unless you intentionally want to destroy the NUQ database.

### Firecrawl Configuration

Recommended defaults:

```text
NUM_WORKERS_PER_QUEUE=8
CRAWL_CONCURRENT_REQUESTS=10
MAX_CONCURRENT_JOBS=5
BROWSER_POOL_SIZE=5
LOGGING_LEVEL=INFO
NUQ_BACKEND=pg
```

### Optional AI configuration

If using OpenAI:

```text
OPENAI_API_KEY=
OPENAI_BASE_URL=
MODEL_NAME=
MODEL_EMBEDDING_NAME=
```

If using Ollama:

```text
OLLAMA_BASE_URL=
```

### Optional Supabase configuration

Supabase is only required for features that use Firecrawl's database authentication/advanced functionality.

```text
SUPABASE_ANON_TOKEN=
SUPABASE_URL=
SUPABASE_SERVICE_TOKEN=
```

### Optional proxy

```text
PROXY_SERVER=
PROXY_USERNAME=
PROXY_PASSWORD=
```

### Optional SearXNG

```text
SEARXNG_ENDPOINT=
SEARXNG_ENGINES=
SEARXNG_CATEGORIES=
```

### Optional webhook

```text
SELF_HOSTED_WEBHOOK_URL=
```

## Internal Service URLs

Do not use the public domain for communication between containers.

Use Docker service names:

| Service    | Internal address                        |
| ---------- | --------------------------------------- |
| API        | `http://api:3002`                       |
| Redis      | `redis://redis:6379`                    |
| RabbitMQ   | `amqp://rabbitmq:5672`                  |
| PostgreSQL | `nuq-postgres:5432`                     |
| Playwright | `http://playwright-service:3000/scrape` |

For example:

```text
REDIS_URL=redis://redis:6379
```

and:

```text
PLAYWRIGHT_MICROSERVICE_URL=http://playwright-service:3000/scrape
```

These should not be changed to `localhost`.

## Persistent Storage

The deployment uses three volumes:

### PostgreSQL

```text
nuq-postgres-data
```

Stores the Firecrawl NUQ PostgreSQL database.

### FoundationDB data

```text
fdb-data
```

Used only when FoundationDB is enabled.

### FoundationDB cluster configuration

```text
fdb-cluster-file
```

Used by Firecrawl when FoundationDB is enabled.

## FoundationDB

FoundationDB is optional.

The default configuration is PostgreSQL:

```text
NUQ_BACKEND=pg
```

Do not change this unless you specifically need FoundationDB.

To enable FoundationDB:

```text
NUQ_BACKEND=fdb
```

The Compose deployment already includes:

```text
foundationdb
foundationdb-init
```

The initialization container is intentionally a one-shot container and exits after configuring the database.

## Playwright

Playwright runs internally on:

```text
playwright-service:3000
```

Firecrawl communicates with it through:

```text
http://playwright-service:3000/scrape
```

It is not intended to be exposed publicly.

The container has:

```text
CPU: 2
RAM: 4 GB
```

and:

```text
MAX_CONCURRENT_PAGES=10
```

by default.

If the server has more resources, increasing browser concurrency may improve throughput.

## Redis

Redis is used internally by Firecrawl.

Address:

```text
redis:6379
```

It is not exposed publicly and does not require persistent storage for the basic deployment.

## RabbitMQ

RabbitMQ is used by the Firecrawl job/queue infrastructure.

Address:

```text
amqp://rabbitmq:5672
```

The API waits for RabbitMQ's health check before starting its dependent queue functionality.

RabbitMQ is not exposed publicly.

## PostgreSQL

The NUQ PostgreSQL service is:

```text
nuq-postgres
```

Port:

```text
5432
```

Database defaults:

```text
POSTGRES_USER=postgres
POSTGRES_DB=postgres
```

The password should be changed from the development default.

The database is persisted through the `nuq-postgres-data` volume.

## Updating Firecrawl

The API uses a versioned production image:

```text
ghcr.io/firecrawl/firecrawl:2.11.203-production
```

Playwright and NUQ PostgreSQL use their published images.

Before upgrading Firecrawl:

1. Review the Firecrawl release.
2. Check for Compose/environment-variable changes.
3. Back up the PostgreSQL volume.
4. Update the image tag.
5. Redeploy in Coolify.
6. Check the API logs.
7. Test `/v2/scrape`.

Avoid blindly upgrading production images without checking compatibility between Firecrawl's API and supporting services.

## Health / Troubleshooting

### ZodError: invalid NUQ_BACKEND

Make sure:

```text
NUQ_BACKEND=pg
```

or:

```text
NUQ_BACKEND=fdb
```

Do not use:

```text
NUQ_BACKEND=postgres
```

or leave it as an empty environment variable.

### ZodError: invalid ALLOW_LOCAL_WEBHOOKS

Use:

```text
ALLOW_LOCAL_WEBHOOKS=false
```

or:

```text
ALLOW_LOCAL_WEBHOOKS=true
```

The Compose file defaults this to:

```text
false
```

### API container repeatedly restarting

Check:

* `nuq-postgres` logs
* `rabbitmq` health
* `redis` logs
* API logs
* PostgreSQL credentials
* `NUQ_BACKEND`

### Playwright failures

Check:

* available RAM
* CPU usage
* `MAX_CONCURRENT_PAGES`
* `CRAWL_CONCURRENT_REQUESTS`
* proxy configuration

Browser-heavy workloads can consume significant memory.

### API works internally but not through the domain

Verify that the Coolify domain is assigned to:

```text
api
```

on port:

```text
3002
```

Do not add a host `ports:` mapping just to make the domain work.

## Testing the Deployment

After deployment, test the API from a machine outside the server:

```bash
curl -i "https://firecrawl.example.com/v2/scrape" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://example.com"
  }'
```

A successful response indicates that:

1. Coolify's proxy is working.
2. The API container is reachable.
3. Firecrawl is processing requests.
4. The internal services are communicating correctly.

## Connecting Applications

For applications that support a custom Firecrawl endpoint, configure:

```text
FIRECRAWL_API_URL=https://firecrawl.example.com
```

If the client requires an API key, configure the appropriate Firecrawl authentication credentials separately.

For the official Firecrawl MCP server, self-hosted deployments use `FIRECRAWL_API_URL` to point the MCP server at the custom instance. The API key is optional for a self-hosted instance when authentication is not enabled.

Example:

```text
FIRECRAWL_API_URL=https://firecrawl.example.com
```

## Security

Do not expose these services directly to the Internet:

* Redis
* RabbitMQ
* PostgreSQL
* Playwright
* FoundationDB

Only expose the Firecrawl API through Coolify's HTTPS proxy.

Use strong random values for:

```text
POSTGRES_PASSWORD
BULL_AUTH_KEY
```

Never commit secrets, API keys, database passwords, or proxy credentials to Git.

## Quick Reference

```text
Public API:
https://firecrawl.example.com

API container:
http://api:3002

Redis:
redis://redis:6379

RabbitMQ:
amqp://rabbitmq:5672

PostgreSQL:
nuq-postgres:5432

Playwright:
http://playwright-service:3000/scrape

NUQ backend:
pg

Local webhooks:
disabled

Media blocking:
disabled
```

## Useful Resources

* [Firecrawl GitHub](https://github.com/firecrawl/firecrawl)
* [Firecrawl API documentation](https://docs.firecrawl.dev/)
* [Coolify documentation](https://coolify.io/docs/)
* [Firecrawl MCP Server](https://github.com/firecrawl/firecrawl-mcp-server)

## License

Firecrawl is open source under the license specified by the upstream Firecrawl repository.

This deployment configuration is intended for self-hosted use and should be kept aligned with the upstream project's licensing and deployment requirements.
