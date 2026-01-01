import argparse
from app import create_app
from app.extensions import db
from app.services.seed_service import create_admin

app = create_app()

def cmd_create_db():
    with app.app_context():
        db.create_all()
        print("Database tables created.")

def cmd_seed(admin_user: str, admin_pass: str):
    with app.app_context():
        db.create_all()
        created = create_admin(admin_user, admin_pass)
        if created:
            print(f"Seeded roles and admin user '{admin_user}'.")
        else:
            print(f"Admin user '{admin_user}' already exists.")

def cmd_run(host: str, port: int, debug: bool):
    app.run(host=host, port=port, debug=debug)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("create-db", help="Create database tables (create_all)")

    p_seed = sub.add_parser("seed", help="Seed roles and create an admin user")
    p_seed.add_argument("--admin-user", default="admin")
    p_seed.add_argument("--admin-pass", default="admin123")

    p_run = sub.add_parser("run", help="Run the development server")
    p_run.add_argument("--host", default="127.0.0.1")
    p_run.add_argument("--port", type=int, default=5000)
    p_run.add_argument("--debug", action="store_true", default=True)

    args = parser.parse_args()
    if args.command == "create-db":
        cmd_create_db()
    elif args.command == "seed":
        cmd_seed(args.admin_user, args.admin_pass)
    elif args.command == "run":
        cmd_run(args.host, args.port, args.debug)
