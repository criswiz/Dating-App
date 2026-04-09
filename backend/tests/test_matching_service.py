from types import SimpleNamespace

from app.services.matching import compatibility_score


def test_compatibility_score_prefers_shared_interests_and_intent():
    current = SimpleNamespace(interests="music,travel,books", intent="serious")
    strong = SimpleNamespace(
        name="Sam",
        bio="Bio",
        age=29,
        city="Nairobi",
        interests="music,books",
        intent="serious",
        last_active_at=True,
    )
    weak = SimpleNamespace(
        name="Pat",
        bio=None,
        age=None,
        city=None,
        interests="sports",
        intent="casual",
        last_active_at=None,
    )

    assert compatibility_score(current, strong) > compatibility_score(current, weak)
