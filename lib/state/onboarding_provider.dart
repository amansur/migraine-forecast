import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True once the user has finished the onboarding flow.
final onboardingCompletedProvider = FutureProvider<bool>((ref) async => false);
