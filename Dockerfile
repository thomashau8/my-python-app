FROM python:3.12-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /

# Install system dependencies
RUN apt-get update && apt-get install -y build-essential libpq-dev curl

# Install Poetry
RUN curl -sSL https://install.python-poetry.org | POETRY_VERSION=2.0.1 python3 -
ENV PATH="/root/.local/bin:${PATH}"

# Create the Poetry configuration file with any custom settings first
RUN mkdir -p ~/.config/pypoetry && \
    echo "[repositories]" > ~/.config/pypoetry/config.toml && \
    echo "custom = \"https://my.custom.repo\"" >> ~/.config/pypoetry/config.toml

# Configure Poetry to not create a virtualenv (optional for containers)
RUN poetry config virtualenvs.create false

# Copy dependency definitions AND your package folder
COPY pyproject.toml poetry.lock* my_project/ ./

# Now run Poetry install (which will install your project too)
RUN poetry install --no-interaction --verbose

# Copy the rest of your source code
COPY . .

RUN poetry run python manage.py collectstatic --noinput

EXPOSE 8000

CMD ["poetry", "run", "gunicorn", "config.config.wsgi:application", "--bind", "0.0.0.0:8000"]