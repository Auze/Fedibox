# Monitoring stack

### Variables

- .env

| Container            | Type | Name            |
|----------------------|------|-----------------|
| Grafana              | ENV  | GF_UID          |
| alertmanager-discord | ENV  | DISCORD_WEBHOOK |

### ports

| Name                 | Port |
|----------------------|------|
| prometheus           | 9090 |
| alertmanager         | 9093 |
| node-exporter        | 9100 |
| alertmanager-discord | 9094 |


# Launch

```
cp sample.env .env
docker compose up -d
```
