from django.urls import path
from apps.wallet.views import WalletView, WalletTransactionsView

urlpatterns = [
    path('', WalletView.as_view(), name='wallet_detail'),
    path('transactions/', WalletTransactionsView.as_view(), name='wallet_transactions'),
]
