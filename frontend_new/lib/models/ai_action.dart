// lib/models/ai_action.dart

enum AiActionType {
  addTransaction,
  showSummary,
  showCategory,
  showTransactions,
  setBudget,
  informational,
  unknown,
}

enum AiActionStatus {
  pending,
  confirmed,
  cancelled,
  executed,
}

class AiAction {
  final String id;
  final AiActionType type;
  final String description;
  final Map<String, dynamic> data;
  final AiActionStatus status;
  final bool requiresConfirmation;

  AiAction({
    required this.id,
    required this.type,
    required this.description,
    required this.data,
    this.status = AiActionStatus.pending,
    this.requiresConfirmation = true,
  });

  factory AiAction.fromJson(Map<String, dynamic> json) {
    return AiAction(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: _parseActionType(json['type']),
      description: json['description'] ?? '',
      data: json['data'] ?? {},
      status: AiActionStatus.pending,
      requiresConfirmation: json['requires_confirmation'] ?? true,
    );
  }

  static AiActionType _parseActionType(String? type) {
    switch (type) {
      case 'add_transaction':
        return AiActionType.addTransaction;
      case 'show_summary':
        return AiActionType.showSummary;
      case 'show_category':
        return AiActionType.showCategory;
      case 'show_transactions':
        return AiActionType.showTransactions;
      case 'set_budget':
        return AiActionType.setBudget;
      case 'informational':
        return AiActionType.informational;
      default:
        return AiActionType.unknown;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'description': description,
      'data': data,
      'status': status.name,
    };
  }

  AiAction copyWith({AiActionStatus? status}) {
    return AiAction(
      id: id,
      type: type,
      description: description,
      data: data,
      status: status ?? this.status,
      requiresConfirmation: requiresConfirmation,
    );
  }

  // Helper getters for transaction data
  String? get transactionType => data['type']?.toString();

  double? get amount {
    final amt = data['amount'];
    if (amt == null) return null;
    if (amt is num) return amt.toDouble();
    if (amt is String) return double.tryParse(amt);
    return null;
  }

  String? get categoryName => data['category']?.toString();

  int? get categoryId {
    final id = data['category_id'];
    if (id == null) return null;
    if (id is int) return id;
    if (id is String) return int.tryParse(id);
    return null;
  }

  String? get transactionDescription => data['description']?.toString();

  String? get currency => data['currency']?.toString();

  DateTime? get date {
    final dateStr = data['date'];
    if (dateStr == null) return DateTime.now();
    try {
      return DateTime.parse(dateStr.toString());
    } catch (_) {
      return DateTime.now();
    }
  }
}