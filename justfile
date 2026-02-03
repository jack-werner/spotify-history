install: 
    uv sync --all-groups

test:
    uv run pytest

lint: 
    uv run mypy .
    uv run ruff check .

build: 
    uv build

clean:
    rm -R dist