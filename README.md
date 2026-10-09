# paunovarts-schedule-timer

A timer and nothing else: a GitHub Actions schedule that wakes the cloud publisher of the Paunov Art **Schedule**
(`/api/tick` on Vercel) every 10 minutes, so Instagram posts still go out while the studio laptop is offline.
The publisher decides what's due; this repo holds no content and no keys (the shared key is an Actions secret).
