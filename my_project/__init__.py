# __init__.py
# This file marks the `my_project` folder as a Python package.
# You can import functions from `app.py` directly with:
# from my_project.app import add, subtract

__version__ = "0.1.0"

# Optionally expose key functions directly for convenience
from .app import add, subtract

__all__ = ["add", "subtract"]
