"""Seed the Big Five personality questions into Firestore.

Standalone script — no Django required. Uses only the `firebase-admin` SDK.

The Flutter app reads this data at onboarding time (Step 5) from the
`personalityQuestions` collection and falls back to a bundled question catalog
when the collection is empty or unreachable, so this seeding is optional.

Usage:
    pip install firebase-admin
    python scripts/seed_personality_questions.py \
        --service-account path/to/firebase-service-account.json

Get the service-account file from:
Firebase Console > Project Settings > Service accounts > Generate new private key.
"""

import argparse
import os

import firebase_admin
from firebase_admin import credentials, firestore

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


def seed(service_account: str) -> None:
    """Seed the personality questions collection."""
    # Initialize Firebase if not already initialized
    try:
        firebase_admin.get_app()
    except ValueError:
        if not os.path.exists(service_account):
            raise FileNotFoundError(
                f"Firebase service account file not found at: {service_account}\n"
                "Download it from Firebase Console > Project Settings > Service "
                "accounts > Generate new private key."
            )
        cred = credentials.Certificate(service_account)
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
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        '--service-account',
        default='firebase-service-account.json',
        help='Path to the Firebase service account JSON '
             '(default: firebase-service-account.json)',
    )
    args = parser.parse_args()
    seed(args.service_account)
