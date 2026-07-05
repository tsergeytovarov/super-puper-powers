# Deploy playbook: Telegram bots

Reference material for `deploy-strategy` step 2 when `product_type: tg-bot`. This is background to draw on, not a script to run verbatim — the actual hosting choice and update mechanics still depend on the stack from phase 3 and whatever infrastructure the owner already has.

## BotFather

Every Telegram bot starts here regardless of hosting choice: talk to [@BotFather](https://t.me/BotFather) in Telegram to register the bot and obtain its bot token. This token is the bot's identity and its credential — it is a secret from the moment it's issued, not just once the bot goes live.

- `/newbot` creates the bot and returns the token immediately — capture it into whatever secrets mechanism the hosting choice uses (see Secrets below), never into a file that gets committed.
- BotFather also configures bot-facing metadata that matters for a real launch: `/setdescription`, `/setabouttext`, `/setuserpic`, and `/setcommands` (the command list shown in Telegram's UI). These are product polish, not infrastructure, but worth doing before the phase 8 gate since they're part of what "live" looks like to an actual user.
- If the token is ever accidentally exposed (committed to git, pasted somewhere public), use `/revoke` in BotFather immediately and update the secret everywhere it's stored — a leaked bot token lets anyone impersonate the bot completely.

## Long polling vs webhook — when which

This is the core architectural choice for how the bot receives updates from Telegram, and it drives the rest of the hosting decision.

### Long polling

The bot's process repeatedly asks Telegram's API "any new messages?" and Telegram holds the connection open until there's an update or a timeout. No inbound network connection to the bot is ever required.

- **Owner cost:** works on literally anything that can run a long-lived process and reach the internet outbound — including a VPS with no public IP configuration, a free-tier background-worker service, or even a machine behind a home router with no port forwarding.
- **Update complexity:** whatever the hosting choice's normal deploy/restart mechanic is; there's no webhook registration step to manage on top of it.
- **What breaks under a spike:** a single polling process handles updates serially by default; a genuine spike in messages can create lag, though for MVP-scale bots this is rarely the bottleneck.
- **When this is the right call:** the default for an MVP tg-bot. Simpler to set up (no public HTTPS endpoint needed), simpler to debug (the process just runs, no incoming-webhook plumbing to verify), and works on hosting that doesn't offer a stable public URL for free.

### Webhook

Telegram pushes updates to a public HTTPS URL the bot exposes, instead of the bot asking for them.

- **Owner cost:** requires hosting that offers a public HTTPS endpoint — the same managed-platform or VPS-with-reverse-proxy considerations as `references/web-apps.md`, since a webhook bot is, at the network level, a small web server.
- **Update complexity:** an extra one-time setup step (registering the webhook URL with Telegram's `setWebhook` API call) beyond whatever the hosting's normal deploy mechanic is — and that registration has to be redone if the public URL ever changes.
- **What breaks under a spike:** scales better than polling for high message volume, since it's push-based and can be handled by whatever concurrency the hosting platform offers a normal web app — but this only matters at a message volume well above typical MVP scale.
- **When this is the right call:** the bot is expected to handle meaningfully high message volume, or it's being deployed alongside a web app that already has a public HTTPS endpoint and the extra setup cost is marginal.

### Deciding between them

Default to long polling for an MVP tg-bot — it's simpler, needs no public HTTPS endpoint, and the scale where webhook's advantage matters is well beyond what a first release needs. Recommend webhook only when there's a concrete reason: expected high volume, or the owner already has a public HTTPS-fronted server this bot would piggyback on for free.

## Hosting options

Once polling vs webhook is decided, the hosting question mostly reduces to the other playbooks:

- **Long polling:** needs a place to run a persistent background process. A free-tier background-worker service on a managed platform (Render, Railway, Fly.io — the same platforms as `references/web-apps.md`, used in worker mode rather than web-server mode) or a VPS both work; a VPS needs a process manager (systemd, `pm2`, or similar) so the bot restarts automatically after a crash or a server reboot.
- **Webhook:** needs the same public-HTTPS hosting as a small web app — see `references/web-apps.md` for the managed-platform-vs-VPS trade-offs, HTTPS setup, and domain considerations, all of which apply here unchanged.

## Secret token

Two secrets matter for a tg-bot, and both follow the same rule as every other `product_type`: never in git, described by location (not value) in the runbook.

- **The bot token from BotFather** — store it in the hosting platform's environment-variable mechanism (or a gitignored `.env` file on a VPS), read at runtime, exactly as in `references/web-apps.md`.
- **The webhook secret token, if using webhook** — Telegram's `setWebhook` call accepts a `secret_token` parameter; the bot's webhook handler must check that incoming requests carry this exact token before processing them. Without this check, anyone who discovers the webhook URL can send it fabricated updates. This is a webhook-specific invariant on top of the general "secrets never in git" rule — polling has no equivalent because it never exposes a public endpoint at all.

## Verification checklist

Run this after deploy, before the phase 8 gate:

- [ ] The bot responds in an actual Telegram chat (message it from a real Telegram client, not a simulated request) — this is the tg-bot equivalent of "reachable at its production address."
- [ ] Every must-scenario from `docs/spp/02-mvp-scope.md` was run against the live bot in a real chat, with evidence captured (a screenshot or transcript of the exchange).
- [ ] If using webhook: the webhook is registered (`getWebhookInfo` confirms the expected URL) and the secret-token check is verified — send a request without the correct token and confirm it's rejected.
- [ ] If using long polling: the process is confirmed to survive a restart (redeploy or reboot the host and confirm the bot comes back up on its own, not only that it worked once after a manual start).
- [ ] The bot token and (if applicable) the webhook secret token are absent from git history, not just the current working tree.
- [ ] The deploy is repeatable from what's in the repo — a start script, a process-manager config (systemd unit, `pm2` config), or a platform config file, not a manually-started process with no record of how it was started.
- [ ] The runbook records BotFather-configured metadata (bot username, where the token lives) and, if webhook is used, the registered webhook URL and how to re-register it if the host's public URL changes.
