import firebase_admin
from firebase_admin import auth, credentials
from django.conf import settings


def initialize_firebase():
    if not firebase_admin._apps:
        cred = credentials.Certificate(str(settings.FIREBASE_SERVICE_ACCOUNT_FILE))
        firebase_admin.initialize_app(cred)


def verify_firebase_token(id_token):
    initialize_firebase()
    return auth.verify_id_token(id_token)