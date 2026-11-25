# ASCENT Versus Sprint — Supabase setup

ASCENT Versus Sprint uses short room codes for two players on separate devices. The static GitHub Pages site talks directly to Supabase through narrowly scoped database functions; it does **not** need a separate app server.

## What you need

- A free Supabase project.
- Access to its **SQL Editor** and **Project Settings → API**.
- The public Project URL and public **anon/publishable** key.

> Never use a `service_role` key, database password, personal access token, or any other private credential in this repository or in `multiplayer-config.js`.

## 1. Create the Supabase project

1. Go to [Supabase](https://supabase.com/dashboard) and create a project.
2. Choose a strong database password and keep it in Supabase only. ASCENT never needs that password.
3. Wait until the project is ready.

## 2. Install the room schema

1. Open **SQL Editor** in the new project.
2. Create a new query.
3. Copy the complete contents of:

   ```text
   supabase/migrations/20261121_create_ascent_versus.sql
   ```

4. Run the query once.

The migration creates:

- seven English-only sprint categories, including **FACIAL EXPRESSIONS**;
- one room table, player table (including a validated cosmetic flight-drone key), and accepted-answer table;
- secure RPC functions for creating, joining, starting, submitting, polling, and closing a room;
- row-level security with **no direct browser table access**.

The game sends an accepted canonical word only after the browser has checked it against the displayed category. The database checks it again before awarding a point. The migration enables RLS, explicitly denies raw browser access to every table, and exposes only the narrowly scoped RPC functions that require each player’s opaque room credential.

> **Existing room setup?** Also run `supabase/migrations/20261121_add_ascent_versus_drones.sql`. It adds the server-validated, room-visible cosmetic drone choice used by the current Versus screen; it does not alter scoring or past answer data.

## 3. Get the two public browser values

Open **Project Settings → API** and copy:

1. **Project URL** — it looks like `https://your-project-ref.supabase.co`
2. **Publishable key** (or the legacy **anon** key)

These are intended to be visible in a browser application. They are not administrative credentials.

## 4. Give the public values to the ASCENT maintainer

The maintainer should place them in `multiplayer-config.js`:

```js
window.ASCENT_MULTIPLAYER = Object.freeze({
  url: 'https://your-project-ref.supabase.co',
  anonKey: 'your-public-anon-or-publishable-key'
});
```

Then deploy the changed file with the rest of the Versus Sprint feature. Do **not** commit a service-role key.

## How rooms work

- Before opening or joining, each player selects one of six flight drones. The selection, callsign, and launch line are cosmetic only; they are visible to the other player but never affect timing, categories, or scoring.
- A host receives a six-character code such as `N7K4QP`.
- One guest joins with that code from another device.
- The host starts a shared 25-second category sprint. The Supabase function selects the shared English category (avoiding the prior category when possible), and start/end timestamps plus answer acceptance are enforced by the database clock, not either player’s device clock.
- Supabase Realtime Broadcast sends data-free “refresh” signals for faster score/state updates; the secure RPC polling fallback keeps the room correct if a browser or project blocks Broadcast. No raw game table is added to Realtime database replication.
- Both players may score the same valid word independently; each player cannot repeat their own word.
- Rejected input never leaves the player’s browser. Accepted canonical words, a display name, selected cosmetic drone key, room code, score, and temporary opaque room credential are used only to run the room. The credential remains in the browser session; Supabase stores only its SHA-256 hash.
- Each open browser sends a lightweight room-state heartbeat. If the other player stops responding for about 12 seconds, the lobby labels them as reconnecting and the host cannot start a fresh sprint until they return. An explicit **Leave room** removes a guest and returns the host to the one-player lobby; a host leaving closes the room for both players.
- Rooms expire after two hours. The database cleans expired rooms when the service is used; for stricter retention, enable a scheduled Supabase cleanup that runs `select public.ascent_cleanup_expired_rooms();`.

## Verification checklist

After configuration, test with two separate browsers/devices:

1. Open `versus.html` on both and choose different flight drones; each player should see both cosmetic drone/callsign identities in the lobby.
2. Host creates a room and shares the code.
3. Guest joins.
4. Host starts a round and both see the same category/countdown.
5. Enter `happy`, `angry`, and another valid **FACIAL EXPRESSIONS** word.
6. Confirm the live score updates, duplicate words for the same player are refused, and the result screen reveals both accepted lists only after time expires.
7. Check that a direct `GET` request to a raw table is denied for the anon key; the browser should use only the RPC endpoints.
