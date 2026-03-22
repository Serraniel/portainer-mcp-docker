# syntax=docker/dockerfile:1
FROM alpine:3.23 AS download

ARG PORTAINER_MCP_VERSION
ARG TARGETARCH

RUN apk add --no-cache curl tar \
    && curl -fsSL "https://github.com/portainer/portainer-mcp/releases/download/v${PORTAINER_MCP_VERSION}/portainer-mcp-v${PORTAINER_MCP_VERSION}-linux-${TARGETARCH}.tar.gz" \
       -o /tmp/portainer-mcp.tar.gz \
    && tar -xzf /tmp/portainer-mcp.tar.gz -C /tmp \
    && mv /tmp/portainer-mcp /usr/local/bin/portainer-mcp \
    && chmod +x /usr/local/bin/portainer-mcp

FROM alpine:3.23

RUN apk add --no-cache ca-certificates

COPY --from=download /usr/local/bin/portainer-mcp /usr/local/bin/portainer-mcp

RUN adduser -D -h /home/mcpuser mcpuser
USER mcpuser
WORKDIR /home/mcpuser

ENTRYPOINT ["portainer-mcp"]
