from django.db import models
from django.contrib.auth.models import User

class Wallet(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='wallet')
    balance = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    created_at = models.DateTimeField(auto_now_add=True, null=True, blank=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.user.username}'s Wallet ({self.balance} coins)"

class WalletTransaction(models.Model):
    wallet = models.ForeignKey(Wallet, on_delete=models.CASCADE, related_name='transactions')
    amount = models.DecimalField(max_digits=12, decimal_places=2)   # positive = earn
    balance_after = models.DecimalField(max_digits=12, decimal_places=2)
    transaction_type = models.CharField(max_length=30, default='watch_reward', db_index=True)
    description = models.CharField(max_length=255)
    reference_id = models.CharField(max_length=50, blank=True)     # e.g. session id
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['created_at']),
            models.Index(fields=['transaction_type']),
            models.Index(fields=['wallet', 'created_at']),
        ]

    def __str__(self):
        return f"{self.wallet.user.username} | {self.amount:+f} coins | {self.transaction_type}"

# Signals to auto-create Wallet on User creation
from django.db.models.signals import post_save
from django.dispatch import receiver

@receiver(post_save, sender=User)
def create_user_wallet(sender, instance, created, **kwargs):
    if created:
        Wallet.objects.get_or_create(user=instance)

