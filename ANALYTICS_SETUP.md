# Google Analytics for ASCENT

## What is deployed

`index.html` contains the public Google Tag Manager container ID supplied by the owner:

```text
GTM-NWWS89ZF
```

ASCENT does **not** load that container until a visitor chooses **Allow analytics**. Once it is allowed, the browser starts Google Tag Manager and pushes these custom data-layer events:

| Event | When it is pushed | Parameters sent by ASCENT |
| --- | --- | --- |
| `game_start` | A seven-question flight begins | `flight_question_count` |
| `game_complete` | The player completes all seven questions | `flight_score`, `flight_destination`, `questions_completed` |

The game deliberately does **not** send a player’s typed answer, name, email address, or account information.

Page/visitor counts are collected by the normal Google tag / GA4 page-view tag configured inside Google Tag Manager. The GTM container ID alone does not create a GA4 property or send analytics anywhere; its connected Google tag must be configured and published in Google Tag Manager.

## One-time Google Tag Manager setup

Do this in the owner’s own Google account at [tagmanager.google.com](https://tagmanager.google.com/). No password, payment, tax, or identity information belongs in this repository or chat.

1. Open container **GTM-NWWS89ZF**.
2. Create a Google Analytics 4 property and web data stream for `https://playascent.online` if one does not already exist. Copy its public Measurement ID, which begins with `G-`.
3. In GTM, create or confirm a **Google tag** using that Measurement ID. Make it fire on **All Pages**. This produces GA4’s normal `page_view` events, which count website visits.
4. Create a Custom Event trigger named `game_start`.
5. Create a Google Analytics: GA4 Event tag:
   - **Event name:** `game_start`
   - **Configuration / Google tag:** the ASCENT GA4 Google tag
   - **Trigger:** the `game_start` Custom Event trigger
6. Create a second Custom Event trigger named `game_complete`.
7. Create another GA4 Event tag:
   - **Event name:** `game_complete`
   - **Configuration / Google tag:** the ASCENT GA4 Google tag
   - **Trigger:** the `game_complete` Custom Event trigger
8. Use **Preview** in GTM and play one complete flight. Confirm that the Google tag, `game_start`, and `game_complete` tags fire once each.
9. Click **Submit → Publish** in GTM.

### Optional event details

To show the optional score and destination in GA4 explorations, create GTM Data Layer Variables for these keys and add them as event parameters to the `game_complete` GA4 Event tag:

```text
flight_score
flight_destination
questions_completed
```

For `game_start`, the optional key is:

```text
flight_question_count
```

If the values should appear in standard GA4 reports, register matching custom dimensions / metrics in **GA4 Admin → Custom definitions**. Event counts work without these optional definitions.

## Where to see the numbers

After GTM is published and players have opted in:

- **GA4 → Reports → Realtime**: check that visits and test events arrive immediately.
- **GA4 → Reports → Engagement → Events**: `game_start` and `game_complete` event counts.
- **GA4 → Reports → Acquisition**: website visitors, traffic channels, and campaigns.
- **GA4 → Explore**: compare game starts with completions and calculate a completion rate.

Normal GA4 reports can take up to a day to fill in. Realtime and DebugView are the best ways to confirm a test right after publishing.

## Consent and privacy

The site displays an analytics choice before Google Tag Manager is loaded. Visitors who choose **Keep it off** are not tracked by this integration. The privacy page lets them change their preference later and removes first-party GA cookies that the browser permits the page to remove.

This keeps the analytics setup separate from advertising consent. **Do not enable AdSense Auto Ads.** Before personalised advertising is enabled for EEA, UK, or Swiss visitors, publish a suitable Google-certified CMP / Google Privacy & messaging consent solution as documented in `ADS_SETUP.md`.
