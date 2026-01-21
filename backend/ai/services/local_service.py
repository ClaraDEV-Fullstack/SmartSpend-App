# ai/services/local_service.py

import re
from datetime import datetime, timedelta
from collections import defaultdict

class LocalService:
    """Enhanced local processing for precise actions"""

    def process(self, message: str, context: dict) -> dict:
        msg = message.lower().strip()

        # === 1. ACTION: ADD TRANSACTION ===
        # Priority: Check this first so "add" is always caught locally
        if any(word in msg for word in ['add', 'spent', 'paid', 'bought']):
            return self._add_transaction(msg, context)

        # === 2. ACTION: GET SPECIFIC INFO ===
        # Keywords that imply a database lookup
        if any(word in msg for word in ['balance', 'income', 'expense', 'spending', 'transactions', 'report', 'summary']):

            if 'balance' in msg:
                return self._balance_query(context)
            elif 'income' in msg:
                return self._income_query(context)
            elif 'expense' in msg or 'spending' in msg:
                return self._expense_query(msg, context)
            elif any(word in msg for word in ['report', 'summary']):
                return self._financial_report(context)
            elif any(word in msg for word in ['transaction', 'list', 'recent']):
                return self._get_recent_transactions(context)

        # === 3. FALLBACK ===
        # If no specific local action is detected, return None so AI Manager uses Hugging Face
        return None

    # === CORE METHODS ===

    def _add_transaction(self, message: str, context: dict) -> dict:
        """Logic to parse and structure a transaction add request"""
        try:
            # 1. Extract Amount
            amount_match = re.search(r'\d+(\.\d+)?', message)
            if not amount_match:
                return {
                    'response': "❌ I see you want to add a transaction, but I couldn't find the amount. Try: 'Add 50 for lunch'",
                    'type': 'informational'
                }
            amount = float(amount_match.group())

            # 2. Extract Description (remove common words)
            stopwords = ['add', 'spent', 'paid', 'bought', 'on', 'for', 'the', 'a', 'an']
            words = message.split()
            desc_words = [w for w in words if w.lower() not in stopwords and not re.match(r'\d+(\.\d+)?', w)]
            description = " ".join(desc_words).title() if desc_words else "General Expense"

            # 3. Determine Type
            t_type = 'income' if any(w in message for w in ['income', 'salary', 'received']) else 'expense'

            # 4. Construct Response for UI to handle
            currency = context.get('currency', 'USD')
            emoji = "💰" if t_type == 'income' else "💸"

            return {
                'response': f"{emoji} **Ready to Add**\n\n**Amount:** {currency} {amount}\n**Item:** {description}\n\nTap the button below to confirm.",
                'type': 'suggestion',  # UI can use this to show a confirmation button
                'suggested_transaction': {
                    'amount': amount,
                    'description': description,
                    'type': t_type
                }
            }
        except Exception as e:
            return {'response': f"Error parsing transaction: {str(e)}", 'type': 'error'}

    def _get_recent_transactions(self, context: dict) -> dict:
        currency = context.get('currency', 'USD')
        transactions = context.get('recent_transactions', [])

        if not transactions:
            return {'response': "You don't have any transactions yet.", 'type': 'informational'}

        response = "📄 **Recent Transactions**\n\n"
        for t in transactions[:5]:
            emoji = "📈" if t.get('type') == 'income' else "📉"
            response += f"{emoji} {t.get('date', '')[:10]}: {currency} {t.get('amount')} - {t.get('description', '')}\n"

        return {'response': response, 'type': 'informational'}

    def _financial_report(self, context: dict) -> dict:
        curr = context.get('currency', 'USD')
        return {
            'response': f"""📊 **Financial Summary**
            
💰 **Balance:** {curr} {context.get('total_balance', 0):,.2f}
📈 **Income:** {curr} {context.get('total_income', 0):,.2f}
📉 **Expenses:** {curr} {context.get('total_expense', 0):,.2f}
""",
            'type': 'informational'
        }

    def _balance_query(self, context: dict) -> dict:
        curr = context.get('currency', 'USD')
        bal = context.get('total_balance', 0)
        return {'response': f"💰 Your current balance is **{curr} {bal:,.2f}**", 'type': 'informational'}

    def _income_query(self, context: dict) -> dict:
        curr = context.get('currency', 'USD')
        inc = context.get('total_income', 0)
        return {'response': f"📈 Total income: **{curr} {inc:,.2f}**", 'type': 'informational'}

    def _expense_query(self, message: str, context: dict) -> dict:
        curr = context.get('currency', 'USD')
        exp = context.get('total_expense', 0)
        # Fixed: Removed the trailing comma here
        return {'response': f"📉 Total expenses: **{curr} {exp:,.2f}**", 'type': 'informational'}