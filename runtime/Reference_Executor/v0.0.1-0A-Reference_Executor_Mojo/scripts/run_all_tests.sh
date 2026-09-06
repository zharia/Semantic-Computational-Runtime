#! /usr/bin/env bash

uv run mojo run -I src examples/001_hello.mojo
uv run mojo run -I src examples/002_relationship.mojo
uv run mojo run -I src examples/003_transformation.mojo
uv run mojo run -I src examples/004_constraint_rollback.mojo
