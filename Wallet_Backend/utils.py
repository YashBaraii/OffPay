# utils.py
import os
import hashlib
import hmac
from aiosmtplib import send
from email.message import EmailMessage
from typing import Dict
import json
from dotenv import load_dotenv

load_dotenv()

SMTP_HOST = os.environ.get("SMTP_HOST")
SMTP_PORT = int(os.environ.get("SMTP_PORT", "587"))
SMTP_USER = os.environ.get("SMTP_USER")
SMTP_PASS = os.environ.get("SMTP_PASS")
FROM_EMAIL = os.environ.get("FROM_EMAIL", SMTP_USER)

HASH_SECRET = os.environ.get("HASH_SECRET", "replace-with-secure-secret")


def hash_security_code(code: str) -> str:
    # HMAC-SHA256 to prevent rainbow-table style attacks. Store hex digest.
    return hmac.new(HASH_SECRET.encode(), code.encode(), hashlib.sha256).hexdigest()


async def send_email_async(to_email: str, subject: str, body: str):
    if not SMTP_HOST:
        # Logging only in absence of SMTP (development)
        print("Email disabled: would send to", to_email, subject, body)
        return
    msg = EmailMessage()
    msg["From"] = FROM_EMAIL
    msg["To"] = to_email
    msg["Subject"] = subject
    msg.set_content(body)
    await send(
        msg,
        hostname=SMTP_HOST,
        port=SMTP_PORT,
        username=SMTP_USER,
        password=SMTP_PASS,
        start_tls=True,
    )
