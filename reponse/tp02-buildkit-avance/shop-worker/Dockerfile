# syntax=docker/dockerfile:1.7
FROM python:3.12.6-slim-bookworm AS builder
ARG TARGETARCH
WORKDIR /app
COPY requirements.txt .
RUN --mount=type=secret,id=pipconf,target=/etc/pip.conf \
    --mount=type=cache,id=pip-${TARGETARCH},target=/root/.cache/pip \
    pip install --prefix=/install -r requirements.txt

FROM python:3.12.6-slim-bookworm AS test
ARG TARGETARCH
WORKDIR /app
COPY requirements.txt requirements-dev.txt ./
RUN --mount=type=secret,id=pipconf,target=/etc/pip.conf \
    --mount=type=cache,id=pip-${TARGETARCH},target=/root/.cache/pip \
    pip install -r requirements-dev.txt
COPY worker ./worker
COPY tests ./tests
ENV PYTHONPATH=/app
RUN pytest -q && ruff check worker tests

FROM python:3.12.6-slim-bookworm AS runtime
ARG APP_VERSION=dev
ARG GIT_SHA=local
LABEL org.opencontainers.image.title="shop-worker" \
      org.opencontainers.image.version="${APP_VERSION}" \
      org.opencontainers.image.revision="${GIT_SHA}" \
      org.opencontainers.image.source="https://github.com/christopheutp/docker_ynov_10_26"
WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    APP_VERSION=${APP_VERSION}
COPY --from=test /app/requirements.txt /tmp/.tests-passed
COPY --from=builder /install /usr/local
COPY worker ./worker
USER 65534
EXPOSE 9100
CMD ["python", "-m", "worker.main"]
