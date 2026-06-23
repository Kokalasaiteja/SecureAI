"""
WSGI config for Usage_of_AI_in_Prevention_of_Social_Engineering_Attack project.

It exposes the WSGI callable as a module-level variable named ``application``.

For more information on this file, see
https://docs.djangoproject.com/en/5.2/howto/deployment/wsgi/
"""

import os

from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'Usage_of_AI_in_Prevention_of_Social_Engineering_Attack.settings')

application = get_wsgi_application()
