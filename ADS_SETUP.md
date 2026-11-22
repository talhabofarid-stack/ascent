# Google AdSense for ASCENT

## Current implementation

ASCENT is configured for the AdSense account selected by the site owner.

- The AdSense loader is in `index.html` for Google’s site-verification process.
- `ads.txt` is present at the site root with the publisher’s authorised-seller entry.
- **Automatic Ads must remain disabled** in the AdSense dashboard.
- ASCENT does **not** use a standalone ad interstitial, loading screen, or navigation-only screen.
- After every **2 completed games**, the existing Flight Complete page can show a content-rich **Mission Debrief**. It includes the player’s result, an explanation of the scoring system, current waypoint, and an original spaceflight note.
- Only after approval and only when a valid manual Display-unit slot is supplied, one responsive ad may be embedded inside that Mission Debrief. It is never the sole content of the screen.
- Until Google approves the site and a manual ad-unit slot is provided, no paid slot or fake ad placeholder is rendered.

## Current policy issue and fix

Google reported: **Google-served ads on screens without publisher content**. The former separate “continue flight” ad modal looked like a standalone navigation/interstitial screen, which is not an appropriate place for a Google-served ad.

The site now removes that separate ad screen. The future manual placement is instead inside the existing content-rich Flight Complete / Mission Debrief page. This change must be deployed before asking Google to review the site again.

## Next steps in AdSense

1. Confirm that `https://playascent.online` loads with HTTPS.
2. Wait until the policy-safe placement update is deployed.
3. In AdSense, open **Sites → playascent.online** and confirm that the policy issue is no longer applicable to the updated site.
4. Tick the confirmation only after the update is live, then choose **Request review**.
5. Complete any payment, identity, tax, or ownership steps only in your own Google account. Never share that information in chat.
6. In **Privacy & messaging**, create and publish a European regulations consent message using Google’s CMP or another Google-certified CMP before enabling personalised ads for EEA, UK, or Swiss visitors.
7. Wait for Google’s new review decision. A review can take days and, in some cases, several weeks.

## After approval: create the manual unit

1. In AdSense, open **Ads → By ad unit → Display ads**.
2. Name it `ASCENT — Mission Debrief`.
3. Keep the unit **Responsive**.
4. Click **Save and get code**.
5. Send the generated snippet or its public `data-ad-slot` number to the developer.

The site already knows the publisher client ID. The only missing value for a real manual ad is the ad-unit slot ID. Once it is added, paid display ads can appear only in the Mission Debrief after games 2, 4, 6, and so on.

## Do not do these things

- Do not enable Auto Ads: they can place ads elsewhere in the game.
- Do not put Google-served ads on a standalone interstitial, loading, navigation, alert, or “continue” screen.
- Do not use somebody else’s publisher ID or ad unit.
- Do not click your own ads or ask others to click them.
- Do not label an ad as game content or place it directly against a game-control button.
- Do not enable personalised ads for European visitors before the consent message is live.
