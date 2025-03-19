FROM ubuntu:24.14

ENV DEBIAN_FRONTEND=noninteractive

# Install system packages needed for Python and Poetry
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      python3 \
      python3-pip \
      build-essential \
      libpq-dev \
      curl && \
    rm -rf /var/lib/apt/lists/*

# Create a symbolic link so that "python" works
RUN ln -s /usr/bin/python3 /usr/local/bin/python

# Install Poetry
RUN curl -sSL https://install.python-poetry.org | POETRY_VERSION=2.0.1 python3 -
ENV PATH="/root/.local/bin:${PATH}"