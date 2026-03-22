# portainer-mcp-docker

Dockerized version of the [Portainer MCP Server](https://github.com/portainer/portainer-mcp) for easy deployment.

Instead of manually downloading and managing binaries, this project provides minimal Alpine-based Docker images that can be deployed alongside Portainer using Docker Compose.

## Features

- Minimal Alpine Linux image with the official `portainer-mcp` binary
- **Two variants:** stdio (local) and HTTP (remote/web)
- Multi-architecture support (linux/amd64, linux/arm64)
- Automatic updates via GitHub Actions when new upstream releases are published
- Base image updates via Dependabot with auto-merge (security patches, Alpine updates)
- Versioned tags matching the upstream release (e.g., `v0.7.0-1`)

## Image Variants

| Image Tag | Transport | Use Case |
|-----------|-----------|----------|
| `latest` / `v0.7.0-1` | stdio | Local MCP clients (Claude Desktop, Claude Code CLI) |
| `http` / `v0.7.0-1-http` | Streamable HTTP | Remote access (Claude Web, shared servers) |

### stdio (default)

The standard image. MCP clients launch the container and communicate over stdin/stdout. Best for local setups where the MCP client runs on the same machine.

### HTTP

Wraps the MCP server with [mcp-proxy](https://github.com/sparfenyuk/mcp-proxy) to expose it over Streamable HTTP. Supports bearer token authentication so the endpoint is not publicly accessible. Best for remote access, e.g., connecting from Claude Web to a Portainer instance on your server.

## Installation

### Prerequisites

- A running [Portainer](https://www.portainer.io/) instance
- A Portainer API access token (generated from the Portainer UI under *My Account > Access Tokens*)
- Docker and Docker Compose

---

## stdio Variant (Local)

### Quick Start

```bash
docker pull ghcr.io/serraniel/portainer-mcp-docker:latest

docker run -i --rm ghcr.io/serraniel/portainer-mcp-docker:latest \
  -server https://your-portainer:9443 \
  -token your-api-token
```

### MCP Client Configuration

#### Claude Desktop

Add to your `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "portainer": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "ghcr.io/serraniel/portainer-mcp-docker:latest",
        "-server", "https://your-portainer:9443",
        "-token", "your-api-token"
      ]
    }
  }
}
```

#### Claude Code

Add to your Claude Code MCP settings:

```json
{
  "mcpServers": {
    "portainer": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "ghcr.io/serraniel/portainer-mcp-docker:latest",
        "-server", "https://your-portainer:9443",
        "-token", "your-api-token"
      ]
    }
  }
}
```

---

## HTTP Variant (Remote)

### Generating Tokens

The HTTP variant requires two tokens:

1. **Portainer API token** (`PORTAINER_TOKEN`) — authenticates the MCP server against your Portainer instance. Generate one in the Portainer UI under *My Account > Access Tokens > Add access token*.

2. **MCP bearer token** (`API_ACCESS_TOKEN`) — protects the HTTP endpoint so only authorized MCP clients can connect. This is a secret you create yourself. Generate a secure random token:

```bash
openssl rand -hex 32
```

Use the output as your `MCP_API_TOKEN` in the `.env` file and configure the same value in your MCP client's `Authorization: Bearer <token>` header.

### Quick Start

```bash
docker pull ghcr.io/serraniel/portainer-mcp-docker:http

docker run -d --rm \
  -p 8080:8080 \
  -e PORTAINER_SERVER=https://your-portainer:9443 \
  -e PORTAINER_TOKEN=your-portainer-api-token \
  -e API_ACCESS_TOKEN=your-mcp-bearer-token \
  ghcr.io/serraniel/portainer-mcp-docker:http
```

### Docker Compose

```yaml
services:
  portainer:
    image: portainer/portainer-ce:latest
    restart: always
    ports:
      - "9443:9443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data

  portainer-mcp:
    image: ghcr.io/serraniel/portainer-mcp-docker:http
    restart: always
    ports:
      - "8080:8080"
    environment:
      - PORTAINER_SERVER=https://portainer:9443
      - PORTAINER_TOKEN=${PORTAINER_TOKEN}
      - API_ACCESS_TOKEN=${MCP_API_TOKEN}
      # Optional:
      # - PORTAINER_READ_ONLY=true
      # - PORTAINER_DISABLE_VERSION_CHECK=true
      # - MCP_PORT=8080
      # - MCP_HOST=0.0.0.0

volumes:
  portainer_data:
```

Create a `.env` file:

```env
PORTAINER_TOKEN=your-portainer-api-token
MCP_API_TOKEN=your-mcp-bearer-token
```

### MCP Client Configuration (Remote)

#### Claude Web / Claude Desktop (Remote URL)

Configure your MCP client to connect to the HTTP endpoint:

- **URL:** `http://your-server:8080/sse`
- **Authorization:** Bearer token (the `MCP_API_TOKEN` you configured)

#### Claude Code (Remote)

```json
{
  "mcpServers": {
    "portainer": {
      "type": "url",
      "url": "http://your-server:8080/sse",
      "headers": {
        "Authorization": "Bearer your-mcp-bearer-token"
      }
    }
  }
}
```

### Environment Variables (HTTP)

| Variable | Required | Description |
|----------|----------|-------------|
| `PORTAINER_SERVER` | Yes | Portainer server URL |
| `PORTAINER_TOKEN` | Yes | Portainer API access token |
| `API_ACCESS_TOKEN` | Recommended | Bearer token for MCP endpoint authentication |
| `PORTAINER_READ_ONLY` | No | Set to `true` for read-only mode |
| `PORTAINER_DISABLE_VERSION_CHECK` | No | Set to `true` to skip version validation |
| `MCP_PORT` | No | HTTP listen port (default: `8080`) |
| `MCP_HOST` | No | HTTP listen address (default: `0.0.0.0`) |

---

## Command Line Options (stdio)

All flags from the upstream binary are supported:

| Flag | Description |
|------|-------------|
| `-server <url>` | Portainer server URL (**required**) |
| `-token <token>` | Portainer API access token (**required**) |
| `-tools <path>` | Path to custom tools YAML file |
| `-read-only` | Restrict to read-only operations (GET requests only) |
| `-disable-version-check` | Skip Portainer server version validation |

## Versioning

Image tags follow the format `v<upstream>-<build>`:

- `v0.7.0-1` - First build of upstream v0.7.0 (stdio)
- `v0.7.0-1-http` - Same version, HTTP variant
- `v0.7.0-2` - Rebuild (e.g., base image security update)
- `latest` - Most recent stdio build
- `http` - Most recent HTTP build

## How Automatic Updates Work

| Trigger | What happens |
|---------|-------------|
| New upstream release | Daily check creates a new tag (e.g., `v0.8.0-1`) and builds both images |
| Dependabot PR merged | Auto-merged after build test, increments build number and rebuilds |
| Manual dispatch | Workflow can be triggered manually with a specific upstream version |

## Upstream Documentation

For full documentation on the Portainer MCP server capabilities, tools, and Portainer version compatibility, see the [upstream README](https://github.com/portainer/portainer-mcp#readme).

## License

This project is licensed under the [European Union Public License v1.2](LICENSE) (EUPL-1.2).

The upstream [portainer-mcp](https://github.com/portainer/portainer-mcp) binary is licensed under the [Zlib License](https://github.com/portainer/portainer-mcp/blob/main/LICENSE).
