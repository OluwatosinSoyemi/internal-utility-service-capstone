FROM python:3.11-slim AS builder
WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

COPY . .

FROM python:3.11-slim AS runtime
WORKDIR /app

RUN useradd -m appuser
USER appuser

COPY --from=builder /install /usr/local
COPY --from=builder /app /app

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:5000/health').read()" || exit 1

CMD ["python", "app.py"]
