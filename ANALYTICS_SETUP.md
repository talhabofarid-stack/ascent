# Google Analytics for ASCENT

## Current direct GA4 setup

ASCENT uses the public Google Analytics 4 Measurement ID created by the owner:

```text
G-G987KT8K4C
```

The site loads Google Analytics directly — it does **not** require a Google Tag Manager account or container. Google Analytics is loaded only after a visitor chooses **Allow analytics** on ASCENT.

Once consent is granted, ASCENT sends the normal GA4 page view plus these custom events:

| Event | When it is sent | Parameters sent by ASCENT |
| --- | --- | --- |
| `game_start` | A seven-question flight begins | `flight_question_count` |
| `game_complete` | The player completes all seven questions | `flight_score`, `flight_destination`, `questions_completed` |

The game deliberately does **not** send a player’s typed answer, name, email address, account information, or other direct identifiers as analytics events.

## What the owner needs to do

There is no Google Tag Manager setup, container, trigger, or event-tag configuration to create. The direct GA4 integration is already configured in the website source.

After the matching site deployment is live:

1. Open `https://playascent.online` in a private/incognito window, or clear this site’s data first.
2. Choose **Allow analytics** in the ASCENT analytics choice.
3. Click **Begin Ascent** to produce a `game_start` event.
4. Finish all seven questions to produce a `game_complete` event.
5. Open [Google Analytics](https://analytics.google.com/) and choose the **ASCENT website** property.
6. Check **Reports → Realtime**. A page view and the game events should appear shortly after the test.

The yellow “data collection is not active” message in GA4 can remain briefly after a new deployment. Realtime is the best first check; standard reports can take up to a day to populate.

## Where to see the numbers

- **GA4 → Reports → Realtime**: immediate testing and current visitors.
- **GA4 → Reports → Engagement → Events**: counts for `game_start` and `game_complete`.
- **GA4 → Reports → Acquisition**: visitors and traffic sources.
- **GA4 → Explore**: compare game starts with completed games to calculate a completion rate.

Event counts work without extra GA4 configuration. To analyse the optional score and destination values in standard reports later, register matching event-scoped custom dimensions / metrics in **GA4 Admin → Custom definitions**:

```text
flight_question_count
flight_score
flight_destination
questions_completed
```

## Consent and advertising

Visitors who choose **Keep it off** are not tracked by this analytics integration. The privacy page lets them change their preference later and removes first-party GA cookies that the browser permits the page to remove.

Analytics consent is separate from advertising consent. **Do not enable AdSense Auto Ads.** Before personalised advertising is enabled for EEA, UK, or Swiss visitors, publish a suitable Google-certified CMP / Google Privacy & messaging consent solution as documented in `ADS_SETUP.md`.
