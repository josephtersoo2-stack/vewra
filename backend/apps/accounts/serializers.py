import re
from django.contrib.auth.models import User
from django.contrib.auth import authenticate
from django.core.cache import cache
from rest_framework import serializers
from rest_framework_simplejwt.tokens import RefreshToken
from apps.wallet.models import Wallet

class UserSerializer(serializers.ModelSerializer):
    wallet_balance = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'first_name', 'last_name', 'is_staff', 'is_superuser', 'date_joined', 'wallet_balance')
        read_only_fields = ('id', 'is_staff', 'is_superuser', 'date_joined', 'wallet_balance')

    def get_wallet_balance(self, obj):
        try:
            return float(obj.wallet.balance)
        except Exception:
            return 0.0

class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8)
    email = serializers.EmailField(required=True)

    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'password')

    def validate_password(self, value):
        # FIX-05: Password strength policy: min 8 chars, must include letter + number
        if len(value) < 8:
            raise serializers.ValidationError("Password must be at least 8 characters long.")
        if not re.search(r"[a-zA-Z]", value):
            raise serializers.ValidationError("Password must contain at least one letter.")
        if not re.search(r"\d", value):
            raise serializers.ValidationError("Password must contain at least one number.")
        return value

    def validate_email(self, value):
        if User.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError("A user with this email already exists.")
        return value.lower()

    def validate_username(self, value):
        if User.objects.filter(username__iexact=value).exists():
            raise serializers.ValidationError("A user with this username already exists.")
        return value

    def create(self, validated_data):
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data['email'],
            password=validated_data['password']
        )
        # Ensure wallet is created
        Wallet.objects.get_or_create(user=user)
        return user

class LoginSerializer(serializers.Serializer):
    username = serializers.CharField()
    password = serializers.CharField(write_only=True)

    def validate(self, attrs):
        username = attrs.get('username', '').strip()
        password = attrs.get('password', '')

        if not username or not password:
            raise serializers.ValidationError("Must provide both username and password.")

        lockout_key = f"auth_lockout:{username.lower()}"
        failed_count = cache.get(lockout_key, 0)
        if failed_count >= 5:
            raise serializers.ValidationError("Account temporarily locked due to multiple failed login attempts. Please wait 15 minutes.")

        # Support login with either username or email
        user = None
        if '@' in username:
            try:
                user_obj = User.objects.get(email__iexact=username)
                user = authenticate(username=user_obj.username, password=password)
            except User.DoesNotExist:
                pass
        if not user:
            user = authenticate(username=username, password=password)

        if not user:
            new_failed = failed_count + 1
            cache.set(lockout_key, new_failed, timeout=900)  # 15 minutes cooldown
            remaining = max(0, 5 - new_failed)
            if remaining == 0:
                raise serializers.ValidationError("Account temporarily locked due to 5 failed login attempts. Please wait 15 minutes.")
            raise serializers.ValidationError(f"Invalid credentials. ({remaining} attempt(s) remaining before lockout)")

        if not user.is_active:
            raise serializers.ValidationError("User account is disabled.")

        # Clear lockout counter on successful auth
        cache.delete(lockout_key)

        # Ensure wallet exists
        Wallet.objects.get_or_create(user=user)

        refresh = RefreshToken.for_user(user)
        return {
            'user': user,
            'tokens': {
                'refresh': str(refresh),
                'access': str(refresh.access_token),
            }
        }
