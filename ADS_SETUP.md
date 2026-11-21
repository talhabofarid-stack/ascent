# Google AdSense for ASCENT

## Current implementation

ASCENT is configured for the AdSense account selected by the site owner.

- The AdSense loader is in `index.html` for Google’s site-verification process.
- `ads.txt` is present at the site root with the publisher’s authorised-seller entry.
- **Automatic Ads must remain disabled** in the AdSense dashboard.
- The game reserves one manual, clearly labelled flight-break placement after every **2 completed games**: before games 3, 5, 7, and so on.
- Until Google approves the site and a manual ad-unit slot is provided, the break shows an honest “review in progress” placeholder instead of a fake advertisement.

## Next steps in AdSense

1. Confirm that `https://playascent.online` loads with HTTPS.
2. In AdSense, open **Sites → playascent.online**.
3. Confirm the site is connected, then choose **Request review** when Google offers it.
4. Complete any payment, identity, tax, or ownership steps only in your own Google account. Never share that information in chat.
5. In **Privacy & messaging**, create and publish a European regulations consent message using Google’s CMP or another Google-certified CMP before enabling personalised ads for EEA, UK, or Swiss visitors.
6. Wait for Google’s approval. A review can take days and, in some cases, several weeks.

## After approval: create the manual unit

1. In AdSense, open **Ads → By ad unit → Display ads**.
2. Name it `ASCENT — Flight Break`.
3. Keep the unit **Responsive**.
4. Click **Save and get code**.
5. Send the generated snippet or its `data-ad-slot` number to the developer.

The site already knows the publisher client ID. The only missing value for a real manual ad is the ad-unit slot ID. Once it is added, paid display ads will appear only in the built-in flight break after games 2, 4, 6, and so on.

## Do not do these things

- Do not enable Auto Ads: they can place ads elsewhere in the game.
- Do not use somebody else’s publisher ID or ad unit.
- Do not click your own ads or ask others to click them.
- Do not label an ad as game content or place it under the Continue button.
- Do not enable personalised ads for European visitors before the consent message is live.
