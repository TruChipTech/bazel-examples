#!/usr/bin/env bash
# Paths arrive as arguments via $(rootpath ...) - never hard-coded.
# The public key now lives in an EXTERNAL repository, whose runfiles path is
# the canonical repo name (e.g. "+signing_keys+signing_keys/rsa_public.pem").
# Writing that by hand would break the moment the repo is renamed.
set -uo pipefail
exec "$1" "$2" "$3" "$4" "$5"
