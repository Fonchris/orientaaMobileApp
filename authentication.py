from rest_framework.authentication import BaseAuthentication
from rest_framework.exceptions import AuthenticationFailed
from .firebase import verify_firebase_token
from django.contrib.auth.models import User

class FirebaseAuthentication(BaseAuthentication):
    def authenticate(self, request):
        header = request.META.get("HTTP_AUTHORIZATION")
        if not header:
            return None

        parts = header.split()
        if len(parts) != 2 or parts[0].lower() != "bearer":
            raise AuthenticationFailed("Invalid authorization header")

        id_token = parts[1]

        try:
            decoded = verify_firebase_token(id_token)
        except Exception:
            raise AuthenticationFailed("Invalid Firebase token")

        uid = decoded.get("uid")
        email = decoded.get("email")

        if not email:
            raise AuthenticationFailed("Token missing email")

        user, _ = User.objects.get_or_create(
            username=uid,
            defaults={"email": email},
        )

        return (user, decoded)