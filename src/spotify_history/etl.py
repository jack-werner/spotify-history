"""Main module for spotify-history."""

import datetime
import json
import logging
import os
from pathlib import Path
from typing import Any, Iterable

import polars as pl
import spotipy
from google.cloud import storage
from spotipy.oauth2 import SpotifyOAuth

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    handlers=[logging.StreamHandler()],
)
logger = logging.getLogger(__name__)

RUNTIME_TOKEN_CACHE_PATH: str = "/tmp/spotify_token_cache"
SCOPE: str = "user-read-recently-played"


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
                json.dumps(data),
                encoding="utf-8",
            )
            logger.info("using token from SPOTIFY_TOKEN_JSON (runtime).")
            return RUNTIME_TOKEN_CACHE_PATH
        except json.JSONDecodeError as e:
            raise ValueError(f"SPOTIFY_TOKEN_JSON must be valid JSON: {e}") from e
    return os.getenv("SPOTIFY_TOKEN_PATH", ".cache")


class SpotifyExtractor:
    """Class for extracting recently played tracks from Spotify."""

    def __init__(self) -> None:
        """Authenticate with Spotify and initialize the Spotify client."""
        self.spotipy_client: spotipy.Spotify = self._authenticate_spotipy_client()

    @staticmethod
    def _authenticate_spotipy_client() -> spotipy.Spotify:
        """Authenticate with Spotify and return the Spotify client."""
        logger.info("Authenticating with Spotify.")
        return spotipy.Spotify(
            auth_manager=SpotifyOAuth(
                client_id=os.getenv("SPOTIFY_CLIENT_ID"),
                client_secret=os.getenv("SPOTIFY_CLIENT_SECRET"),
                redirect_uri=os.getenv("SPOTIFY_REDIRECT_URI"),
                scope=SCOPE,
                cache_path=_get_cache_path(),
            ),
        )

    @staticmethod
    def _write_results(results: Iterable[dict[str, Any]]) -> None:
        """Write results to GCS when configured, otherwise local file."""
        payload = json.dumps(results, indent=2)
        now: datetime.datetime = datetime.datetime.now(datetime.timezone.utc)
        object_name: str = (
            f"recently_played/{now.strftime('%Y-%m-%d')}/"
            f"{now.strftime('%H:%M:%S')}.json"
        )
        gcs_bucket: str | None = os.getenv("GCS_BUCKET")
        if gcs_bucket:
            client = storage.Client()
            bucket = client.bucket(gcs_bucket)
            blob = bucket.blob(object_name)
            blob.upload_from_string(payload, content_type="application/json")
            logger.info("Wrote recently played tracks to gs://%s/%s.", gcs_bucket, object_name)
            return

        if not Path(object_name).parent.exists():
            Path(object_name).parent.mkdir(parents=True)
        Path(object_name).write_text(payload, encoding="utf-8")
        logger.info("Wrote recently played tracks to %s.", object_name)

    def _get_recently_played_tracks(self, limit: int = 50) -> Iterable[dict[str, Any]]:
        logger.info("Fetching recently played tracks.")
        results: Iterable[dict[str, Any]] = (
            self.spotipy_client.current_user_recently_played(limit=limit)
        )
        return results

    def save_recently_played_tracks(self, limit: int = 50) -> None:
        """Save recently played tracks to local file."""
        results: Iterable[dict[str, Any]] = self._get_recently_played_tracks(
            limit=limit,
        )
        self._write_results(results)


class SpotifyCleaner:
    """Class for cleaning recently played tracks from Spotify."""

    def __init__(self) -> None:
        """Initialize."""
        pass

    @staticmethod
    def _read_directory_json_files(table_name: str) -> pl.LazyFrame:
        """Read recently played tracks from directory files."""
        file_pattern: str = f"{table_name}/*/*.json"
        return pl.scan_ndjson(file_pattern)

    def clean_recently_played_tracks(self) -> pl.DataFrame:
        """Clean recently played tracks."""
        table_name: str = "recently_played"
        lazy_df: pl.LazyFrame = self._read_directory_json_files(table_name)
        # TODO: add cleaning logic here
        return lazy_df.collect()

    def save_cleaned_recently_played_tracks(self) -> None:
        """Save cleaned recently played tracks."""
        df: pl.DataFrame = self.clean_recently_played_tracks()
        base_path: str | None = os.getenv("GCS_MOUNT_PATH")
        output_location: str = "bronze/recently_played.delta"
        if base_path:
            output_location = f"{base_path}/{output_location}"
        df.write_delta(target=output_location)
