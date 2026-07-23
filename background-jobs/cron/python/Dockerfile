FROM python:3.13-slim
WORKDIR /app
COPY requirements.txt* Pipfile* Pipfile.lock* pyproject.toml* poetry.lock* uv.lock* ./
RUN pip install --no-cache-dir -r requirements.txt
COPY . .

# The platform-generated Dockerfile for lang=python framework=cron has no
# EXPOSE at all (see pythonDockerfile() in platform/build) — deliberately
# correct for a plain sleep-loop cron, but this template's job.py now runs
# an HTTP status server alongside the loop (see BZYNC_CLOUD), so it ships
# its own Dockerfile to declare that port instead.
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://localhost:3000/').status == 200 else 1)"

CMD ["python", "job.py"]
