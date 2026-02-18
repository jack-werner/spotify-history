"""Main entry point for spotify-history."""

import argparse

from spotify_history.etl import SpotifyExtractor


def main() -> None:
    """Docstring for main."""
    parser = argparse.ArgumentParser(
        description="Extract recently played tracks from Spotify.",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=50,
        help="Number of recently played tracks to extract.",
    )
    args = parser.parse_args()

    extractor: SpotifyExtractor = SpotifyExtractor()
    extractor.save_recently_played_tracks(limit=args.limit)


if __name__ == "__main__":
    main()
