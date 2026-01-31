# Build

## Prerequisites

- Docker Engine with Compose v2
- Network access to pull base images and install dependencies

## Build the image

From the project root:

```bash
docker compose build
```

This builds the `agent` image from `Dockerfile`.

## Clean build (optional)

```bash
docker compose build --no-cache
```
