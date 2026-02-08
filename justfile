set dotenv-load

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

gcp-docker-auth:
    gcloud auth configure-docker $GCP_REGION-docker.pkg.dev

docker-push:
    docker build -t spotify-history .
    docker tag spotify-history $GCP_REGION-docker.pkg.dev/$GCP_PROJECT_ID/$GCP_REPO/spotify-history:latest
    docker push $GCP_REGION-docker.pkg.dev/$GCP_PROJECT_ID/$GCP_REPO/spotify-history:latest

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