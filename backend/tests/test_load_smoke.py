from time import perf_counter

from conftest import auth_headers


def test_auth_and_discover_smoke_load(client):
    main_headers = auth_headers(
        client,
        "loadmain@example.com",
        "pw123456",
        name="Load Main",
        intent="serious",
        interests="music,travel",
    )
    # Seed candidate pool.
    for i in range(1, 11):
        auth_headers(
            client,
            f"load{i}@example.com",
            "pw123456",
            name=f"Load User {i}",
            intent="serious",
            interests="music",
        )

    start = perf_counter()
    for _ in range(50):
        res = client.post("/auth/login", json={"email": "loadmain@example.com", "password": "pw123456"})
        assert res.status_code == 200
    auth_elapsed = perf_counter() - start

    start = perf_counter()
    for _ in range(50):
        res = client.get("/profiles/discover?intent=serious", headers=main_headers)
        assert res.status_code == 200
    discover_elapsed = perf_counter() - start

    # Non-strict local thresholds to catch severe regressions while avoiding CI/mac variance.
    assert auth_elapsed < 20
    assert discover_elapsed < 20
