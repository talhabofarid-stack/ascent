# Turning on real ads in ASCENT

ASCENT’s every-third-flight interstitial is live in the game logic, but it deliberately has **no ad-network credentials** in this repository. Without a real publisher account, it shows a clearly labelled in-game placeholder rather than pretending to be a paid ad.

## Behaviour already built

- A completed game is counted only after all seven questions finish.
- The break appears before the next flight after game 3, 6, 9, and so on.
- The count is stored only in the visitor’s browser using local storage.
- A visitor sees each break at most once per three-game milestone, even after refreshing the page.
- The **CONTINUE FLIGHT** button starts the next game.

## Google AdSense activation checklist

1. Create and approve a Google AdSense publisher account.
2. Use the custom domain on a stable public site; do not submit an unverified domain.
3. Add a real support contact to `privacy.html` and review the privacy notice for your actual setup.
4. Implement a consent-management solution before serving personalised ads to visitors where consent is required, including the EEA, UK, and Switzerland.
5. Create a display-ad unit in AdSense and copy its publisher client ID and slot ID.
6. In `index.html`, add this tiny configuration *immediately before* the existing main `<script>` tag:

   ```html
   <script>
   window.ASCENT_ADS = {
     client: 'ca-pub-1234567890123456',
     slot: '1234567890'
   };
   </script>
   ```

   Replace both example values with the approved values from your own AdSense account. The existing game code validates the expected formats, loads the Google ad script only when both values are present, and otherwise leaves the clearly labelled placeholder in place.

7. Once Google gives you the publisher ID, add an `ads.txt` file at the site root with the exact line supplied by AdSense. A commonly used Google entry has this shape, but copy the official value from your account rather than inventing one:

   ```text
   google.com, pub-YOUR_PUBLISHER_ID, DIRECT, f08c47fec0942fa0
   ```

## Never do these things

- Do not use somebody else’s publisher ID.
- Do not create fake impressions or click your own ads.
- Do not label an ad as game content or place it where a player can accidentally click it while trying to continue.
- Do not turn on personalised ads before required consent and policy pages are ready.

These steps matter both for visitors and for keeping an ad account in good standing.
