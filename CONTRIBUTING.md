# Contributing

Thanks for your interest in the CloudOps Toolkit.

## Setup

```bash
git clone https://github.com/srushtirevoor99-beep/cloudops-toolkit.git
cd cloudops-toolkit
sudo apt-get install -y bats shellcheck
```

## Before you open a pull request

```bash
shellcheck scripts/*.sh tests/stubs/*
bats tests/
```

CI runs the same two commands, and a pull request cannot deploy unless both pass.

## Guidelines

- Start scripts with `#!/usr/bin/env bash` and `set -euo pipefail` (use `set -eu` if a pipeline ends in `head`).
- Validate arguments and exit non-zero with a message on stderr when they are wrong.
- Quote every variable.
- Add a bats test for every new behaviour, including the failure case. The fake `aws`, `df` and `free` commands in `tests/stubs/` let tests run without AWS credentials.
- Never commit credentials, keys, or real account details.
- Keep pull requests small and describe what changed and why.
