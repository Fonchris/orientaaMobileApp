"""
Django management command to seed Big Five personality questions into Firestore.

Usage: python manage.py seed_personality_questions

This seeds 16 IPIP-based Big Five questions with reverse-scored items.
"""
import firebase_admin
from firebase_admin import credentials, firestore
import os
import sys

# Add the parent directory to the path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')

from django.conf import settings  # noqa: E402

QUESTIONS = [
    # Openness (4 questions)
    {"text": "I have a vivid imagination.", "trait": "openness", "reverseScored": False, "order": 1},
    {"text": "I enjoy abstract ideas and philosophical discussions.", "trait": "openness", "reverseScored": False, "order": 2},
    {"text": "I appreciate art, beauty, and creative expression.", "trait": "openness", "reverseScored": False, "order": 3},
    {"text": "I prefer routine and familiar experiences over novelty.", "trait": "openness", "reverseScored": True, "order": 4},
    
    # Conscientiousness (4 questions)
    {"text": "I complete tasks thoroughly and on time.", "trait": "conscientiousness", "reverseScored": False, "order": 5},
    {"text": "I like order, regularity, and keeping things organized.", "trait": "conscientiousness", "reverseScored": False, "order": 6},
    {"text": "I often forget to put things back in their place.", "trait": "conscientiousness", "reverseScored": True, "order": 7},
    {"text": "I work hard to achieve my goals and meet deadlines.", "trait": "conscientiousness", "reverseScored": False, "order": 8},
    
    # Extraversion (3 questions)
    {"text": "I am the life of the party and enjoy social gatherings.", "trait": "extraversion", "reverseScored": False, "order": 9},
    {"text": "I enjoy being around people and feel energized by social interaction.", "trait": "extraversion", "reverseScored": False, "order": 10},
    {"text": "I prefer solitude and quiet environments over busy social settings.", "trait": "extraversion", "reverseScored": True, "order": 11},
    
    # Agreeableness (3 questions)
    {"text": "I sympathize with others' feelings and show compassion.", "trait": "agreeableness", "reverseScored": False, "order": 12},
    {"text": "I take time to help others even when I'm busy.", "trait": "agreeableness", "reverseScored": False, "order": 13},
    {"text": "I am not particularly interested in other people's problems.", "trait": "agreeableness", "reverseScored": True, "order": 14},
    
    # Neuroticism (3 questions)
    {"text": "I often feel stressed and overwhelmed by daily demands.", "trait": "neuroticism", "reverseScored": False, "order": 15},
    {"text": "I worry about things and tend to be anxious.", "trait": "neuroticism", "reverseScored": False, "order": 16},
]


def seed():
    """Seed the personality questions collection."""
    # Initialize Firebase if not already initialized
    try:
        firebase_admin.get_app()
    except ValueError:
        service_account = getattr(settings, 'FIREBASE_SERVICE_ACCOUNT_FILE', None)
        if service_account is None or not os.path.exists(str(service_account)):
            raise FileNotFoundError(
                f"Firebase service account file not found at: {service_account}\n"
                "Download it from Firebase Console > Project Settings > Service accounts "
                "> Generate new private key, and save it as 'firebase-service-account.json' "
                "inside the backend/ directory."
            )
        cred = credentials.Certificate(str(service_account))
        firebase_admin.initialize_app(cred)

    db = firestore.client()
    collection = db.collection('personalityQuestions')
    
    # Clear existing questions
    docs = collection.stream()
    for doc in docs:
        doc.reference.delete()
    
    # Add new questions
    for q in QUESTIONS:
        doc_ref = collection.document()
        doc_ref.set(q)
        print(f"Added question: {q['text'][:50]}...")
    
    print(f"\nSeeded {len(QUESTIONS)} personality questions successfully!")


if __name__ == '__main__':
    seed()