# plex-media-server

Plex Media Server on Ubuntu 26.04 with NVIDIA (NVENC/NVDEC) and Intel VAAPI
hardware-transcode support.

```
ghcr.io/rake-pro/plex-media-server
```

## Tags / releases

| Tag | Meaning |
| --- | --- |
| `X.Y.Z` | Immutable release, built from git tag `vX.Y.Z` |
| `X.Y` | Latest patch of that minor |
| `latest` | Latest release |
| `<plex-version>` | The exact upstream Plex Media Server version baked into that release (e.g. `1.43.4.10903-e5521bd8c`) |
| `sha-<short>` | Commit the image was built from |

- `dev` is the integration branch (default); `ci.yml` builds on every push and PR.
- `sync-main.yml` opens a promotion PR from `dev` to `main`. Merging it (merge
  commit) mints the next patch tag and `release.yml` builds, pushes and
  Trivy-scans the image (blocking on fixable CRITICALs).
- Label the promotion PR `release:minor` or `release:major` to change the bump.
- `trivy-rescan.yml` re-scans the currently released image weekly
  (CRITICAL+HIGH) so CVEs disclosed after release still surface; it does not
  rebuild or push anything.
- `plex-version-check.yml` polls the Plex Pass (beta) download channel daily
  and opens a PR into `dev` bumping the pinned `VERSION` build arg when a
  newer build is available (requires a `PLEX_TOKEN` repository secret).
- Pin `X.Y.Z` in deployments; `latest` is a convenience pointer.

## Run

```
docker run -d --name plex \
  --network host \
  -e TZ=Etc/UTC \
  -e PLEX_CLAIM_TOKEN=claim-xxxxxxxx \
  -e ADVERTISE_IP=https://plex.example.com \
  -v /path/to/config:/config \
  -v /path/to/media:/mnt/media:ro \
  --tmpfs /transcode \
  ghcr.io/rake-pro/plex-media-server:latest
```

For NVIDIA hardware transcoding add `--runtime nvidia --gpus all` (and Plex Pass
on the account). The image already requests the `compute,video,utility` driver
capabilities; the host provides the driver via the NVIDIA container runtime, and
no driver libraries are baked in.

## Configuration

All configuration is via environment variables.

| Variable | Default | Purpose |
| --- | --- | --- |
| `PLEX_CLAIM_TOKEN` | (empty) | One-time claim token from <https://plex.tv/claim> (first boot only). |
| `ADVERTISE_IP` / `PLEX_ADVERTISE_URL` | (empty) | Public URL(s) the server advertises (`customConnections`). |
| `ALLOWED_NETWORKS` / `PLEX_NO_AUTH_NETWORKS` | (empty) | CIDRs allowed without auth. |
| `PLEX_PREFERENCE_<N>` | (empty) | Inject any `Preferences.xml` key as `"Key=Value"` (e.g. `PLEX_PREFERENCE_0="TranscoderQuality=0"`). Repeat with incrementing `N`. |
| `PLEX_PURGE_CODECS` | `false` | `true` clears the Codecs cache on boot (driver/codec mismatch recovery). |
| `TZ` | `Etc/UTC` | Container timezone. |
| `NVIDIA_VISIBLE_DEVICES` | `all` | GPU selection for the NVIDIA container runtime. |
| `NVIDIA_DRIVER_CAPABILITIES` | `compute,video,utility` | Driver capabilities requested from the NVIDIA container runtime. |

## Ports

| Port | Use |
| --- | --- |
| `32400/tcp` | Plex web UI and API (the only required port). |

## Volumes

| Path | Use |
| --- | --- |
| `/config` | Plex database, metadata, preferences (persist this). |
| `/transcode` | Scratch space for transcoding (ephemeral / tmpfs recommended). |
| media mounts | Your libraries, mounted wherever you point the libraries (read-only is fine). |
