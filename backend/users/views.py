# users/views.py

from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.views import APIView
from drf_yasg.utils import swagger_auto_schema
from drf_yasg import openapi
from .serializers import RegisterSerializer, LoginSerializer, UserSerializer
from django.contrib.auth import get_user_model
User = get_user_model()
from categories.models import Category

# views.py
from google.oauth2 import id_token
from google.auth.transport import requests
from rest_framework_simplejwt.tokens import RefreshToken



# --------------------------
# User Registration API
# --------------------------
@swagger_auto_schema(method='post', request_body=RegisterSerializer)
@api_view(['POST'])
@permission_classes([AllowAny])
def register_user(request):
    serializer = RegisterSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.save()

        # Create default categories for this user
        default_categories = [
            {'name': 'Food', 'type': 'expense', 'color': '#FF6B6B', 'icon': 'fastfood'},
            {'name': 'Transport', 'type': 'expense', 'color': '#4ECDC4', 'icon': 'directions_car'},
            {'name': 'Salary', 'type': 'income', 'color': '#45B7D1', 'icon': 'attach_money'},
            {'name': 'Utilities', 'type': 'expense', 'color': '#96CEB4', 'icon': 'bolt'},
            {'name': 'Entertainment', 'type': 'expense', 'color': '#FFEAA7', 'icon': 'movie'},
        ]
        for cat_data in default_categories:
            Category.objects.create(user=user, **cat_data)

        return Response({
            'message': 'User registered successfully',
            'user': UserSerializer(user, context={'request': request}).data  # ✅ Pass context
        }, status=status.HTTP_201_CREATED)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# --------------------------
# User Login API
# --------------------------
@swagger_auto_schema(method='post', request_body=LoginSerializer)
@api_view(['POST'])
@permission_classes([AllowAny])
def login_user(request):
    serializer = LoginSerializer(data=request.data, context={'request': request})  # ✅ Pass context
    if serializer.is_valid():
        tokens = serializer.create(serializer.validated_data)
        return Response(tokens, status=status.HTTP_200_OK)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)



@api_view(['POST'])
@permission_classes([AllowAny])
def google_login(request):
    """Handle Google Sign-In from mobile app"""
    try:
        google_token = request.data.get('id_token')
        email = request.data.get('email')
        display_name = request.data.get('display_name', '')
        photo_url = request.data.get('photo_url', '')

        if not email:
            return Response(
                {'detail': 'Email is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Get or create user
        user, created = User.objects.get_or_create(
            email=email,
            defaults={
                'username': email.split('@')[0],
                'first_name': display_name.split()[0] if display_name else '',
                'last_name': ' '.join(display_name.split()[1:]) if display_name else '',
                'is_active': True,
            }
        )

        # ✅ Create default categories for NEW Google users
        if created:
            default_categories = [
                {'name': 'Food', 'type': 'expense', 'color': '#FF6B6B', 'icon': 'fastfood'},
                {'name': 'Transport', 'type': 'expense', 'color': '#4ECDC4', 'icon': 'directions_car'},
                {'name': 'Salary', 'type': 'income', 'color': '#45B7D1', 'icon': 'attach_money'},
                {'name': 'Utilities', 'type': 'expense', 'color': '#96CEB4', 'icon': 'bolt'},
                {'name': 'Entertainment', 'type': 'expense', 'color': '#FFEAA7', 'icon': 'movie'},
            ]
            for cat_data in default_categories:
                Category.objects.create(user=user, **cat_data)

            # Set unusable password for Google users
            user.set_unusable_password()
            user.save()

        # Update profile image if available
        if photo_url and hasattr(user, 'profile_image_url'):
            user.profile_image_url = photo_url
            user.save()

        # Generate JWT tokens
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
            'created': created,  # ✅ Let frontend know if new user
        })

    except Exception as e:
        print(f"Google login error: {str(e)}")  # Debug log
        return Response(
            {'detail': str(e)},
            status=status.HTTP_400_BAD_REQUEST
        )


# --------------------------
# User Profile API
# --------------------------
@swagger_auto_schema(method='get', responses={200: UserSerializer})
@swagger_auto_schema(method='put', request_body=UserSerializer)
@api_view(['GET', 'PUT'])
@permission_classes([IsAuthenticated])
def user_profile(request):
    user = request.user
    if request.method == 'GET':
        serializer = UserSerializer(user, context={'request': request})  # ✅ Pass context
        print(f"Profile data: {serializer.data}")  # Debug log
        return Response(serializer.data)
    elif request.method == 'PUT':
        serializer = UserSerializer(user, data=request.data, partial=True, context={'request': request})
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# --------------------------
# Profile Image Upload API
# --------------------------
class ProfileImageView(APIView):
    """Handle profile image upload and deletion"""
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
        """Upload profile image"""
        profile_image = request.FILES.get('profile_image')

        if not profile_image:
            return Response(
                {'detail': 'No image provided'},
                status=status.HTTP_400_BAD_REQUEST
            )

        user = request.user

        print(f"Uploading image for user: {user.email}")  # Debug log
        print(f"Image file: {profile_image.name}, size: {profile_image.size}")  # Debug log

        # Delete old image if exists
        if user.profile_image:
            print(f"Deleting old image: {user.profile_image.url}")  # Debug log
            user.profile_image.delete(save=False)

        # Save new image
        user.profile_image = profile_image
        user.save()

        # Build absolute URL for the image
        image_url = None
        if user.profile_image:
            image_url = request.build_absolute_uri(user.profile_image.url)
            print(f"New image URL: {image_url}")  # Debug log

        return Response({
            'message': 'Profile image uploaded successfully',
            'profile_image_url': image_url
        }, status=status.HTTP_200_OK)

    @swagger_auto_schema(
        operation_description="Delete profile image",
        responses={204: "Image deleted successfully"}
    )
    def delete(self, request):
        """Delete profile image"""
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