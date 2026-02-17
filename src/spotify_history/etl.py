"""Main module for spotify-history."""

import datetime
import json
import logging
import os
from pathlib import Path

import spotipy  # type: ignore
from dotenv import load_dotenv
from google.cloud import secretmanager  # type: ignore
from google.cloud import storage  # type: ignore
from spotipy.oauth2 import SpotifyOAuth  # type: ignore

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    handlers=[logging.StreamHandler()],
)
logger = logging.getLogger(__name__)

RUNTIME_TOKEN_CACHE_PATH: str = "/tmp/spotify_token_cache"
SCOPE: str = "user-read-recently-played"

# When GCP_PROJECT_ID is set, these Secret Manager secret IDs are fetched and set as env vars.
SECRET_ID_TO_ENV: dict[str, str] = {
    "spotify-token-json": "SPOTIFY_TOKEN_JSON",
    "spotify-client-secret": "SPOTIFY_CLIENT_SECRET",
    "spotify-client-id": "SPOTIFY_CLIENT_ID",
    "spotify-redirect-uri": "SPOTIFY_REDIRECT_URI",
}


def _load_secrets_from_gcp() -> None:
    """If GCP_PROJECT_ID is set, load secrets from Secret Manager into os.environ."""
    logger.info("Loading secrets from Secret Manager.")
    client = secretmanager.SecretManagerServiceClient()
    for secret_id, env_var in SECRET_ID_TO_ENV.items():
        try:
            name = f"projects/{project_id}/secrets/{secret_id}/versions/latest"
            response = client.access_secret_version(request={"name": name})
            value = response.payload.data.decode("utf-8")
            os.environ[env_var] = value
            logger.info("loaded %s from Secret Manager.", env_var)
        except Exception as e:
            logger.warning("could not load secret %s: %s", secret_id, e)


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


class SpotifyExtractor:
    def __init__(self):
        self.spotipy_client: spotipy.Spotify = self._authenticate_spotipy_client()
    
    @staticmethod
    def _authenticate_spotipy_client() -> spotipy.Spotify:
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
    def _write_results(results: dict) -> None:
        """Write results to local file."""
        payload = json.dumps(results, indent=2)
        now: datetime.datetime = datetime.datetime.now(datetime.timezone.utc)
        base_path: str = os.getenv("GCS_MOUNT_PATH")
        output_location: str = (
            f'{base_path}/recently_played/{now.strftime("%Y-%m-%d")}/{now.strftime("%H:%M:%S")}.json'
        )
        if not Path(output_location).parent.exists():
            Path(output_location).parent.mkdir(parents=True)
        Path(output_location).write_text(payload, encoding="utf-8")
        logger.info("Wrote recently played tracks to %s.", output_location)

    def _get_recently_played_tracks(self, limit: int = 50) -> None:
        logger.info("Fetching recently played tracks.")
        results = self.spotipy_client.current_user_recently_played(limit=limit)
        return results

    def save_recently_played_tracks(self, limit: int = 50) -> None:
        """Save recently played tracks to local file."""
        results = self._get_recently_played_tracks(limit=limit)
        self._write_results(results)
