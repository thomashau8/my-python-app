# Stage 1: Build stage using the Python base image
FROM python:3.12-slim AS builder
WORKDIR /app

# Install system dependencies
# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential \
      libpq-dev \
      curl \
    && apt-get upgrade -y --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Install Poetry
RUN bash -o pipefail -c "curl -sSL https://install.python-poetry.org | POETRY_VERSION=2.0.1 python3 -"
ENV PATH="/root/.local/bin:${PATH}"

# Configure Poetry: disable automatic virtualenv creation
RUN poetry config virtualenvs.create false

# Copy dependency files first to leverage Docker cache
COPY pyproject.toml poetry.lock* ./

# Install dependencies
RUN poetry install --no-interaction --no-ansi --no-root

# Copy the rest of your source code
COPY . .

# Compile Python files to catch syntax errors early
RUN poetry run python -m compileall . && \
    poetry run python manage.py collectstatic --noinput


# Stage 2: Production Stage – Use the built application from the builder stage
FROM builder AS production
WORKDIR /app

# Create a non-root user for security
RUN if ! id appuser > /dev/null 2>&1; then \
        addgroup --system appgroup && adduser --system --ingroup appgroup appuser; \
    fi

RUN chown -R appuser:appgroup /app || true

USER appuser

EXPOSE 8000

# Set the command to run your application (using Gunicorn for example)
CMD ["gunicorn", "config.wsgi:application", "--bind", "0.0.0.0:8000"]