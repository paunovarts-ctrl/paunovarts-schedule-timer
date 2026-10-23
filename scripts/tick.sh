#!/usr/bin/env bash
# One tick of the cloud publisher: send the queue and the last results to /api/tick, commit what it answers.
# Used by tick.yml (one tick) and tick-loop.yml (a tick every few minutes for hours). Needs TICK_KEY in the env.
set -u
git pull -q --rebase --autostash origin main || true
[ -f data/results.json ] || echo '{"posts":{},"log":[]}' > data/results.json
jq -n --slurpfile s data/state.json --slurpfile r data/results.json '{state: $s[0], results: $r[0]}' > /tmp/body.json
code=$(curl -sS --max-time 90 -o /tmp/out.json -w '%{http_code}' -X POST -H "x-tick-key: $TICK_KEY" \
  -H 'content-type: application/json' --data-binary @/tmp/body.json "https://paunovarts-schedule.vercel.app/api/tick${DRY:-}" || echo 000)
echo "$(date -u +%H:%M:%S) HTTP $code $(jq -c 'del(.results)' /tmp/out.json 2>/dev/null | head -c 300)"
if jq -e '.results.posts' /tmp/out.json > /dev/null 2>&1; then jq '.results' /tmp/out.json > data/results.json; fi
git add data/results.json
if ! git diff --cached --quiet; then
  git commit -qm 'Cloud publisher results'
  for i in 1 2 3 4; do git pull --rebase -q origin main && git push -q origin HEAD:main && break; sleep 5; done
fi
[ "$code" -lt 400 ] 2>/dev/null
