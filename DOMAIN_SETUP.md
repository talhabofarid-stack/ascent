# Custom-domain setup for ASCENT

## Connected domain: `playascent.online`

The owner has registered `playascent.online` through TransIP. This repository includes a `CNAME` file so future GitHub Pages deployments keep the domain attached.

## DNS records to add at TransIP

In the TransIP control panel, open **playascent.online → DNS**. Keep the existing nameservers and add these records for the apex (`@`) domain:

```text
Type  Host  Value
A     @     185.199.108.153
A     @     185.199.109.153
A     @     185.199.110.153
A     @     185.199.111.153
```

GitHub also supports these optional IPv6 `AAAA` records:

```text
Type  Host  Value
AAAA  @     2606:50c0:8000::153
AAAA  @     2606:50c0:8001::153
AAAA  @     2606:50c0:8002::153
AAAA  @     2606:50c0:8003::153
```

## Optional `www` address

To make `www.playascent.online` work too, add:

```text
Type   Host  Value
CNAME  www   talhabofarid-stack.github.io.
```

The CNAME value must point to `talhabofarid-stack.github.io`, **not** to the `/ascent/` path.

## GitHub Pages

The GitHub Pages custom-domain setting should be `playascent.online`. After DNS starts resolving, GitHub Pages will verify the configuration and issue HTTPS. Keep **Enforce HTTPS** enabled when GitHub makes it available.

## Status checks

- The normal game URL remains `https://talhabofarid-stack.github.io/ascent/` until DNS propagation and GitHub verification finish.
- DNS can take from a few minutes up to 24 hours, depending on caching.
- Check that the domain resolves to GitHub’s addresses before expecting the custom domain to load.
- Do not replace TransIP nameservers just to add these records.
