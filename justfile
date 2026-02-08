install: 
    uv sync --all-groups

requirements:
    uv pip compile pyproject.toml -o requirements.txt

docker-build:
    docker build -t spotify-history .

docker-run:
    docker run --env-file .env spotify-history

test:
    uv run pytest

lint: 
    uv run mypy .
    uv run ruff check .

build: 
    uv build

clean:
    rm -R dist