"""Main module for spotify-history."""

import json
import os
import logging
from pathlib import Path

import spotipy  # type: ignore
from dotenv import load_dotenv
from spotipy.oauth2 import SpotifyOAuth  # type: ignore

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    handlers=[logging.StreamHandler()],
)
logger = logging.getLogger(__name__)

OUTPUT_LOCATION: str = "recently_played.json"


def main() -> None:
    """Docstring for main."""
    logger.info("loading environment variables.")  # noqa
    # Load environment variables from .env
    load_dotenv()

    scope = "user-read-recently-played"

    logger.info("authenticating with Spotify.")
    sp = spotipy.Spotify(
        auth_manager=SpotifyOAuth(
            client_id=os.getenv("SPOTIPY_CLIENT_ID"),
            client_secret=os.getenv("SPOTIPY_CLIENT_SECRET"),
            redirect_uri=os.getenv("SPOTIPY_REDIRECT_URI"),
            scope=scope,
        ),
    )

    logger.info("fetching recently played tracks.")
    results = sp.current_user_recently_played(limit=50)

    logger.info("writing recently played tracks to file.")
    with Path(OUTPUT_LOCATION).open("w", encoding="utf-8") as f:
        json.dump(results, f, indent=2)


if __name__ == "__main__":
    main()
