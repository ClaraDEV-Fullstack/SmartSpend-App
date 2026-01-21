# ai/views.py

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework import status

from .services import AIManager


class AIAssistView(APIView):
    """
    AI Assistant Endpoint
    Uses: Gemini (FREE) → Local (Offline fallback)
    """
    permission_classes = [IsAuthenticated]

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.ai_manager = AIManager()

    def post(self, request):
        message = request.data.get('message', '').strip()
        context = request.data.get('context', {})

        if not message:
            return Response(
                {'error': 'Message is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Add user info
        context['user_name'] = request.user.first_name or request.user.username

        try:
            result = self.ai_manager.process(message, context)
            return Response(result)
        except Exception as e:
            print(f"❌ AI Error: {e}")
            return Response({
                'response': "Sorry, something went wrong. Please try again!",
                'type': 'informational',
                '_service': 'error'
            })


class AIStatusView(APIView):
    """Check AI services status"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        ai_manager = AIManager()
        return Response(ai_manager.get_status())