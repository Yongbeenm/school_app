from app import create_app
from waitress import serve
import os

app = create_app()

def ensure_instance_dir():
    # Ensure writable folder for SQLite DB
    data_dir = os.path.join(os.getcwd(), "data")
    os.makedirs(data_dir, exist_ok=True)
    # Optional: if your app reads INSTANCE_PATH from env
    os.environ.setdefault("INSTANCE_PATH", data_dir)

if __name__ == "__main__":
    ensure_instance_dir()
    serve(app, host="127.0.0.1", port=5001, threads=8)
