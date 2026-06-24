# plex-media-server

Plex Media Server on Ubuntu 24.04 with NVIDIA (NVENC/NVDEC) and Intel VAAPI
hardware-transcode support. Published to GitHub Container Registry as
`ghcr.io/rake-pro/plex-media-server`.

## Image

- Base: `ubuntu:24.04`, amd64 only (the cluster's only arch).
- Plex driver libraries are **not** baked in - they are injected at runtime by
  the NVIDIA container runtime (`runtimeClassName: nvidia` + the device plugin).
  The image only sets `NVIDIA_VISIBLE_DEVICES` / `NVIDIA_DRIVER_CAPABILITIES`.
- Tracks the Plex **beta (Plex Pass) channel**. The beta `.deb` is publicly
  downloadable, so no Plex Pass token is needed to build.

## CI

`.github/workflows/build.yml` builds and pushes on:

- push to `main` touching `Dockerfile`, `entrypoint.sh`, or the workflow
- manual run (Actions tab -> "Build & Push Plex Image" -> Run workflow)

It parses `VERSION` from the `Dockerfile`, builds linux/amd64, and tags the
result `ghcr.io/rake-pro/plex-media-server:<version>` and `:latest`.

Auth uses the built-in `GITHUB_TOKEN` (`packages: write`) - **no registry
secrets to configure**.

## Version bumps

Renovate watches the Plex plexpass release feed (`renovate.json` ->
`customDatasources.plex`, `channel=plexpass`) and opens a PR bumping the pin in
`Dockerfile`. Merging to `main` triggers the build.

## Local build

```
docker build --build-arg VERSION=1.43.2.10687-563d026ea \
  -t ghcr.io/rake-pro/plex-media-server:dev .
```
