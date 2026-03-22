#!/bin/sh
set -e

if [ -z "$PORTAINER_SERVER" ] || [ -z "$PORTAINER_TOKEN" ]; then
  echo "Error: PORTAINER_SERVER and PORTAINER_TOKEN environment variables are required." >&2
  exit 1
fi

# Build portainer-mcp command
MCP_CMD="portainer-mcp -server ${PORTAINER_SERVER} -token ${PORTAINER_TOKEN}"

if [ "${PORTAINER_READ_ONLY}" = "true" ]; then
  MCP_CMD="${MCP_CMD} -read-only"
fi

if [ "${PORTAINER_DISABLE_VERSION_CHECK}" = "true" ]; then
  MCP_CMD="${MCP_CMD} -disable-version-check"
fi

# Run mcp-proxy in stdio-to-SSE mode
# API_ACCESS_TOKEN is read by mcp-proxy from the environment for bearer auth
exec mcp-proxy \
  --host "${MCP_HOST:-0.0.0.0}" \
  --port "${MCP_PORT:-8080}" \
  ${MCP_CMD}
