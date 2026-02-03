"""Docstring for module."""
import os
import json
from pathlib import Path

from dotenv import load_dotenv
import spotipy  # noqa
from spotipy.oauth2 import SpotifyOAuth  # noqa

OUTPUT_LOCATION: str = "recently_played.json"


def main() -> None:
    """Docstring for main."""
    print("Hello from spotify-history!")  # noqa
    # Load environment variables from .env
    load_dotenv()

    scope = "user-read-recently-played"

    sp = spotipy.Spotify(
        auth_manager=SpotifyOAuth(
            client_id=os.getenv("SPOTIPY_CLIENT_ID"),
            client_secret=os.getenv("SPOTIPY_CLIENT_SECRET"),
            redirect_uri=os.getenv("SPOTIPY_REDIRECT_URI"),
            scope=scope,
        ),
    )

    # Fetch recently played tracks
    results = sp.current_user_recently_played(limit=20)

    with Path(OUTPUT_LOCATION).open("w", encoding="utf-8") as f:
        json.dump(results, f, indent=2)


if __name__ == "__main__":
    main()
