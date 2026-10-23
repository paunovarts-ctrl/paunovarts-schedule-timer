# paunovarts-schedule-timer

The timer and the storage of the Paunov Art **Schedule**'s cloud publisher (`/api/tick` on Vercel), so Instagram
posts go out while the studio laptop is closed or offline. Every 10 minutes a GitHub Actions job sends `data/state.json`
(the queue, pushed by the laptop) and `data/results.json` (what the publisher did) to `/api/tick`, and commits its
answer back to `data/results.json`. The publisher decides what's due. No keys live here (the shared key is an Actions
secret; the Instagram key is in Vercel's environment).
