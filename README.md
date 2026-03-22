# portainer-mcp-docker

Dockerized version of the [Portainer MCP Server](https://github.com/portainer/portainer-mcp) for easy deployment.

Instead of manually downloading and managing binaries, this project provides a minimal Alpine-based Docker image that can be deployed alongside Portainer using Docker Compose.

## Features

- Minimal Alpine Linux image with the official `portainer-mcp` binary
- Multi-architecture support (linux/amd64, linux/arm64)
- Automatic updates via GitHub Actions when new upstream releases are published
- Base image updates via Dependabot (security patches, Alpine updates)
- Versioned tags matching the upstream release (e.g., `v0.7.0-1`)

## Installation

### Prerequisites

- A running [Portainer](https://www.portainer.io/) instance
- A Portainer API access token (generated from the Portainer UI under *My Account > Access Tokens*)
- Docker and Docker Compose

### Quick Start

1. Pull the image:

```bash
docker pull ghcr.io/serraniel/portainer-mcp-docker:latest
```

2. Run directly:

```bash
docker run -i --rm ghcr.io/serraniel/portainer-mcp-docker:latest \
  -server https://your-portainer:9443 \
  -token your-api-token
```

### Docker Compose

Add the MCP server to your existing Portainer Compose file:

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
    image: ghcr.io/serraniel/portainer-mcp-docker:latest
    restart: "no"
    stdin_open: true
    command:
      - "-server"
      - "https://portainer:9443"
      - "-token"
      - "${PORTAINER_TOKEN}"

volumes:
  portainer_data:
```

Create a `.env` file alongside your `docker-compose.yml`:

```env
PORTAINER_TOKEN=your-api-token-here
```

### MCP Client Configuration

#### Claude Desktop

Add to your Claude Desktop MCP configuration (`claude_desktop_config.json`):

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

### Command Line Options

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

- `v0.7.0-1` - First build of upstream v0.7.0
- `v0.7.0-2` - Rebuild (e.g., base image security update)
- `latest` - Always points to the most recent build

## How Automatic Updates Work

| Trigger | What happens |
|---------|-------------|
| New upstream release | Daily check creates a new tag (e.g., `v0.8.0-1`) and builds the image |
| Dependabot PR merged | Increments the build number (e.g., `v0.7.0-1` → `v0.7.0-2`) and rebuilds |
| Manual dispatch | Workflow can be triggered manually with a specific upstream version |

## Upstream Documentation

For full documentation on the Portainer MCP server capabilities, tools, and Portainer version compatibility, see the [upstream README](https://github.com/portainer/portainer-mcp#readme).

## License

This project is licensed under the [European Union Public License v1.2](LICENSE) (EUPL-1.2).

The upstream [portainer-mcp](https://github.com/portainer/portainer-mcp) binary is licensed under the [Zlib License](https://github.com/portainer/portainer-mcp/blob/main/LICENSE).
