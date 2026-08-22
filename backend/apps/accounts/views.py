from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework_simplejwt.tokens import RefreshToken, OutstandingToken, BlacklistedToken
from apps.accounts.serializers import RegisterSerializer, LoginSerializer, UserSerializer
from apps.core.throttling import LoginRateThrottle, RegisterRateThrottle

class RegisterView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [RegisterRateThrottle]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            refresh = RefreshToken.for_user(user)
            return Response({
                'message': 'User registered successfully',
                'user': UserSerializer(user).data,
                'tokens': {
                    'refresh': str(refresh),
                    'access': str(refresh.access_token),
                }
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class LoginView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [LoginRateThrottle]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        if serializer.is_valid():
            data = serializer.validated_data
            return Response({
                'message': 'Login successful',
                'user': UserSerializer(data['user']).data,
                'tokens': data['tokens']
            }, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class MeView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        serializer = UserSerializer(request.user)
        return Response(serializer.data, status=status.HTTP_200_OK)

class LogoutAllView(APIView):
    """
    FIX-05: Session management endpoint to revoke and blacklist all outstanding tokens for a user.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        tokens = OutstandingToken.objects.filter(user=request.user)
        count = 0
        for token in tokens:
            _, created = BlacklistedToken.objects.get_or_create(token=token)
            if created:
                count += 1
        return Response({
            'message': f'Successfully logged out from all devices. {count} active session(s) revoked.',
            'revoked_count': count
        }, status=status.HTTP_200_OK)
