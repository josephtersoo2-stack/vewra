import os
import base64
import hashlib
from cryptography.fernet import Fernet
from django.conf import settings

def _get_fernet_key() -> bytes:
    raw_key = getattr(settings, 'VAULT_ENCRYPTION_KEY', None) or getattr(settings, 'SECRET_KEY', 'vewra-default-vault-key-2026')
    # Derive a valid 32-byte urlsafe base64 key
    key_hash = hashlib.sha256(raw_key.encode('utf-8')).digest()
    return base64.urlsafe_b64encode(key_hash)

def encrypt_secret(plaintext: str) -> str:
    """
    Encrypts a plaintext secret (e.g. API key) using Fernet.
    Returns ciphertext prefixed with 'enc:' so we can detect encrypted values.
    """
    if not plaintext:
        return ""
    if plaintext.startswith("enc:"):
        return plaintext  # Already encrypted
    
    f = Fernet(_get_fernet_key())
    encrypted = f.encrypt(plaintext.encode('utf-8')).decode('utf-8')
    return f"enc:{encrypted}"

def decrypt_secret(ciphertext: str) -> str:
    """
    Decrypts an 'enc:' ciphertext back to plaintext.
    If the string is not encrypted (does not start with 'enc:'), returns as is.
    """
    if not ciphertext:
        return ""
    if not ciphertext.startswith("enc:"):
        return ciphertext  # Raw plaintext fallback
    
    raw_cipher = ciphertext[4:]
    try:
        f = Fernet(_get_fernet_key())
        return f.decrypt(raw_cipher.encode('utf-8')).decode('utf-8')
    except Exception:
        return ciphertext
