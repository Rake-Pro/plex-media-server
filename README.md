# plex-media-server

Plex Media Server on Ubuntu 24.04 with NVIDIA (NVENC/NVDEC) and Intel VAAPI
hardware-transcode support.

```
ghcr.io/rake-pro/plex-media-server
```

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
capabilities; the host provides the driver via the NVIDIA container runtime - no
driver libraries are baked in.

## Configuration

All configuration is via environment variables.

| Variable | Purpose |
| --- | --- |
| `PLEX_CLAIM_TOKEN` | One-time claim token from <https://plex.tv/claim> (first boot only). |
| `ADVERTISE_IP` / `PLEX_ADVERTISE_URL` | Public URL(s) the server advertises (`customConnections`). |
| `ALLOWED_NETWORKS` / `PLEX_NO_AUTH_NETWORKS` | CIDRs allowed without auth. |
| `PLEX_PREFERENCE_<N>` | Inject any `Preferences.xml` key as `"Key=Value"` (e.g. `PLEX_PREFERENCE_0="TranscoderQuality=0"`). Repeat with incrementing `N`. |
| `PLEX_PURGE_CODECS` | `true` clears the Codecs cache on boot (driver/codec mismatch recovery). |
| `TZ` | Container timezone. |
| `NVIDIA_VISIBLE_DEVICES` / `NVIDIA_DRIVER_CAPABILITIES` | GPU selection / capabilities (defaults: `all` / `compute,video,utility`). |

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
