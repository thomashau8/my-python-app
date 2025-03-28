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
#TODO optimize AS production(?)
FROM builder AS production
WORKDIR /app

# Copy ONLY required runtime files from builder
COPY --from=builder /app /app

# Install only necessary runtime system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
      libpq5=15.12-0+deb12u2 && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user for security
RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser
USER appuser

# Expose the port that your application listens on
EXPOSE 8000

# Set the command to run your application (using Gunicorn for example)
CMD ["gunicorn", "config.wsgi:application", "--bind", "0.0.0.0:8000"]