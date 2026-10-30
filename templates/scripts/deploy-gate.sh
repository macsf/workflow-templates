#!/usr/bin/env bash
# Decides whether a push to main should deploy. Prints `skip_deploy=true|false`
# on stdout (append it to $GITHUB_OUTPUT) and the reason on stderr.
#
# Inputs (env): EVENT_NAME, BEFORE_SHA, HEAD_SHA
#
# Deploy when any commit in the push (BEFORE_SHA..HEAD_SHA) has a subject
# starting with "release:", "fix:" or "fix(scope):", unless any commit in the
# push contains "[skip deploy]". Scanning the whole push, not only the head,
# keeps a --no-ff merge commit from hiding the release commit under it.
# Manual runs always deploy.
set -euo pipefail

EVENT_NAME="${EVENT_NAME:?EVENT_NAME is required}"
HEAD_SHA="${HEAD_SHA:?HEAD_SHA is required}"
BEFORE_SHA="${BEFORE_SHA:-}"

if [ "$EVENT_NAME" = "workflow_dispatch" ]; then
  echo "Manual run: deploying" >&2
  echo "skip_deploy=false"
  exit 0
fi

# A new branch or force-push has no usable "before"; fall back to the head commit.
if [ -n "$BEFORE_SHA" ] \
  && [ "$BEFORE_SHA" != "0000000000000000000000000000000000000000" ] \
  && git cat-file -e "${BEFORE_SHA}^{commit}" 2>/dev/null; then
  range=("${BEFORE_SHA}..${HEAD_SHA}")
else
  range=(-1 "$HEAD_SHA")
fi

subjects="$(git log --format=%s "${range[@]}")"
messages="$(git log --format=%B "${range[@]}")"

if grep -qiF '[skip deploy]' <<<"$messages"; then
  echo "Skipping deploy: a commit in this push contains [skip deploy]" >&2
  echo "skip_deploy=true"
elif matches="$(grep -E '^(release:|fix(\([^)]*\))?:)' <<<"$subjects")"; then
  echo "Deploying: found \"${matches%%$'\n'*}\" in this push" >&2
  echo "skip_deploy=false"
else
  echo "Skipping deploy: no commit subject starts with release:, fix:, or fix(...):" >&2
  echo "skip_deploy=true"
fi
