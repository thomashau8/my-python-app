# Stage 1: Build stage using the Python base image
FROM docker.io/thomashau8/python-base:latest AS builder
WORKDIR /app

# Copy dependency files first for caching
COPY pyproject.toml poetry.lock* ./

# Disable Poetry’s virtualenv creation so it installs into the current environment.
RUN poetry config virtualenvs.create false

# Install dependencies (using --no-root to avoid packaging your project)
RUN poetry install --no-interaction --no-ansi --no-root

# Copy the rest of your source code.
COPY . .

# (Optional) Compile Python code to catch errors early.
RUN poetry run python -m compileall .

# Collect static files (if using Django)
RUN poetry run python manage.py collectstatic --noinput

# Stage 2: Production stage – use the same Python base image
FROM myrepo/python-base:latest AS production
WORKDIR /app

# Copy built app from builder stage
COPY --from=builder /app /app

# Set up a non-root user for security
RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser

# Switch to the non-root user
USER appuser

# Expose the port your application uses
EXPOSE 8000

# Command to start the app (adjust according to your project)
CMD ["poetry", "run", "gunicorn", "config.wsgi:application", "--bind", "0.0.0.0:8000"]