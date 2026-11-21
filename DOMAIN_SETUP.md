# Custom-domain setup for ASCENT

## Chosen target: `playascent.io`

`playascent.io` is the preferred name from the options discussed. A DNS lookup on **2026-11-21** did not return a public record for either `playascent.io` or `ascentgame.io`, but that **does not prove that either domain is available to register**. Only a registrar can confirm availability and sell the domain.

Do not add a `CNAME` file or configure GitHub Pages with this domain until the owner has bought or otherwise verified control of it. Pointing a site at a domain someone else owns can cause an avoidable configuration problem.

## After buying `playascent.io`

1. Open the repository’s **Settings → Pages → Custom domain** field and enter:

   ```text
   playascent.io
   ```

2. At the domain’s DNS provider, create these four `A` records for the apex (`@`) domain:

   ```text
   185.199.108.153
   185.199.109.153
   185.199.110.153
   185.199.111.153
   ```

   GitHub also supports these optional IPv6 `AAAA` records:

   ```text
   2606:50c0:8000::153
   2606:50c0:8001::153
   2606:50c0:8002::153
   2606:50c0:8003::153
   ```

3. Optionally add a `www` subdomain with this `CNAME` record:

   ```text
   www  CNAME  talhabofarid-stack.github.io.
   ```

4. Wait for GitHub Pages to verify the DNS configuration, then turn on **Enforce HTTPS** in the Pages settings.

5. Add a `CNAME` file containing only `playascent.io` to the Pages source branch once the custom domain is verified. This prevents a later deployment from accidentally removing the configuration.

## Important

- Keep the site live at `https://talhabofarid-stack.github.io/ascent/` until the domain is verified.
- DNS changes can take time to propagate.
- If a different domain is bought instead, replace `playascent.io` with that exact domain in every step above.
- The records above are GitHub Pages’ standard IP addresses. Check GitHub’s current Pages documentation before changing DNS in case its requirements change.
