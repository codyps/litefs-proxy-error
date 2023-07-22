#! /usr/bin/env bash

: ${PROJECT_NAME:=litefs-proxy-error}

cd "$(dirname "$0")"
set -euf -o pipefail

$(nix build --no-link --print-out-paths '.#oci') | gzip --fast | skopeo \
	--insecure-policy \
	--debug copy \
	docker-archive:/dev/stdin \
	"docker://registry.fly.io/$PROJECT_NAME:latest" \
	--dest-creds x:"$(flyctl auth token)" \
	--format v2s2

flyctl deploy --ha=false -i "registry.fly.io/$PROJECT_NAME:latest" --remote-only
