import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  // Load from environment variables (.env file)
  // Get these from: https://app.supabase.com/project/_/settings/api

  static String get supabaseUrl => dotenv.get('SUPABASE_URL', fallback: '');

  static String get supabaseAnonKey =>
      dotenv.get('SUPABASE_ANON_KEY', fallback: '');

  // Instructions:
  // 1. Copy .env.example to .env
  // 2. Go to https://supabase.com and create a free account
  // 3. Create a new project
  // 4. Go to Project Settings > API
  // 5. Copy the URL and anon/public key to your .env file
}
