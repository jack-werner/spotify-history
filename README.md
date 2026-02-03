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
