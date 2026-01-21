# ai/services/ai_manager.py

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
            return local_result

        # 2. Fallback to AI (Hugging Face)
        # If local didn't catch it, it's likely a conversational query
        print("🤖 Routing to Hugging Face AI...")
        return self.ai.process(message, context)