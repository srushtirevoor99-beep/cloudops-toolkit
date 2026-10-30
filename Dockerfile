FROM debian:bookworm-slim AS base

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates awscli gawk procps util-linux hostname \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --shell /bin/bash toolkit

WORKDIR /opt/cloudops-toolkit
COPY --chown=toolkit:toolkit scripts/ ./scripts/
RUN chmod +x scripts/*.sh

USER toolkit
CMD ["./scripts/disk-alert.sh", "80", "/"]

FROM base AS test
USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends bats \
    && rm -rf /var/lib/apt/lists/*
COPY --chown=toolkit:toolkit tests/ ./tests/
RUN chmod +x tests/stubs/*
USER toolkit
CMD ["bats", "--print-output-on-failure", "tests/"]
