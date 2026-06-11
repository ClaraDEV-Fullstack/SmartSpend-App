# users/views.py

from django.conf import settings
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.views import APIView
from drf_yasg.utils import swagger_auto_schema
from drf_yasg import openapi
from .serializers import (
    RegisterSerializer,
    LoginSerializer,
    UserSerializer,
    DeleteAccountSerializer,
)
from django.contrib.auth import get_user_model
from categories.models import Category
from google.oauth2 import id_token
from google.auth.transport import requests as google_requests
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.exceptions import TokenError

User = get_user_model()

DEFAULT_CATEGORIES = [
    {'name': 'Food', 'type': 'expense', 'color': '#FF6B6B', 'icon': 'fastfood'},
    {'name': 'Transport', 'type': 'expense', 'color': '#4ECDC4', 'icon': 'directions_car'},
    {'name': 'Salary', 'type': 'income', 'color': '#45B7D1', 'icon': 'attach_money'},
    {'name': 'Utilities', 'type': 'expense', 'color': '#96CEB4', 'icon': 'bolt'},
    {'name': 'Entertainment', 'type': 'expense', 'color': '#FFEAA7', 'icon': 'movie'},
]


def create_default_categories(user):
    for cat_data in DEFAULT_CATEGORIES:
        Category.objects.create(user=user, **cat_data)


def verify_google_id_token(token_value):
    if not token_value:
        return None

    client_id = getattr(settings, 'GOOGLE_CLIENT_ID', None)
    if not client_id:
        return None

    try:
        return id_token.verify_oauth2_token(
            token_value,
            google_requests.Request(),
            client_id,
        )
    except ValueError:
        return None


@swagger_auto_schema(method='post', request_body=RegisterSerializer)
@api_view(['POST'])
@permission_classes([AllowAny])
def register_user(request):
    serializer = RegisterSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.save()
        create_default_categories(user)

        return Response({
            'message': 'User registered successfully',
            'user': UserSerializer(user, context={'request': request}).data
        }, status=status.HTTP_201_CREATED)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@swagger_auto_schema(method='post', request_body=LoginSerializer)
@api_view(['POST'])
@permission_classes([AllowAny])
def login_user(request):
    serializer = LoginSerializer(data=request.data, context={'request': request})
    if serializer.is_valid():
        tokens = serializer.create(serializer.validated_data)
        return Response(tokens, status=status.HTTP_200_OK)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([AllowAny])
def google_login(request):
    """Handle Google Sign-In from mobile app."""
    try:
        google_token = request.data.get('id_token')
        email = request.data.get('email')
        display_name = request.data.get('display_name', '')
        photo_url = request.data.get('photo_url', '')

        token_info = verify_google_id_token(google_token)
        if token_info:
            email = token_info.get('email')
            if not email:
                return Response(
                    {'detail': 'Google token did not include an email address.'},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            if not token_info.get('email_verified', False):
                return Response(
                    {'detail': 'Google email address is not verified.'},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            display_name = token_info.get('name', display_name)
            photo_url = token_info.get('picture', photo_url)
        elif getattr(settings, 'GOOGLE_CLIENT_ID', None):
            return Response(
                {'detail': 'Invalid Google ID token.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        elif not email:
            return Response(
                {'detail': 'Email is required'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user, created = User.objects.get_or_create(
            email=email,
            defaults={
                'username': email.split('@')[0],
                'first_name': display_name.split()[0] if display_name else '',
                'last_name': ' '.join(display_name.split()[1:]) if display_name else '',
                'is_active': True,
            }
        )

        if created:
            create_default_categories(user)
            user.set_unusable_password()
            user.save()

        if photo_url and hasattr(user, 'profile_image_url'):
            user.profile_image_url = photo_url
            user.save()

        refresh = RefreshToken.for_user(user)

        return Response({
            'access': str(refresh.access_token),
            'refresh': str(refresh),
            'user': {
                'id': user.id,
                'email': user.email,
                'username': user.username,
                'first_name': user.first_name,
                'last_name': user.last_name,
            },
            'created': created,
        })

    except Exception as e:
        print(f"Google login error: {str(e)}")
        return Response(
            {'detail': str(e)},
            status=status.HTTP_400_BAD_REQUEST
        )


@swagger_auto_schema(method='get', responses={200: UserSerializer})
@swagger_auto_schema(method='put', request_body=UserSerializer)
@swagger_auto_schema(method='patch', request_body=UserSerializer)
@api_view(['GET', 'PUT', 'PATCH'])
@permission_classes([IsAuthenticated])
def user_profile(request):
    user = request.user
    if request.method == 'GET':
        serializer = UserSerializer(user, context={'request': request})
        return Response(serializer.data)

    serializer = UserSerializer(
        user,
        data=request.data,
        partial=True,
        context={'request': request},
    )
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@swagger_auto_schema(method='post', request_body=DeleteAccountSerializer)
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def delete_account(request):
    serializer = DeleteAccountSerializer(data=request.data, context={'request': request})
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    refresh_token = request.data.get('refresh')
    if refresh_token:
        try:
            RefreshToken(refresh_token).blacklist()
        except TokenError:
            pass

    request.user.delete()

    return Response(
        {'message': 'Account deleted successfully.'},
        status=status.HTTP_200_OK,
    )


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout_user(request):
    refresh_token = request.data.get('refresh')
    if refresh_token:
        try:
            token = RefreshToken(refresh_token)
            token.blacklist()
        except TokenError:
            pass

    return Response(
        {'message': 'Logged out successfully.'},
        status=status.HTTP_200_OK,
    )


class ProfileImageView(APIView):
    """Handle profile image upload and deletion."""
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    @swagger_auto_schema(
        operation_description="Upload a profile image",
        manual_parameters=[
            openapi.Parameter(
                'profile_image',
                openapi.IN_FORM,
                type=openapi.TYPE_FILE,
                required=True,
                description='Profile image file'
            )
        ],
        responses={200: "Image uploaded successfully"}
    )
    def post(self, request):
        profile_image = request.FILES.get('profile_image')

        if not profile_image:
            return Response(
                {'detail': 'No image provided'},
                status=status.HTTP_400_BAD_REQUEST
            )

        user = request.user

        if user.profile_image:
            user.profile_image.delete(save=False)

        user.profile_image = profile_image
        user.save()

        image_url = None
        if user.profile_image:
            image_url = request.build_absolute_uri(user.profile_image.url)

        return Response({
            'message': 'Profile image uploaded successfully',
            'profile_image_url': image_url
        }, status=status.HTTP_200_OK)

    @swagger_auto_schema(
        operation_description="Delete profile image",
        responses={204: "Image deleted successfully"}
    )
    def delete(self, request):
        user = request.user

        if user.profile_image:
            user.profile_image.delete(save=False)
            user.profile_image = None
            user.save()
            return Response(
                {'message': 'Profile image deleted successfully'},
                status=status.HTTP_204_NO_CONTENT
            )

        return Response(
            {'detail': 'No profile image to delete'},
            status=status.HTTP_404_NOT_FOUND
        )
