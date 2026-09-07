import os
from datetime import datetime
from functools import wraps

from dotenv import load_dotenv
from flask import (
    Flask, render_template, request,
    redirect, url_for, session, flash
)
from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import check_password_hash, generate_password_hash

load_dotenv()

app = Flask(name)
app.config["SECRET_KEY"] = os.getenv("SECRET_KEY", "change-this-secret")
app.config["SQLALCHEMY_DATABASE_URI"] = os.getenv(
    "DATABASE_URL",
    "sqlite:///shir_khorshid.db"
)
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
CMD ["sh", "-c", "gunicorn --bind

db = SQLAlchemy(app)


class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(120), nullable=False)
    email = db.Column(db.String(180), unique=True, nullable=False)
    status = db.Column(db.String(30), default="فعال")
    created_at = db.Column(db.DateTime, default=datetime.utcnow)


def login_required(view):
    @wraps(view)
    def wrapped(*args, **kwargs):
        if not session.get("admin_logged_in"):
            return redirect(url_for("login"))
        return view(*args, **kwargs)

    return wrapped


@app.cli.command("init-db")
def init_db():
    db.create_all()
    print("Database initialized.")


@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        username = request.form.get("username", "")
        password = request.form.get("password", "")

        admin_user = os.getenv("ADMIN_USERNAME", "admin")
        admin_password = os.getenv("ADMIN_PASSWORD", "change-me")

        if username == admin_user and password == admin_password:
            session["admin_logged_in"] = True
            return redirect(url_for("dashboard"))

        flash("نام کاربری یا رمز عبور اشتباه است.", "error")

    return render_template("login.html")


@app.get("/logout")
def logout():
    session.clear()
    return redirect(url_for("login"))


@app.get("/")
@login_required
def dashboard():
    total_users = User.query.count()
    active_users = User.query.filter_by(status="فعال").count()

    return render_template(
        "dashboard.html",
        total_users=total_users,
        active_users=active_users
    )


@app.route("/users", methods=["GET", "POST"])
@login_required
def users():
    if request.method == "POST":
        name = request.form.get("name", "").strip()
        email = request.form.get("email", "").strip()

        if not name or not email:
            flash("تمام فیلدها را تکمیل کنید.", "error")
        elif User.query.filter_by(email=email).first():
            flash("این ایمیل قبلاً ثبت شده است.", "error")
        else:
            db.session.add(User(name=name, email=email))
            db.session.commit()
            flash("کاربر با موفقیت اضافه شد.", "success")

        return redirect(url_for("users"))

    all_users = User.query.order_by(User.id.desc()).all()
    return render_template("users.html", users=all_users)


@app.post("/users/<int:user_id>/toggle")
@login_required
def toggle_user(user_id):
    user = User.query.get_or_404(user_id)
    user.status = "غیرفعال" if user.status == "فعال" else "فعال"
    db.session.commit()
    return redirect(url_for("users"))


@app.post("/users/<int:user_id>/delete")
@login_required
def delete_user(user_id):
    user = User.query.get_or_404(user_id)
    db.session.delete(user)
    db.session.commit()
    flash("کاربر حذف شد.", "success")
    return redirect(url_for("users"))


@app.get("/settings")
@login_required
def settings():
    return render_template("settings.html")


@app.get("/health")
def health():
    return {"status": "ok", "service": "Shir o Khorshid Panel"}


with app.app_context():
    db.create_all()


if name == "main":
    port = int(os.getenv("PORT", "8000"))
    app.run(host="0.0.0.0", port=port)
