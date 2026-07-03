import os
import time

import psycopg2
import psycopg2.extras
from flask import Flask, jsonify, request

app = Flask(__name__)

DB_CONFIG = {
    "host": os.environ.get("DB_HOST", "localhost"),
    "port": os.environ.get("DB_PORT", "5432"),
    "dbname": os.environ.get("DB_NAME", "helloworld"),
    "user": os.environ.get("DB_USER", "helloworld"),
    "password": os.environ.get("DB_PASSWORD", "helloworld"),
}


def get_connection(retries=5, delay=2):
    last_error = None
    for _ in range(retries):
        try:
            return psycopg2.connect(**DB_CONFIG)
        except psycopg2.OperationalError as exc:
            last_error = exc
            time.sleep(delay)
    raise last_error


def init_db():
    conn = get_connection()
    try:
        with conn, conn.cursor() as cur:
            cur.execute(
                """
                CREATE TABLE IF NOT EXISTS messages (
                    id SERIAL PRIMARY KEY,
                    text TEXT NOT NULL,
                    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
                )
                """
            )
    finally:
        conn.close()


_db_ready = False


def ensure_db():
    """Create the schema on first DB access.

    init_db() used to run only under ``if __name__ == "__main__"``, so under
    gunicorn (the container entrypoint) the table was never created and every
    /api/messages call 500'd. Doing it lazily here means it runs for every
    server type, and keeps the unit tests DB-free (they never reach a code
    path that touches the database).
    """
    global _db_ready
    if not _db_ready:
        init_db()
        _db_ready = True


@app.get("/health")
def health():
    return jsonify(status="ok"), 200


@app.get("/ready")
def ready():
    try:
        conn = get_connection(retries=1, delay=0)
        conn.close()
        return jsonify(status="ready"), 200
    except Exception as exc:  # noqa: BLE001
        return jsonify(status="not-ready", error=str(exc)), 503


@app.get("/api/hello")
def hello():
    return jsonify(message="Hello, World!", env=os.environ.get("APP_ENV", "local"))


@app.get("/api/messages")
def list_messages():
    ensure_db()
    conn = get_connection()
    try:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute("SELECT id, text, created_at FROM messages ORDER BY id DESC LIMIT 50")
            rows = cur.fetchall()
        return jsonify(messages=rows)
    finally:
        conn.close()


@app.post("/api/messages")
def create_message():
    payload = request.get_json(silent=True) or {}
    text = (payload.get("text") or "").strip()
    if not text:
        return jsonify(error="text is required"), 400

    ensure_db()
    conn = get_connection()
    try:
        with conn, conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(
                "INSERT INTO messages (text) VALUES (%s) RETURNING id, text, created_at",
                (text,),
            )
            row = cur.fetchone()
        return jsonify(message=row), 201
    finally:
        conn.close()


if __name__ == "__main__":
    init_db()
    app.run(host="0.0.0.0", port=5000)
