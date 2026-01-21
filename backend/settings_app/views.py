from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework import status
from .models import UserSetting
from .serializers import UserSettingSerializer
from drf_yasg.utils import swagger_auto_schema
from drf_yasg import openapi

@swagger_auto_schema(
    method='get',
    tags=['settings'],
    operation_summary="Get User Settings",
    operation_description="Retrieve the authenticated user's app settings.",
    responses={
        200: UserSettingSerializer,
        401: "Unauthorized"
    }
)
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def user_settings(request):
    setting, created = UserSetting.objects.get_or_create(user=request.user)
    serializer = UserSettingSerializer(setting)
    return Response(serializer.data)


@swagger_auto_schema(
    method='put',
    tags=['settings'],
    operation_summary="Update User Settings",
    operation_description="Update the authenticated user's preferences.",
    request_body=UserSettingSerializer,
    responses={
        200: UserSettingSerializer,
        400: "Bad Request (Validation Error)",
        401: "Unauthorized"
    }
)
@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def update_user_settings(request):
    setting, created = UserSetting.objects.get_or_create(user=request.user)
    serializer = UserSettingSerializer(setting, data=request.data, partial=True)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# Add the password change endpoint
@swagger_auto_schema(
    method='post',
    tags=['auth'],
    operation_summary="Change Password",
    operation_description="Change the authenticated user's password.",
    request_body=openapi.Schema(
        type=openapi.TYPE_OBJECT,
        required=['current_password', 'new_password'],
        properties={
            'current_password': openapi.Schema(
                type=openapi.TYPE_STRING,
                description='Current password of the user'
            ),
            'new_password': openapi.Schema(
                type=openapi.TYPE_STRING,
                description='New password to set'
            )
        }
    ),
    responses={
        200: openapi.Response(
            description="Password changed successfully",
            schema=openapi.Schema(
                type=openapi.TYPE_OBJECT,
                properties={
                    'message': openapi.Schema(type=openapi.TYPE_STRING)
                }
            )
        ),
        400: "Bad Request (Validation Error)",
        401: "Unauthorized"
    }
)
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def change_password(request):
    current_password = request.data.get('current_password')
    new_password = request.data.get('new_password')

    if not current_password or not new_password:
        return Response(
            {'error': 'Both current_password and new_password are required'},
            status=status.HTTP_400_BAD_REQUEST
        )

    # Verify current password
    if not request.user.check_password(current_password):
        return Response(
            {'error': 'Current password is incorrect'},
            status=status.HTTP_400_BAD_REQUEST
        )

    # Set new password
    request.user.set_password(new_password)
    request.user.save()

    return Response({'message': 'Password changed successfully'})