# ai/services/conversation_service.py

import time
from ai.models import AIConversation, AIMessage, AIUsageLog


class ConversationService:
    def get_or_create_active(self, user):
        conversation = AIConversation.objects.filter(
            user=user,
            is_active=True,
        ).first()
        if conversation:
            return conversation
        return AIConversation.objects.create(user=user, is_active=True)

    def save_exchange(self, user, user_message, result, service_used='local'):
        conversation = self.get_or_create_active(user)

        AIMessage.objects.create(
            conversation=conversation,
            role='user',
            content=user_message,
            service_used=service_used,
        )

        action = result.get('action') if isinstance(result.get('action'), dict) else {}
        AIMessage.objects.create(
            conversation=conversation,
            role='assistant',
            content=result.get('response', ''),
            action_type=action.get('type'),
            action_data=action.get('data'),
            service_used=service_used,
        )
        conversation.save(update_fields=['updated_at'])

    def log_usage(
        self,
        user,
        request_message,
        result,
        service,
        response_time_ms,
        success=True,
        error_message=None,
    ):
        preview = str(result.get('response', ''))[:200]
        AIUsageLog.objects.create(
            user=user,
            service=service,
            request_message=request_message,
            response_preview=preview,
            response_time_ms=response_time_ms,
            success=success,
            error_message=error_message,
        )

    def get_history(self, user, limit=50):
        conversation = AIConversation.objects.filter(
            user=user,
            is_active=True,
        ).first()
        if not conversation:
            return []

        messages = conversation.messages.order_by('-created_at')[:limit]
        return list(reversed(messages))

    def clear_active_conversation(self, user):
        AIConversation.objects.filter(user=user, is_active=True).update(is_active=False)
