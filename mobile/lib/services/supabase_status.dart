import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStatus {
  const SupabaseStatus._();

  static bool get isConfigured {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  static SupabaseClient get client {
    if (!isConfigured) {
      throw StateError(
        'Supabase is not configured. Pass SUPABASE_URL and SUPABASE_ANON_KEY.',
      );
    }

    return Supabase.instance.client;
  }
}
