"""Main entry point for spotify-history."""

import argparse

from spotify_history.etl import SpotifyExtractor, SpotifyTransformer


def main() -> None:
    """Run the spotify-history pipeline."""
    parser = argparse.ArgumentParser(description="Spotify history pipeline.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    ingest_parser = subparsers.add_parser(
        "ingest",
        help="Extract recently played tracks from Spotify and write raw JSON.",
    )
    ingest_parser.add_argument(
        "--limit",
        type=int,
        default=50,
        help="Number of recently played tracks to extract (default: 50).",
    )

    subparsers.add_parser(
        "transform",
        help="Read raw JSON, deduplicate, and write to silver/fct_play Iceberg table.",
    )

    args = parser.parse_args()

    if args.command == "ingest":
        extractor: SpotifyExtractor = SpotifyExtractor()
        extractor.save_recently_played_tracks(limit=args.limit)
    elif args.command == "transform":
        transformer: SpotifyTransformer = SpotifyTransformer()
        transformer.transform()


if __name__ == "__main__":
    main()
