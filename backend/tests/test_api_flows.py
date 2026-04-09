from conftest import auth_headers


def test_signup_login_and_profile_me(client):
    signup = client.post(
        "/auth/signup",
        json={
            "email": "u1@example.com",
            "password": "secret123",
            "name": "User One",
            "intent": "serious",
            "interests": "music,travel",
        },
    )
    assert signup.status_code == 200
    login = client.post("/auth/login", json={"email": "u1@example.com", "password": "secret123"})
    assert login.status_code == 200
    token = login.json()["access_token"]
    me = client.get("/profiles/me", headers={"Authorization": f"Bearer {token}"})
    assert me.status_code == 200
    assert me.json()["email"] == "u1@example.com"


def test_discover_scoring_and_filters(client):
    h1 = auth_headers(
        client,
        "alice@example.com",
        "pw123456",
        name="Alice",
        age=28,
        intent="serious",
        interests="music,travel,books",
    )
    auth_headers(
        client,
        "bob@example.com",
        "pw123456",
        name="Bob",
        age=30,
        intent="serious",
        interests="music,travel",
    )
    auth_headers(
        client,
        "carl@example.com",
        "pw123456",
        name="Carl",
        age=31,
        intent="casual",
        interests="gaming",
    )
    discover = client.get("/profiles/discover?intent=serious", headers=h1)
    assert discover.status_code == 200
    data = discover.json()
    assert len(data) >= 1
    assert data[0]["email"] == "bob@example.com"
    assert data[0]["score"] >= data[-1]["score"]


def test_like_creates_match_and_chat_flow(client):
    h1 = auth_headers(client, "a@example.com", "pw123456", name="A", interests="music")
    h2 = auth_headers(client, "b@example.com", "pw123456", name="B", interests="music")

    first_like = client.post("/matches/like", json={"target_user_id": 2}, headers=h1)
    assert first_like.status_code == 200
    assert first_like.json()["matched"] is False

    second_like = client.post("/matches/like", json={"target_user_id": 1}, headers=h2)
    assert second_like.status_code == 200
    assert second_like.json()["matched"] is True
    match_id = second_like.json()["match_id"]
    assert isinstance(match_id, int)

    my_matches = client.get("/matches/", headers=h1)
    assert my_matches.status_code == 200
    assert len(my_matches.json()) == 1

    threads = client.get("/chat/threads", headers=h1)
    assert threads.status_code == 200
    assert len(threads.json()) == 1
    thread_id = threads.json()[0]["id"]

    send = client.post(
        f"/chat/threads/{thread_id}/messages",
        json={"content": "Hey there"},
        headers=h1,
    )
    assert send.status_code == 200
    messages = client.get(f"/chat/threads/{thread_id}/messages", headers=h2)
    assert messages.status_code == 200
    assert messages.json()[0]["content"] == "Hey there"


def test_block_and_report_flow(client):
    h1 = auth_headers(client, "safe1@example.com", "pw123456")
    h2 = auth_headers(client, "safe2@example.com", "pw123456")
    admin_headers = auth_headers(client, "ops@admin.com", "pw123456", role="admin")

    block = client.post("/safety/block", json={"blocked_user_id": 2, "reason": "abuse"}, headers=h1)
    assert block.status_code == 200
    like_blocked = client.post("/matches/like", json={"target_user_id": 2}, headers=h1)
    assert like_blocked.status_code == 403

    report = client.post(
        "/safety/report",
        json={"reported_user_id": 2, "reason": "spam messages"},
        headers=h1,
    )
    assert report.status_code == 200

    queue = client.get("/safety/moderation/queue", headers=admin_headers)
    assert queue.status_code == 200
    assert len(queue.json()) == 1

    non_admin_queue = client.get("/safety/moderation/queue", headers=h2)
    assert non_admin_queue.status_code == 403

    verify = client.post("/safety/verify/2", headers=admin_headers)
    assert verify.status_code == 200


def test_ai_readiness_endpoint(client):
    readiness = client.get(
        "/ai/readiness?monthly_revenue=1500&training_events=9000&conversion_plateaued=true"
    )
    assert readiness.status_code == 200
    assert readiness.json()["ready"] is False
    status = client.get(
        "/ai/features/status?monthly_revenue=999999&training_events=999999&conversion_plateaued=true"
    )
    assert status.status_code == 200
    assert status.json()["enabled"] is False


def test_interaction_rate_limit(client):
    h1 = auth_headers(client, "rate1@example.com", "pw123456")
    auth_headers(client, "rate2@example.com", "pw123456")
    last_code = 200
    for _ in range(65):
        res = client.post("/matches/pass", json={"target_user_id": 2}, headers=h1)
        last_code = res.status_code
    assert last_code == 429
