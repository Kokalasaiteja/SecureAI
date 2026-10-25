from django.db import models

class RegisteredUser(models.Model):
    name = models.CharField(max_length=100)
    email = models.EmailField()
    mobile = models.CharField(max_length=15)
    password = models.CharField(max_length=255)  # Django PBKDF2/Argon2 hashed password
    image = models.ImageField(upload_to='user_images/')
    image_base64 = models.TextField(blank=True, null=True)
    is_active = models.BooleanField(default=False)

    def __str__(self):
        return self.name
