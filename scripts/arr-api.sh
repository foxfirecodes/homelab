#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: arr-api.sh <sonarr|radarr|prowlarr> <endpoint-or-url> [curl options...]

Endpoints may omit /api/v3 (Sonarr/Radarr) or /api/v1 (Prowlarr).
Full URLs use only their path and query; requests target the selected container.
The API key, port, and URL base are read from /config/config.xml inside it.
Responses go to stdout; Docker, connection, and HTTP errors return nonzero.

Examples:
  scripts/arr-api.sh sonarr /qualityprofile | jq .
  scripts/arr-api.sh radarr /api/v3/movie | jq '.[].title'
  scripts/arr-api.sh prowlarr '/indexer?enabled=true'
  scripts/arr-api.sh sonarr http://localhost:8989/api/v3/system/status
  scripts/arr-api.sh sonarr /command -X POST --data '{"name":"RssSync"}'
  cat command.json | scripts/arr-api.sh radarr /command -X POST --data-binary @-
EOF
}

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
  '') usage >&2; exit 2 ;;
esac
service=$1
shift

case "$service" in
  sonarr) api_version=v3; default_port=8989 ;;
  radarr) api_version=v3; default_port=7878 ;;
  prowlarr) api_version=v1; default_port=9696 ;;
  *) printf 'Unsupported service: %s\n' "$service" >&2; exit 2 ;;
esac

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
  '') usage >&2; exit 2 ;;
esac
endpoint=$1
shift

if [[ "$endpoint" =~ ^https?://[^/?#]+(/[^#]*)?$ ]]; then
  endpoint=${BASH_REMATCH[1]:-/}
elif [[ "$endpoint" == *://* || "$endpoint" == //* ]]; then
  printf 'Expected an API path or an HTTP(S) URL with a path.\n' >&2
  exit 2
fi

# Keep credentials inside the container and stdin available for curl's @- input.
exec docker exec -i "$service" sh -c '
  set -eu
  api_version=$1
  default_port=$2
  endpoint=$3
  shift 3

  config=/config/config.xml
  if [ ! -r "$config" ]; then
    printf "Cannot read %s inside the container.\n" "$config" >&2
    exit 1
  fi
  config_value() {
    sed -n "s:.*<$1>\([^<]*\)</$1>.*:\1:p" "$config"
  }
  api_key=$(config_value ApiKey)
  port=$(config_value Port)
  url_base=$(config_value UrlBase)
  if [ -z "$api_key" ]; then
    printf "No API key found in %s.\n" "$config" >&2
    exit 1
  fi

  url_base=/${url_base#/}
  url_base=${url_base%/}
  endpoint=/${endpoint#/}
  if [ -n "$url_base" ]; then
    case "$endpoint" in
      "$url_base"/*) endpoint=${endpoint#"$url_base"} ;;
    esac
  fi
  case "$endpoint" in
    /api/*) ;;
    *) endpoint=/api/$api_version$endpoint ;;
  esac

  exec curl --silent --show-error --fail-with-body --globoff \
    --connect-timeout 10 --max-time 60 \
    --header "X-Api-Key: $api_key" \
    --header "Accept: application/json" \
    --header "Content-Type: application/json" \
    "$@" --url "http://127.0.0.1:${port:-$default_port}$url_base$endpoint"
' arr-api "$api_version" "$default_port" "$endpoint" "$@"
