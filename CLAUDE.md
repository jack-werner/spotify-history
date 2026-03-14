# CLAUDE.md

## What This Repo Does

`spotify-history` is a data pipeline that extracts a user's recently played tracks from the Spotify API and stores them as timestamped JSON files. It is designed to run on a recurring schedule in GCP, building up a historical record of Spotify listening activity.

## Architecture

### Python Package (`src/spotify_history/`)

- **`etl.py`** — Core logic, two classes:
  - `SpotifyExtractor`: Authenticates with Spotify via OAuth (spotipy), fetches recently played tracks (up to 50), and writes timestamped JSON to `recently_played/YYYY-MM-DD/HH:MM:SS.json`. Writes locally or to a GCS FUSE mount path if `GCS_MOUNT_PATH` is set.
  - `SpotifyCleaner`: Reads the raw JSON files and converts them to Delta format at `bronze/recently_played.delta`. Cleaning logic is stubbed out (TODO).
- **`__main__.py`** — CLI entrypoint. Accepts `--limit` (default 50) and calls `SpotifyExtractor.save_recently_played_tracks()`.

### Auth / Token Handling

Spotify credentials come from environment variables (`SPOTIFY_CLIENT_ID`, `SPOTIFY_CLIENT_SECRET`, `SPOTIFY_REDIRECT_URI`). The OAuth token cache is resolved from:
1. `SPOTIFY_TOKEN_JSON` env var (JSON string written to `/tmp/spotify_token_cache`) — used in Cloud Run
2. `SPOTIFY_TOKEN_PATH` env var or `.cache` file — used locally

### GCP Infrastructure (`infra/`)

Managed with Terraform:
- **Cloud Run Job** — runs the Docker image on demand or on schedule
- **Cloud Scheduler** — triggers the job every 15 minutes
- **GCS Bucket** — mounted via FUSE into the container at `/mnt/spotify-history` for output storage
- **Artifact Registry** — hosts the Docker image
- **Secret Manager** — stores Spotify credentials and token JSON; injected as env vars into the Cloud Run job

The default compute service account is used for the job; IAM bindings for Secret Manager, GCS, Artifact Registry, and Cloud Run invoker are managed in Terraform.

### Key Environment Variables

| Variable | Purpose |
|---|---|
| `SPOTIFY_CLIENT_ID` | Spotify app client ID |
| `SPOTIFY_CLIENT_SECRET` | Spotify app client secret |
| `SPOTIFY_REDIRECT_URI` | OAuth redirect URI |
| `SPOTIFY_TOKEN_JSON` | Serialized token cache (for Cloud Run) |
| `GCP_PROJECT_ID` | GCP project |
| `GCP_REGION` | GCP region (for Docker push) |
| `GCP_REPO` | Artifact Registry repo name |
| `GCS_BUCKET` | GCS bucket name |
| `GCS_MOUNT_PATH` | FUSE mount path inside container |

Local values are stored in `.env` (loaded automatically by `just` via `set dotenv-load`).

## Just Recipes

Run `just <recipe>` from the repo root.

### Development

| Recipe | What it does |
|---|---|
| `just install` | Install all dependencies including dev/lint groups via `uv sync --all-groups` |
| `just test` | Run pytest via `uv run pytest` |
| `just lint` | Run mypy (strict) and ruff check |
| `just build` | Build the Python wheel via `uv build` |
| `just clean` | Remove the `dist/` directory |
| `just requirements` | Compile `requirements.txt` from `pyproject.toml` via `uv pip compile` |

### Spotify Token Management

| Recipe | What it does |
|---|---|
| `just add-token` | Append `SPOTIFY_TOKEN_JSON=<contents of .cache>` to `.env` |
| `just update-spotify-token` | Create/update the `spotify-token-json` secret in GCP Secret Manager from `.cache` |

### Docker

| Recipe | What it does |
|---|---|
| `just docker-build` | Build the Docker image for `linux/amd64` tagged `spotify-history` |
| `just docker-run` | Run the Docker image locally using `.env` |
| `just gcp-docker-auth` | Authenticate Docker to push to Artifact Registry (`$GCP_REGION-docker.pkg.dev`) |
| `just docker-push` | Build, tag, and push the image to Artifact Registry (requires `GCP_REGION`, `GCP_PROJECT_ID`, `GCP_REPO` in `.env`) |

### Terraform

| Recipe | What it does |
|---|---|
| `just tf-init` | `terraform init` inside `infra/` |
| `just tf-plan` | `terraform plan` inside `infra/` |
| `just tf-apply [ARGS]` | `terraform apply` inside `infra/`, passes optional extra args (e.g. `-auto-approve`) |

## Tooling

- **uv** — package and virtualenv management
- **ruff** — linting (strict ruleset; line length 88)
- **mypy** — type checking (strict mode; spotipy errors suppressed)
- **pytest** — tests in `tests/`
- **hatchling** — build backend
- **just** — task runner
- **Terraform** — GCP infrastructure
