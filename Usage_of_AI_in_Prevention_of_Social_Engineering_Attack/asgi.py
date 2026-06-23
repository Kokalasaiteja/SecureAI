"""
ASGI config for Usage_of_AI_in_Prevention_of_Social_Engineering_Attack project.

It exposes the ASGI callable as a module-level variable named ``application``.

For more information on this file, see
https://docs.djangoproject.com/en/5.2/howto/deployment/asgi/
"""

import os

from django.core.asgi import get_asgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'Usage_of_AI_in_Prevention_of_Social_Engineering_Attack.settings')

application = get_asgi_application()
