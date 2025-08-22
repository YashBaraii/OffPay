import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  static const String supabaseUrl = String.fromEnvironment(
      'https://mvzbaqbiprhtjcrevhus.supabase.co',
      defaultValue: '');
  static const String supabaseAnonKey = String.fromEnvironment(
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im12emJhcWJpcHJodGpjcmV2aHVzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU4NTgwNjEsImV4cCI6MjA3MTQzNDA2MX0.2358Ya0rK6tvvjoXI_TPHwxQ3-_51KsQQyVpqDTw0zE',
      defaultValue: '');

  // Initialize Supabase - call this in main()
  static Future<void> initialize() async {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception(
          'SUPABASE_URL and SUPABASE_ANON_KEY must be defined using --dart-define.');
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  // Get Supabase client
  SupabaseClient get client => Supabase.instance.client;
}
