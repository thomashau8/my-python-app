# Stage 1: Build stage using the Python base image
FROM python:3.12-slim AS builder
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential=12.9 \
      libpq-dev=15.12-0+deb12u2 \
      curl=7.88.1-10+deb12u12 && \
    rm -rf /var/lib/apt/lists/*

# Install Poetry
RUN bash -o pipefail -c "curl -sSL https://install.python-poetry.org | POETRY_VERSION=2.0.1 python3 -"
ENV PATH="/root/.local/bin:${PATH}"

# Copy dependency files and install dependencies
COPY pyproject.toml poetry.lock* ./
RUN poetry install --no-interaction --no-ansi --no-root

# Install dependencies (using --no-root so that your project isn't packaged)
RUN poetry install --no-interaction --no-ansi --no-root

# Copy the rest of the source code and build your application
COPY . .
RUN poetry run python -m compileall . && \
    poetry run python manage.py collectstatic --noinput


# Stage 2: Production Stage – Use the built application from the builder stage
FROM builder AS production
WORKDIR /app

# Create a non-root user for security
RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser
USER appuser

# Set the command to run your application (using Gunicorn for example)
CMD ["poetry", "run", "gunicorn", "config.wsgi:application", "--bind", "0.0.0.0:8000"]