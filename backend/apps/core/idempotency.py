from django.core.cache import cache

IDEMPOTENCY_TTL = 86400  # 24 hours in seconds

def get_idempotent_result(user_id: int, idempotency_key: str):
    """
    Checks if a request with this idempotency key was already processed.
    Returns (is_cached: bool, cached_data: dict | None).
    """
    if not idempotency_key:
        return False, None

    cache_key = f"idempotency:{user_id}:{idempotency_key.strip()}"
    cached_data = cache.get(cache_key)
    if cached_data is not None:
        return True, cached_data
    return False, None

def set_idempotent_result(user_id: int, idempotency_key: str, data: dict):
    """
    Stores the result of a processed request under its idempotency key.
    """
    if not idempotency_key:
        return
    cache_key = f"idempotency:{user_id}:{idempotency_key.strip()}"
    cache.set(cache_key, data, timeout=IDEMPOTENCY_TTL)
