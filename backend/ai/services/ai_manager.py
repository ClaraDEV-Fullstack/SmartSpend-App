# ai/services/ai_manager.py

from django.conf import settings

from .huggingface_service import HuggingFaceService
from .local_service import LocalService

class AIManager:
    def __init__(self, user=None):
        self.user = user
        self.local = LocalService()
        self.ai = HuggingFaceService()
        print("🤖 AI Manager Initialized: [Local + HuggingFace]")

    def process(self, message: str, context: dict) -> dict:
        """
        Smart Routing:
        1. Local Service (Precise actions, Math, Database)
        2. Hugging Face (General knowledge, Advice, Chit-chat)
        """

        # 1. Try Local Service First
        # If the user wants to ADD or VIEW specific data, Local is best.
        local_result = self.local.process(message, context)

        if local_result is not None:
            print("✅ Handled by Local Service")
            local_result['_service'] = 'local'
            return local_result

        print("🤖 Routing to Hugging Face AI...")
        result = self.ai.process(message, context)
        result['_service'] = 'huggingface'
        return result

    def get_status(self) -> dict:
        return {
            'local_service': True,
            'huggingface_configured': bool(settings.HUGGINGFACE_API_KEY),
            'model': settings.HUGGINGFACE_MODEL,
        }