import hashlib
from datetime import timedelta
from django.utils import timezone
from django.db import models
from django.contrib.auth.models import User
from django.core.cache import cache

def hash_ip(ip_address: str) -> str:
    """Anonymizes and hashes IP addresses for secure fraud pattern matching."""
    if not ip_address:
        return ""
    return hashlib.sha256(ip_address.strip().encode('utf-8')).hexdigest()[:32]

class UserFraudProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='fraud_profile')
    fraud_score = models.FloatField(default=0.0, help_text="Calculated fraud score from 0.0 (clean) to 1.0 (malicious).")
    is_flagged = models.BooleanField(default=False, help_text="Flagged for manual admin audit.")
    flag_reason = models.CharField(max_length=255, blank=True)
    
    last_known_ip_hash = models.CharField(max_length=64, blank=True)
    suspicious_pings_count = models.IntegerField(default=0)
    total_pings_count = models.IntegerField(default=0)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "User Fraud Profile"
        verbose_name_plural = "User Fraud Profiles"

    def __str__(self):
        return f"{self.user.username} | Fraud Score: {self.fraud_score:.2f} | Flagged: {self.is_flagged}"

def evaluate_fraud_signal(user, delta_seconds: float, request_ip: str = None) -> float:
    """
    Evaluates anti-fraud heuristics on each incoming progress ping.
    Updates UserFraudProfile and returns the updated score.
    """
    profile, _ = UserFraudProfile.objects.get_or_create(user=user)
    profile.total_pings_count += 1
    
    suspicion_detected = False
    reasons = []

    # Heuristic 1: Consistent pegging at max delta (15s) with 0 current_time increase
    if delta_seconds >= 14.9:
        profile.suspicious_pings_count += 1
        suspicion_detected = True

    # Heuristic 2: IP collision checking
    if request_ip:
        ip_hash = hash_ip(request_ip)
        profile.last_known_ip_hash = ip_hash
        
        # Check how many distinct users shared this IP hash today
        cache_key = f"ip_users:{ip_hash}"
        user_ids = cache.get(cache_key, set())
        if not isinstance(user_ids, set):
            user_ids = set()
        user_ids.add(user.id)
        cache.set(cache_key, user_ids, timeout=86400)

        if len(user_ids) > 4:
            reasons.append(f"High multi-account density on same IP ({len(user_ids)} users)")
            profile.fraud_score = min(1.0, profile.fraud_score + 0.25)

    # Calculate base ratio score
    if profile.total_pings_count > 10:
        ratio = profile.suspicious_pings_count / profile.total_pings_count
        profile.fraud_score = round(min(1.0, max(profile.fraud_score, ratio)), 2)

    # Flag threshold
    if profile.fraud_score >= 0.70:
        profile.is_flagged = True
        profile.flag_reason = "; ".join(reasons) or "High frequency anomaly score"

    profile.save()
    return profile.fraud_score
