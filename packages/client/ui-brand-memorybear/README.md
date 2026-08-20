# @deepseek-ai/dsh-client-ui-brand-memorybear

English | [中文](README.zh.md)

This package fills `sidebar.brand.mark`, `sidebar.brand.name`, and `conversation.hero.brand.mark` with the MemoryBear mark and wordmark. Registration is unconditional: the row is mounted by the MemoryBear patch overlay, so its presence in the composed tree is the deployment's decision. The upstream official occupants gate themselves on an artifact profile, so the two packages never register at once.

The three occupants install as one declaration-aware registration set through nested `slots.inject()` calls. The package therefore works whether its row activates before or after the sidebar and conversation declarers, withdraws all occupants when either declaration collapses, and leaves no partial brand mix during HMR. It retains no runtime state. The node half is an empty Loader seat, and the browser title remains a build-environment concern outside this package.

## Model Experience

None, as the package contributes browser presentation only; nothing here reaches a model request.

#### KV Cache effect

None; this package neither assembles nor sends a provider request.

## Known Limitations and Deferred Work

- **The package supplies one occupant set** — alternative presentation belongs in another Cordis package occupying the same slots.
- **The browser title and icon are independent** — `DSH_CLIENT_TITLE` selects title text at build time, and the tab icon and web manifest are static files served from the profile's public directory, neither of which passes through a UI slot.
- **The mark's colours are fixed, not themed** — the head reads dark on either theme; on a dark surface the red spectacles and white muzzle carry recognition instead of the silhouette.
- **The traced geometry exists twice** — `Brand.tsx` and `deploy/memorybear/public/favicon.svg` hold the same path data in two formats; a shape change must edit both.
