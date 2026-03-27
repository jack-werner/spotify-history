"""Main entry point for spotify-history."""

import argparse

from spotify_history.etl import SpotifyCleaner, SpotifyExtractor


def main() -> None:
    """CLI entrypoint for pipeline stages."""
    parser = argparse.ArgumentParser(
        description="Run spotify-history pipeline stages.",
    )
    subparsers = parser.add_subparsers(dest="stage")

    ingest_parser = subparsers.add_parser(
        "ingest",
        help="Extract recently played tracks from Spotify.",
    )
    ingest_parser.add_argument(
        "--limit",
        type=int,
        default=50,
        help="Number of recently played tracks to extract.",
    )

    subparsers.add_parser(
        "transform",
        help="Run cleaning/transform stage for recently played tracks.",
    )

    args = parser.parse_args()

    if args.stage in (None, "ingest"):
        extractor: SpotifyExtractor = SpotifyExtractor()
        extractor.save_recently_played_tracks(limit=args.limit)
        return

    if args.stage == "transform":
        cleaner: SpotifyCleaner = SpotifyCleaner()
        cleaner.save_cleaned_recently_played_tracks()


if __name__ == "__main__":
    main()
