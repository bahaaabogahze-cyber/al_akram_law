import 'supabase_service.dart';

class SubscriptionState {
  final String status;
  final DateTime? trialStartedAt;
  final DateTime? trialEndsAt;
  final DateTime? subscriptionStartedAt;
  final DateTime? subscriptionEndsAt;
  final String? subscriptionType;
  final bool canUsePaidFeatures;

  const SubscriptionState({
    required this.status,
    this.trialStartedAt,
    this.trialEndsAt,
    this.subscriptionStartedAt,
    this.subscriptionEndsAt,
    this.subscriptionType,
    required this.canUsePaidFeatures,
  });

  factory SubscriptionState.fromMap(Map<String, dynamic> map) {
    DateTime? date(dynamic value) =>
        value == null ? null : DateTime.tryParse(value.toString());
    return SubscriptionState(
      status: map['status']?.toString() ?? 'missing',
      trialStartedAt: date(map['trial_started_at']),
      trialEndsAt: date(map['trial_ends_at']),
      subscriptionStartedAt: date(map['subscription_started_at']),
      subscriptionEndsAt: date(map['subscription_ends_at']),
      subscriptionType: map['subscription_type']?.toString(),
      canUsePaidFeatures: map['can_use_paid_features'] == true,
    );
  }
}

class SubscriptionService {
  static Future<SubscriptionState> getState() async {
    final result = await SupabaseService.client.rpc('get_subscription_state');
    return SubscriptionState.fromMap(Map<String, dynamic>.from(result as Map));
  }

  static Future<void> redeemActivationCode(String code) async {
    await SupabaseService.client.rpc(
      'redeem_activation_code',
      params: {'input_code': code.trim()},
    );
  }
}
