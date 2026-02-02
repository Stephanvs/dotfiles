# Rust Development Guidelines

## Building Projects

To prevent context window overflow when building:

```bash
# Pipe build output to temp file
cargo build > /tmp/cargo-build.txt 2>&1

# Then check for errors/warnings
grep -E "error|warning" /tmp/cargo-build.txt

# Or get a summary
tail -20 /tmp/cargo-build.txt
```

For large workspaces, build specific crates:
```bash
cargo build -p my_crate > /tmp/cargo-build.txt 2>&1
cargo build --manifest-path crates/my_crate/Cargo.toml > /tmp/cargo-build.txt 2>&1
```

## Running Tests

Same approach for tests:
```bash
cargo test > /tmp/cargo-test.txt 2>&1
grep -E "failed|error|test result" /tmp/cargo-test.txt
```

Target a specific crate or test:
```bash
cargo test -p my_crate
cargo test my_test_name
```

## Dependencies

ALWAYS use the CLI to add dependencies:
```bash
cargo add serde
cargo add tokio --features full
cargo add anyhow --dev
```

To remove dependencies:
```bash
cargo rm serde
```

If cargo add/rm is missing, install cargo-edit:
```bash
cargo install cargo-edit
```

Avoid manually editing Cargo.toml for dependency changes unless cargo-edit is unavailable.

## Creating New Projects

Use the CLI for all project creation:
```bash
# New binary crate
cargo new my_app

# New library crate
cargo new my_lib --lib

# Initialize an existing directory
cargo init
```

## Repository Structure

If a repository contains multiple crates, maintain the existing layout when adding new crates. Follow the same structure used in the repo (for example, `/home/stephanvs/code/neon`).

## Running Binaries

```bash
cargo run
cargo run -p my_crate
cargo run --bin my_bin
```

## Formatting and Linting

```bash
cargo fmt
cargo clippy
cargo clippy --all-targets --all-features
```

## Updating Dependencies

```bash
cargo update
cargo update -p serde
```

## Building for Release

```bash
cargo build --release
cargo build -p my_crate --release
```

## Documentation

```bash
cargo doc --open
```

## Common Patterns

### Check if build succeeds without full output
```bash
cargo build -q && echo "Build succeeded" || echo "Build failed"
```

### Get just error count
```bash
cargo build 2>&1 | grep -c "error:"
```
