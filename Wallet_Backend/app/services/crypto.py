# AES encryption
from cryptography.fernet import Fernet


def encrypt_data(key: bytes, data: str) -> str:
    f = Fernet(key)
    return f.encrypt(data.encode()).decode()


def decrypt_data(key: bytes, token: str) -> str:
    f = Fernet(key)
    return f.decrypt(token.encode()).decode()


# ECDSA/RSA token signing
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives import hashes, serialization


def generate_keys():
    private_key = ec.generate_private_key(ec.SECP256R1())
    public_key = private_key.public_key()
    return private_key, public_key


def sign_token(private_key, token_data: str) -> bytes:
    return private_key.sign(token_data.encode(), ec.ECDSA(hashes.SHA256()))
