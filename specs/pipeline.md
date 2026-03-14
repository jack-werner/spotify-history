# Pipeline

This pipeline will build a listening history of a user's spotify songs.

## Source

The main source of this pipeline is a GCS bucket called recently_played. Inside this bucket, there are date partitioned directories. Inside each of these directories are json files with the contents of the response from the [me/player/recently-played](https://developer.spotify.com/documentation/web-api/reference/get-recently-played) endpoint. See the reference here for the output schema of this response.

## Architecture

This pipeline will read all the data from these files, and deduplicate the listening records and extract each `item` from the `items` attribute in the greater json object as a row and then write them to an iceberg table in a new GCS location inside the same bucket called silver/fct_play.

Any records that do not fit within that schema should be written to recently_played/failed/<date>.json.

Reading the JSON and writing the JSON to the Iceberg table should be done with DuckDB and run on a GCP cloud run job.
