# syntax=docker/dockerfile:1.7
FROM python:3.12.6-slim-bookworm AS runtime
WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 PYTHONPATH=/app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY worker ./worker
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh && useradd -r -u 10001 appuser
USER 10001
EXPOSE 9100
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=5 \
  CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:9100/metrics', timeout=2)"]
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["python", "-m", "worker.main"]
