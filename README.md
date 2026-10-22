# homelab

> homelab & media server setup

## Arr API helper

Query Sonarr, Radarr, or Prowlarr through their running Docker containers. The
helper reads the API key, port, and URL base inside the selected container and
prints the response to stdout. It works from any directory with Docker access.

```bash
scripts/arr-api.sh sonarr /qualityprofile | jq .
scripts/arr-api.sh radarr /movie | jq '.[].title'
scripts/arr-api.sh prowlarr /indexer | jq .
scripts/arr-api.sh sonarr /api/v3/system/status
```

API version prefixes are optional: Sonarr and Radarr default to `/api/v3`, while
Prowlarr defaults to `/api/v1`. Full URLs are also accepted; only their path and
query are used, and the request always targets the selected container.

Additional arguments are passed to curl, with JSON request headers set by
default. For example, to trigger an RSS sync:

```bash
scripts/arr-api.sh sonarr /command -X POST --data '{"name":"RssSync"}'
# Or send a JSON file through stdin:
cat command.json | scripts/arr-api.sh radarr /command -X POST --data-binary @-
```

HTTP and connection failures return a nonzero exit status. Run
`scripts/arr-api.sh --help` for usage.
