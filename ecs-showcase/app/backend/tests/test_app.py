import app as app_module


def test_health():
    client = app_module.app.test_client()
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.get_json() == {"status": "ok"}


def test_hello():
    client = app_module.app.test_client()
    resp = client.get("/api/hello")
    assert resp.status_code == 200
    body = resp.get_json()
    assert body["message"] == "Hello, World!"
    assert body["platform"] == "ecs-fargate"


def test_create_message_requires_text():
    client = app_module.app.test_client()
    resp = client.post("/api/messages", json={})
    assert resp.status_code == 400
