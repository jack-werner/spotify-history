# spotify-history

This my python template set up with my preferred project tooling and structure.

This repo comes set up with a few tools to make development easier and more consistent when working with a team.

- `uv` for general python project and package management.
- `ruff` for static python linting, enforcing code standards.
- `mypy` for static type checking.
- `just` for running common collections of commands for working with the project.

If you are using VSCode, the following extensions are also recommended for working with this project setup:

- Ruff
- Mypy Type Checker
- GitHub Actions
- Even Better TOML
- YAML
- just

## Installation

To work with this package, first install `uv` with

```
pip install uv
```

Then install `just` with

```
brew install just
```

or any of the options listed [here](https://github.com/casey/just?tab=readme-ov-file#installation).

Then, run

```
just install
```

## Contrubuting

To introduce any changes, open a PR and make sure that all tests and linting passes.

## Building

To build, run

```
just build
```

## Stage-safe Cloud Run rollout

The pipeline is deployed as separate Cloud Run Jobs (ingest and transform), so you can
promote image changes to one stage without changing the other.

### Why this helps

- Ingest and transform use independent image pins in Terraform.
- You can test/promote transform first, then promote ingest later.
- Rollback is stage-specific (change one digest, re-apply).

### Typical release flow

1. Build and push the latest image:

```
just docker-push
```

2. Resolve the digest that was pushed:

```
just docker-digest latest
```

3. Promote only one stage using that digest:

```
just promote-transform sha256:...
```

or

```
just promote-ingest sha256:...
```

4. Run `just tf-plan` / `just tf-apply` as needed for any additional Terraform changes.

### Terraform vars used for stage-safe image pinning

- `ingest_image_tag` / `ingest_image_digest`
- `transform_image_tag` / `transform_image_digest`

Digest values take precedence over tags when set.
