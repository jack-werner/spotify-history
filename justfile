install: 
    uv sync --all-groups

requirements:
    uv pip compile pyproject.toml -o requirements.txt

add-token:
    echo "SPOTIFY_TOKEN_JSON=$(jq -c . .cache)" >> .env

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

# Terraform (infra/)
tf-init:
    cd infra && terraform init

tf-plan:
    cd infra && terraform plan

tf-apply *ARGS:
    cd infra && terraform apply {{ ARGS }}