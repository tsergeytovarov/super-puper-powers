# Deploy playbook: packages and plugins

Reference material for `deploy-strategy` step 2 when `product_type: package`. This is background to draw on, not a script to run verbatim — the actual registry, manifest fields, and verification depend on the stack picked in phase 3 and what the product actually is (a library, a CLI tool, a Claude Code plugin/skill).

For this `product_type`, "deploy" means publishing to a registry so someone else can install it — there's no server to keep running, which changes the cost and update-complexity trade-offs from the other playbooks: the ongoing $/month is usually zero, and "what breaks under a spike" mostly doesn't apply (a registry serves the download, not the product's own infrastructure). What replaces those concerns is: does it install cleanly for someone who has never seen the source, and does a new version reach existing installs the way users expect.

## Hosting options: which registry

### npm (JavaScript/TypeScript packages)

- **Owner cost:** free to publish public packages; a paid npm account is only needed for private packages.
- **Update complexity:** `npm publish` after bumping the version in `package.json` — effectively one command, provided the account is already authenticated (`npm login`, done once, not part of the repeatable release process).
- **Vendor lock-in:** low — npm is the de facto standard for the JS ecosystem; there's no realistic alternative registry for public JS packages that users would look in instead.
- **When this applies:** the stack from phase 3 is Node.js/TypeScript and the product is a library or CLI tool meant to be installed via `npm install` or `npx`.

### PyPI (Python packages)

- **Owner cost:** free to publish.
- **Update complexity:** build the package (`python -m build` or the project's chosen build backend) then `twine upload` (or `uv publish`) after bumping the version — a short sequence, scriptable into one command via a `Makefile` target or a CI job.
- **Vendor lock-in:** low — PyPI is the standard registry for `pip install`-able Python packages.
- **When this applies:** the stack from phase 3 is Python and the product is a library or CLI tool.

### Claude Code plugin marketplace

- **Owner cost:** free.
- **Update complexity:** depends on the marketplace source declared in `.claude-plugin/marketplace.json` — a git-based marketplace (`source: "./"` pointing at a repo) updates when the repo updates and the user re-runs `/plugin update` (or reinstalls); there's no separate publish step beyond committing and tagging the release, which phase 7 (`release-fixation`) already did.
- **Vendor lock-in:** none beyond the Claude Code ecosystem itself — the plugin is a git repo with a manifest, portable to any marketplace source.
- **When this applies:** `product_type: package` and the product is itself a Claude Code plugin or skill, not a general-purpose library.

### Deciding between them

The registry isn't really a choice among competing options the way hosting is for web apps — it's determined by the stack and the target audience: JS library → npm, Python library → PyPI, Claude Code plugin → the plugin marketplace mechanism. If the product could reasonably target more than one (rare, but a `mixed` product might bundle a CLI and a plugin), treat each artifact as its own mini-deploy against the matching registry.

## Manifests

Every registry requires a manifest file that describes the package — this is not optional boilerplate, it's what the registry and the installer both read to know what they're getting:

- **npm:** `package.json` — `name`, `version` (semver, matching what phase 7 fixed), `main`/`exports` (entry point), `license`, and `files` or `.npmignore` to control what actually ships (don't publish `node_modules`, test fixtures, or local config).
- **PyPI:** `pyproject.toml` — `[project]` table with `name`, `version`, dependencies, and build-system declaration. Match the version to what phase 7 fixed.
- **Claude Code plugin:** `.claude-plugin/plugin.json` — `name`, `version`, `description`, `author`, `license`, and (per the SPP repo-structure convention) `homepage`/`repository`. The `marketplace.json` alongside it declares how the plugin is discovered and installed.

Whichever manifest applies, the version field must match the semver phase 7 fixed in `docs/spp/07-release-notes.md` — a mismatch between the release notes and what actually got published is a defect the owner has no way to catch themselves.

## Mandatory verification: install from scratch

This is the smoke-test invariant from `deploy-strategy` step 2, specialized for packages: there is no "production server" to check, so the equivalent must-scenario verification is installing the package the way a real user would, from a clean environment that has never seen the source tree.

This step is **mandatory, not optional** — a package that only ever ran from the developer's own checkout can fail to install anywhere else for reasons the source tree hides entirely (a file missing from the published tarball, a dependency present locally but not declared, a hardcoded local path).

- **npm:** in a separate temp directory (or `npm pack` then install the resulting tarball elsewhere), run `npm install <package-name>` (or install the local tarball) and execute the must-scenario the package is meant to deliver — import it and call its main entry point, or run its CLI command.
- **PyPI:** in a fresh virtual environment (`uv venv` in a scratch directory), run `pip install <package-name>` (or `uv pip install` from the built wheel/sdist) and execute the must-scenario.
- **Claude Code plugin:** in a separate Claude Code session or a scratch project directory, run `/plugin marketplace add <repo-or-path>` followed by `/plugin install`, then confirm the skill(s) actually trigger and behave as the MVP scope describes.

Capture the evidence (command output, a successful invocation) — this is what satisfies the phase 8 gate's "production scenarios verified" requirement for a package-shaped product, in place of a live-server smoke test.

## Verification checklist

Run this after publishing, before the phase 8 gate:

- [ ] The manifest's version field matches the semver fixed in `docs/spp/07-release-notes.md`.
- [ ] The package installs successfully from the registry (or from the marketplace source) into a clean environment that has no prior copy of the source tree.
- [ ] Every must-scenario from `docs/spp/02-mvp-scope.md` was executed against the freshly-installed copy, not the original checkout, with evidence captured.
- [ ] No secrets, local paths, or local-only config ended up in the published artifact — check what actually got published (`npm pack --dry-run`, inspect the built sdist/wheel, or review the git tree for a git-sourced plugin), not just what's in `.gitignore`.
- [ ] The publish step itself is repeatable from a documented command or script (`npm publish`, a `twine upload` sequence, or a tag-triggered CI job) — not a one-off manual upload nobody wrote down.
- [ ] The runbook records how to publish an update (the exact command sequence) and, where the registry supports it, how to yank/deprecate a bad version.
