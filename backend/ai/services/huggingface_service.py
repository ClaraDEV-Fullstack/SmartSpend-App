# ai/services/huggingface_service.py

import requests
import logging
from django.conf import settings

logger = logging.getLogger(__name__)

class HuggingFaceService:
    def __init__(self):
        self.api_url = f"https://api-inference.huggingface.co/models/{settings.HUGGINGFACE_MODEL}"
        self.headers = {"Authorization": f"Bearer {settings.HUGGINGFACE_API_KEY}"}

    def process(self, message, context):
        """Generate a response using Hugging Face"""

        system_prompt = self._build_system_prompt(context)

        # Format for Zephyr/Mistral: <|system|>...<|user|>...<|assistant|>
        full_prompt = f"<|system|>\n{system_prompt}</s>\n<|user|>\n{message}</s>\n<|assistant|>\n"

        payload = {
            "inputs": full_prompt,
            "parameters": {
                "max_new_tokens": 500,
                "temperature": 0.7,
                "return_full_text": False
            }
        }

        try:
            response = requests.post(self.api_url, headers=self.headers, json=payload)

            if response.status_code == 200:
                result = response.json()

                if isinstance(result, list) and len(result) > 0:
                    return {
                        'response': result[0].get('generated_text', '').strip(),
                        'type': 'ai_chat'
                    }
                elif isinstance(result, dict) and 'error' in result:
                    if 'loading' in str(result['error']):
                        return {
                            'response': "🧠 I'm waking up... Ask me again in 20 seconds!",
                            'type': 'error'
                        }
                    return {'response': f"AI Error: {result['error']}", 'type': 'error'}

            logger.error(f"Hugging Face Error: {response.status_code} - {response.text}")
            return {'response': f"Connection Error: {response.status_code}", 'type': 'error'}

        except Exception as e:
            logger.error(f"Request Error: {str(e)}")
            return {'response': "Network error connecting to AI.", 'type': 'error'}

    def _build_system_prompt(self, context):
        curr = context.get('currency', 'USD')

        base = f"""You are SmartSpend AI, a helpful financial assistant.
        
        USER CONTEXT:
        - Balance: {curr} {context.get('total_balance', 0)}
        - Income: {curr} {context.get('total_income', 0)}
        - Expenses: {curr} {context.get('total_expense', 0)}
        
        RECENT TRANSACTIONS:
        """

        # Add recent transactions to context
        transactions = context.get('recent_transactions', [])
        for t in transactions[:5]:
            description = t.get('description', 'Unknown')
            amount = t.get('amount', 0)
            date = t.get('date', '')[:10] if t.get('date') else ''
            base += f"- {date}: {description} ({curr} {amount})\n"

        base += """
        GUIDELINES:
        1. Answer based on the data above.
        2. Keep it short, helpful and friendly. Use emojis.
        3. If asked to add a transaction, say: "I can help! Say 'Add 50 for lunch'."
        """
        return base