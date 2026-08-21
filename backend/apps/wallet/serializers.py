from rest_framework import serializers
from apps.wallet.models import Wallet, WalletTransaction

class WalletTransactionSerializer(serializers.ModelSerializer):
    class Meta:
        model = WalletTransaction
        fields = ('id', 'amount', 'balance_after', 'transaction_type', 'description', 'reference_id', 'created_at')
        read_only_fields = fields

class WalletSerializer(serializers.ModelSerializer):
    recent_transactions = serializers.SerializerMethodField()

    class Meta:
        model = Wallet
        fields = ('id', 'balance', 'updated_at', 'recent_transactions')
        read_only_fields = fields

    def get_recent_transactions(self, obj):
        txs = obj.transactions.all()[:10]
        return WalletTransactionSerializer(txs, many=True).data
