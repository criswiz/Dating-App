"""
Seed the dev database with dummy users for testing.
Run from the backend/ directory:
    python seed.py
"""
import sys
from app.db.database import SessionLocal
from app.services.user_service import create_user_with_profile, get_user_by_email

SEED_PASSWORD = "password123"

USERS = [
    {
        "email": "sophie.green@example.com",
        "name": "Sophie Green",
        "age": 26,
        "gender": "Woman",
        "intent": "Serious",
        "city": "London",
        "bio": "Bookworm, amateur baker, and obsessed with hiking trails. Looking for someone to explore the world with.",
        "interests": "Reading, Outdoors, Cooking, Travel",
    },
    {
        "email": "james.carter@example.com",
        "name": "James Carter",
        "age": 29,
        "gender": "Man",
        "intent": "Serious",
        "city": "Manchester",
        "bio": "Software engineer by day, jazz musician by night. Coffee snob. Will judge you if you say you like pineapple on pizza.",
        "interests": "Music, Tech, Food, Film",
    },
    {
        "email": "aisha.patel@example.com",
        "name": "Aisha Patel",
        "age": 24,
        "gender": "Woman",
        "intent": "Casual",
        "city": "Birmingham",
        "bio": "Yoga instructor who also loves CrossFit. Traveling whenever I can — 31 countries and counting!",
        "interests": "Fitness, Travel, Outdoors, Cooking",
    },
    {
        "email": "tom.harris@example.com",
        "name": "Tom Harris",
        "age": 31,
        "gender": "Man",
        "intent": "Friendship",
        "city": "London",
        "bio": "Documentary filmmaker with too many opinions about cheese. Big fan of long walks and longer dinners.",
        "interests": "Film, Food, Travel, Art",
    },
    {
        "email": "zoe.adams@example.com",
        "name": "Zoe Adams",
        "age": 27,
        "gender": "Woman",
        "intent": "Serious",
        "city": "Edinburgh",
        "bio": "Marine biologist and part-time mermaid. If you love the ocean as much as I do, we'll get along.",
        "interests": "Outdoors, Reading, Travel, Pets",
    },
    {
        "email": "alex.morgan@example.com",
        "name": "Alex Morgan",
        "age": 28,
        "gender": "Non-binary",
        "intent": "Casual",
        "city": "Bristol",
        "bio": "UX designer who paints on weekends. I make great playlists and even better pancakes.",
        "interests": "Art, Music, Cooking, Gaming",
    },
    {
        "email": "dan.nguyen@example.com",
        "name": "Dan Nguyen",
        "age": 33,
        "gender": "Man",
        "intent": "Serious",
        "city": "London",
        "bio": "Chef turned food writer. I'll cook for you on the third date — no exceptions.",
        "interests": "Cooking, Food, Travel, Reading",
    },
    {
        "email": "emma.white@example.com",
        "name": "Emma White",
        "age": 25,
        "gender": "Woman",
        "intent": "Casual",
        "city": "Leeds",
        "bio": "PhD student in astrophysics. Yes, I really do stare at stars for a living. Night owl by necessity.",
        "interests": "Reading, Film, Music, Tech",
    },
    {
        "email": "chris.walker@example.com",
        "name": "Chris Walker",
        "age": 30,
        "gender": "Man",
        "intent": "Friendship",
        "city": "London",
        "bio": "Personal trainer and avid rock climber. Always looking for a new challenge — in the gym or in life.",
        "interests": "Fitness, Outdoors, Travel, Gaming",
    },
    {
        "email": "priya.sharma@example.com",
        "name": "Priya Sharma",
        "age": 23,
        "gender": "Woman",
        "intent": "Serious",
        "city": "London",
        "bio": "Graphic designer with a love for street art and street food. Cat mum x2. Send me your best meme.",
        "interests": "Art, Food, Music, Pets",
    },
]


def seed():
    db = SessionLocal()
    created = 0
    skipped = 0

    try:
        for u in USERS:
            if get_user_by_email(db, u["email"]):
                print(f"  skip  {u['email']} (already exists)")
                skipped += 1
                continue
            create_user_with_profile(
                db,
                email=u["email"],
                password=SEED_PASSWORD,
                name=u["name"],
                age=u["age"],
                gender=u["gender"],
                intent=u["intent"],
                city=u["city"],
                bio=u["bio"],
                interests=u["interests"],
            )
            print(f"  added {u['email']}")
            created += 1
    finally:
        db.close()

    print(f"\nDone — {created} users created, {skipped} skipped.")
    print(f"All dummy accounts use password: {SEED_PASSWORD}")


if __name__ == "__main__":
    seed()
