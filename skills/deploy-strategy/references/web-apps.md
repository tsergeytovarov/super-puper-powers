# Deploy playbook: web apps

Reference material for `deploy-strategy` step 2 when `product_type: web`. This is background to draw on, not a script to run verbatim — the actual choice still depends on the stack picked in phase 3, the budget, and whatever infrastructure the owner already has.

## Hosting options: managed platforms vs VPS

### Managed platforms (Vercel, Netlify, Render, Railway, Fly.io, and similar)

What they trade: less control for less operational burden.

- **Owner cost:** most have a free tier that comfortably covers an MVP with modest traffic; paid tiers scale with usage (requests, bandwidth, build minutes) rather than a flat server rent. The bill can grow gradually with success rather than jumping in a step.
- **Update complexity:** typically a `git push` to a connected branch, or a CLI deploy command. This is the "one command" end of the spectrum `deploy-strategy` step 1 asks about.
- **Vendor lock-in:** low to moderate — most of these platforms deploy standard web apps (Node, Python, static sites) without proprietary code changes, so migrating to a different managed platform or a VPS later is usually a config change, not a rewrite. Some platform-specific features (edge functions, specific serverless APIs) do increase lock-in if used.
- **What breaks under a spike:** generally nothing breaks — these platforms autoscale — but the bill can spike instead. Worth naming explicitly to the owner: "it won't go down, but a viral moment could cost more that month."
- **When this is the right call:** the product is a fairly standard web app (a framework the platform explicitly supports), the owner has no existing server to reuse, and the team wants to ship without owning server maintenance.

### VPS (a rented virtual private server — DigitalOcean, Hetzner, a Yandex Cloud VM, and similar)

What they trade: more control and often lower cost at steady scale, for more operational responsibility.

- **Owner cost:** a flat monthly fee regardless of traffic (a few dollars to a few tens of dollars for MVP-scale), which can be cheaper than a managed platform's usage-based pricing once traffic is steady and predictable — but the fee doesn't drop to zero if the product gets no traffic at all, unlike most managed free tiers.
- **Update complexity:** this is the "a ritual" end of the spectrum — someone (or some script) has to SSH in, pull the new code, restart the service, and handle process management (keeping the app running after a crash or reboot). Without a deploy script, this is manual work every single release.
- **Vendor lock-in:** low — a VPS runs whatever the owner puts on it; moving to a different VPS provider is mostly a matter of copying the setup.
- **What breaks under a spike:** the server can run out of CPU, memory, or connections and the app can genuinely go down or become unresponsive, unless the owner has proactively sized the server for headroom or set up their own autoscaling (rare at this scale).
- **When this is the right call:** the owner already has a VPS or cloud account they're paying for and want to reuse, the budget favors a flat low monthly cost at steady traffic, or the stack needs something a managed platform doesn't support well (long-running background processes, unusual runtime requirements).

### Deciding between them

Ask, in order: does the owner already have one of these set up? (reuse it, don't add a redundant account) If not — does the stack run cleanly on a mainstream managed platform, and does the owner want to avoid server maintenance? Default to managed. Pick VPS only when there's a concrete reason: existing infrastructure to reuse, a cost calculation that clearly favors it at expected steady traffic, or a stack requirement the managed platforms don't handle.

## Environment variables and secrets

- Managed platforms: set secrets through the platform's environment variable / secrets panel (dashboard or CLI), never committed to the repo. The app reads them from the process environment at runtime.
- VPS: use a `.env` file that is listed in `.gitignore` and never committed, or the OS-level environment / a secrets manager if one is already in use. The deploy script should document where the file needs to exist on the server and how it gets there (manually placed once, not part of the repeatable deploy script itself, since the whole point is that it never touches git).
- Either way: the runbook (`docs/spp/08-deploy-runbook.md`) describes *where* secrets live (which platform panel, which file path) — never the actual secret values.

## Domain

- A custom domain is optional for an MVP; most managed platforms provide a free subdomain (`myapp.vercel.app` and similar) that's enough to smoke-test and even launch with.
- If the owner wants a custom domain: they buy it from a registrar (Namecheap, Cloudflare Registrar, or a local registrar if jurisdiction favors it) and point its DNS at the hosting platform, following that platform's domain-connection instructions. This is a recurring cost (typically ~$10-15/year) separate from hosting.
- Note the domain cost explicitly in the runbook's $/month figure if the owner adds one.

## HTTPS

- Managed platforms: HTTPS is provisioned automatically for both the platform's subdomain and any custom domain added, with no separate action required. Don't present this as a decision point — it's the default, note it and move on.
- VPS: HTTPS is not automatic. Use a free certificate authority (Let's Encrypt via `certbot` is the mainstream choice) and a reverse proxy (nginx or Caddy) in front of the app to terminate TLS. This is part of what makes VPS deploys "a ritual" rather than "one command" — factor the initial setup and the certificate renewal (`certbot` can automate renewal, but it has to actually be configured to) into the runbook.
- Never ship a production web app without HTTPS — plain HTTP exposes user data (including login credentials) in transit, which is a security defect regardless of `product_type`.

## Verification checklist

Run this after the deploy, before the phase 8 gate:

- [ ] The app is reachable at its production address (platform subdomain or custom domain) from a network the agent doesn't control (not just `localhost`).
- [ ] HTTPS is active — the production address loads over `https://` without a certificate warning.
- [ ] Every must-scenario from `docs/spp/02-mvp-scope.md` works against the production address, not a dev server, with evidence captured (response body, screenshot, or observed behavior).
- [ ] Secrets are set through the platform's mechanism (or a gitignored file on the VPS) and are absent from the git history — check with `git log -p -- <config-file>` or a repo-wide secret scan, not just the current working tree.
- [ ] The deploy is reproducible from what's committed: a deploy script, a platform config file (e.g. `vercel.json`, a `Procfile`), or documented CI configuration — not a sequence of manual dashboard clicks with no record.
- [ ] The domain (if any) resolves and the runbook records where it's registered and how DNS is configured.
