from django.contrib.auth.models import User
from django.contrib.auth import authenticate
from rest_framework import serializers
from rest_framework_simplejwt.tokens import RefreshToken
from apps.wallet.models import Wallet

class UserSerializer(serializers.ModelSerializer):
    wallet_balance = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'first_name', 'last_name', 'date_joined', 'wallet_balance')
        read_only_fields = ('id', 'date_joined', 'wallet_balance')

    def get_wallet_balance(self, obj):
        try:
            return float(obj.wallet.balance)
        except Exception:
            return 0.0

class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=6)
    email = serializers.EmailField(required=True)

    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'password')

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
        username = attrs.get('username')
        password = attrs.get('password')

        if username and password:
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
                raise serializers.ValidationError("Invalid username/email or password.")
            if not user.is_active:
                raise serializers.ValidationError("User account is disabled.")

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
        raise serializers.ValidationError("Must provide both username and password.")
