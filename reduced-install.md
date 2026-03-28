# Reducing Dependency Install Time

## Problem

Running `npm install` for the storefront takes ~30 minutes. The main causes are:

1. **5 packages use `latest` instead of pinned versions** — npm must query the registry to resolve these on every install, even with a lockfile present
2. **16,222-line lockfile** — large transitive dependency tree, partly inflated by `latest` resolution
3. **No `.npmrc`** — missing cache and registry optimizations
4. **Redundant overrides** — both `resolutions` (Yarn legacy) and `overrides` (npm) are set for React; `resolutions` is unused since `packageManager` is npm

## Solution

### 1. Pin `latest` versions to exact installed versions in `package.json`

```
@medusajs/icons:       "latest" → "2.13.5"
@medusajs/js-sdk:      "latest" → "2.13.5"
@medusajs/ui:          "latest" → "4.1.5"
@medusajs/types:       "latest" → "2.13.5"
@medusajs/ui-preset:   "latest" → "2.13.5"
```

This eliminates registry lookups for version resolution on every install. Updates become explicit — bump the version number when you want a newer release.

### 2. Create `.npmrc` with cache optimizations

```ini
prefer-offline=true
fund=false
audit=false
```

- `prefer-offline` — use cached packages when available, skip network requests
- `fund=false` — skip the fund metadata fetch after install
- `audit=false` — skip the security audit HTTP call after install

### 3. Remove unused `resolutions` block from `package.json`

The `resolutions` field is a Yarn convention. Since `packageManager` is `npm@10.8.2`, only `overrides` is effective. Removing `resolutions` avoids confusion and potential edge cases.

## Expected Impact

| Optimization | Time saved |
|---|---|
| Pin `latest` → exact | Removes registry resolution round-trips (biggest impact) |
| `prefer-offline=true` | Skips network for cached packages |
| `fund=false` / `audit=false` | Eliminates 2 post-install HTTP calls |
| Remove `resolutions` | Negligible, cleanup only |

## Files to Modify

| File | Change |
|---|---|
| `package.json` | Pin 5 Medusa deps to exact versions, remove `resolutions` block |
| `.npmrc` (new) | Add `prefer-offline`, `fund=false`, `audit=false` |
