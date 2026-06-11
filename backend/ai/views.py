# ai/views.py

import time

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework import status

from .services import AIManager
from .services.conversation_service import ConversationService


class AIAssistView(APIView):
    """AI Assistant endpoint with conversation persistence."""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        message = request.data.get('message', '').strip()
        context = request.data.get('context', {})

        if not message:
            return Response(
                {'error': 'Message is required'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        context['user_name'] = request.user.first_name or request.user.username
        conversation_service = ConversationService()
        started_at = time.time()

        try:
            ai_manager = AIManager(user=request.user)
            result = ai_manager.process(message, context)
            service_used = result.pop('_service', 'local')
            elapsed_ms = int((time.time() - started_at) * 1000)

            conversation_service.save_exchange(
                request.user,
                message,
                result,
                service_used=service_used,
            )
            conversation_service.log_usage(
                user=request.user,
                request_message=message,
                result=result,
                service=service_used,
                response_time_ms=elapsed_ms,
                success=True,
            )

            return Response(result)
        except Exception as e:
            elapsed_ms = int((time.time() - started_at) * 1000)
            conversation_service.log_usage(
                user=request.user,
                request_message=message,
                result={'response': str(e)},
                service='error',
                response_time_ms=elapsed_ms,
                success=False,
                error_message=str(e),
            )
            return Response({
                'response': 'Sorry, something went wrong. Please try again!',
                'type': 'informational',
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class AIHistoryView(APIView):
    """Return persisted AI conversation history for the current user."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        limit = int(request.query_params.get('limit', 50))
        messages = ConversationService().get_history(request.user, limit=limit)
        return Response([
            {
                'role': message.role,
                'content': message.content,
                'action_type': message.action_type,
                'action_data': message.action_data,
                'service_used': message.service_used,
                'created_at': message.created_at.isoformat(),
            }
            for message in messages
        ])

    def delete(self, request):
        ConversationService().clear_active_conversation(request.user)
        return Response(status=status.HTTP_204_NO_CONTENT)


class AIStatusView(APIView):
    """Check AI services status."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        ai_manager = AIManager()
        return Response(ai_manager.get_status())
