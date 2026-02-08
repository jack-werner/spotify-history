"""Main module for spotify-history."""

import json
import logging
import os
from pathlib import Path

import spotipy  # type: ignore
from dotenv import load_dotenv
from google.cloud import storage  # type: ignore
from spotipy.oauth2 import SpotifyOAuth  # type: ignore

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    handlers=[logging.StreamHandler()],
)
logger = logging.getLogger(__name__)

OUTPUT_LOCATION: str = "recently_played.json"
RUNTIME_TOKEN_CACHE_PATH: str = "/tmp/spotify_token_cache"


def _get_cache_path() -> str:
    """Resolve token cache path: from SPOTIFY_TOKEN_JSON (write to temp) or SPOTIFY_TOKEN_PATH / .cache."""
    token_json = os.getenv("SPOTIFY_TOKEN_JSON")
    if token_json:
        try:
            data = json.loads(token_json)
            if "refresh_token" not in data:
                raise ValueError("SPOTIFY_TOKEN_JSON must include 'refresh_token'")
            data.setdefault("access_token", "")
            data.setdefault("expires_at", 0)
            Path(RUNTIME_TOKEN_CACHE_PATH).write_text(
                json.dumps(data), encoding="utf-8"
            )
            logger.info("using token from SPOTIFY_TOKEN_JSON (runtime).")
            return RUNTIME_TOKEN_CACHE_PATH
        except json.JSONDecodeError as e:
            raise ValueError(
                f"SPOTIFY_TOKEN_JSON must be valid JSON: {e}"
            ) from e
    return os.getenv("SPOTIFY_TOKEN_PATH", ".cache")


def _write_results(results: dict) -> None:
    """Write results to local file or GCS bucket depending on GCS_BUCKET env."""
    payload = json.dumps(results, indent=2)
    gcs_bucket = os.getenv("GCS_BUCKET")
    if gcs_bucket:
        blob_name = os.getenv("GCS_OBJECT_NAME", OUTPUT_LOCATION)
        client = storage.Client()
        bucket = client.bucket(gcs_bucket)
        blob = bucket.blob(blob_name)
        blob.upload_from_string(payload, content_type="application/json")
        logger.info("wrote recently played tracks to gs://%s/%s.", gcs_bucket, blob_name)
    else:
        Path(OUTPUT_LOCATION).write_text(payload, encoding="utf-8")
        logger.info("wrote recently played tracks to %s.", OUTPUT_LOCATION)


def main() -> None:
    """Docstring for main."""
    logger.info("loading environment variables.")  # noqa
    # Load environment variables from .env
    load_dotenv()

    scope = "user-read-recently-played"
    cache_path = _get_cache_path()

    logger.info("authenticating with Spotify.")
    sp = spotipy.Spotify(
        auth_manager=SpotifyOAuth(
            client_id=os.getenv("SPOTIPY_CLIENT_ID"),
            client_secret=os.getenv("SPOTIPY_CLIENT_SECRET"),
            redirect_uri=os.getenv("SPOTIPY_REDIRECT_URI"),
            scope=scope,
            cache_path=cache_path,
        ),
    )

    logger.info("fetching recently played tracks.")
    results = sp.current_user_recently_played(limit=50)

    logger.info("writing recently played tracks to file.")
    _write_results(results)


if __name__ == "__main__":
    main()
