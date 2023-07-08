# Monitoring stack

## Fediblox Monitoring stack

### Variables
|----------------------|------|-----------------|
| Container            | Type | Name            |
| alertmanager-discord | ENV  | DISCORD_WEBHOOK |
|----------------------|------|-----------------|

### ports
|----------------------|------|
| Name                 | Port |
| prometheus           | 9090 |
| alertmanager         | 9093 |
| node-exporter        | 9100 |
| alertmanager-discord | 9094 |
|----------------------|------|

# Launch
`docker compose up -d`

