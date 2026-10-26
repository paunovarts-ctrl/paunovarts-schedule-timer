#!/usr/bin/env bash
# One tick of the cloud publisher: send the queue and the last results to /api/tick, commit what it answers.
# Used by tick.yml (one tick) and tick-loop.yml (a tick every few minutes for hours). Needs TICK_KEY in the env.
set -u
git rebase --abort 2>/dev/null || true   # a stuck rebase from an earlier tick must never block this one (26 Oct)
git pull -q --rebase --autostash origin main || { git rebase --abort 2>/dev/null; git reset -q --hard origin/main; }
[ -f data/results.json ] || echo '{"posts":{},"log":[]}' > data/results.json
jq -n --slurpfile s data/state.json --slurpfile r data/results.json '{state: $s[0], results: $r[0]}' > /tmp/body.json
code=$(curl -sS --max-time 90 -o /tmp/out.json -w '%{http_code}' -X POST -H "x-tick-key: $TICK_KEY" \
  -H 'content-type: application/json' --data-binary @/tmp/body.json "https://paunovarts-schedule.vercel.app/api/tick${DRY:-}" || echo 000)
echo "$(date -u +%H:%M:%S) HTTP $code $(jq -c 'del(.results)' /tmp/out.json 2>/dev/null | head -c 300)"
if jq -e '.results.posts' /tmp/out.json > /dev/null 2>&1; then jq '.results' /tmp/out.json > data/results.json; fi
git add data/results.json
if ! git diff --cached --quiet; then
  git commit -qm 'Cloud publisher results'
  # never rebase-and-stall: on a race, take the newest remote file and merge ours into it (a lost "published" entry could post twice)
  for i in 1 2 3 4 5; do
    git push -q origin HEAD:main && break
    cp data/results.json /tmp/ours.json; git fetch -q origin main; git reset -q --hard origin/main
    # a failed merge must never save an empty file: then keep this run's answer as before
    if jq -s -f scripts/merge-results.jq data/results.json /tmp/ours.json > /tmp/merged.json && jq -e .posts /tmp/merged.json > /dev/null
    then cp /tmp/merged.json data/results.json; else cp /tmp/ours.json data/results.json; fi; git add data/results.json
    git diff --cached --quiet || git commit -qm 'Cloud publisher results (merged)'; sleep 3
  done
fi
[ "$code" -lt 400 ] 2>/dev/null
