#!/usr/bin/env python
"""Django's command-line utility for administrative tasks."""
import os
import sys

from pathlib import Path

# Load environment variables from .env (if present)
try:
    from dotenv import load_dotenv
    dotenv_path = Path(__file__).resolve().parent / '.env'
    load_dotenv(dotenv_path=dotenv_path)
except Exception:
    # If python-dotenv isn't installed or .env doesn't exist, fall back to normal env vars
    pass





def main():
    """Run administrative tasks."""
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'Usage_of_AI_in_Prevention_of_Social_Engineering_Attack.settings')
    try:
        from django.core.management import execute_from_command_line
    except ImportError as exc:
        raise ImportError(
            "Couldn't import Django. Are you sure it's installed and "
            "available on your PYTHONPATH environment variable? Did you "
            "forget to activate a virtual environment?"
        ) from exc
    execute_from_command_line(sys.argv)


if __name__ == '__main__':
    main()
