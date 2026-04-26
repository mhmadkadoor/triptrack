import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/config/env_config.dart';

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUpWithEmailPassword(
    String email,
    String password,
    String fullName,
  ) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  Future<void> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    await _client.auth.verifyOTP(
      type: OtpType.signup,
      email: email,
      token: otp,
    );
  }

  Future<AuthResponse?> signInWithGoogle() async {
    if (kIsWeb) {
      final currentUrl = Uri.base.origin;
      final success = await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: currentUrl,
      );
      if (!success) {
        throw Exception('Google Sign-In failed to redirect.');
      }
      // On web, this triggers a redirect, halting immediate execution.
      return null;
    }

    // Read the secret credentials from our EnvConfig!
    const webClientId = EnvConfig.googleWebClientId;

    // In a real project you'd also include an injected IOS client ID if needed.
    // For now we just use null so compilation doesn't fail.
    const String? iosClientId = null;

    final GoogleSignIn googleSignIn = GoogleSignIn(
      serverClientId: webClientId,
      clientId: iosClientId,
    );

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      return null;
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw Exception('Google login failed: Missing ID Token.');
    }

    return await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: googleAuth.accessToken ?? '',
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Updates the user's profile information.
  Future<void> updateUserProfile(
    String userId, {
    String? name,
    String? avatarUrl,
    String? paymentInfo,
    String? iban,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['full_name'] = name;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (paymentInfo != null) updates['payment_info'] = paymentInfo;
    if (iban != null) updates['iban'] = iban;

    if (updates.isEmpty) return;

    // Use DateTime.now().toUtc() for consistency
    updates['updated_at'] = DateTime.now().toUtc().toIso8601String();

    await _client.from('profiles').update(updates).eq('id', userId);
  }

  /// Fetches the profile data for a given user ID.
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return data;
    } catch (e) {
      // In case of error (e.g. no internet), return null or rethrow
      return null;
    }
  }

  /// Uploads a profile image to Supabase Storage and returns the public URL.
  Future<String> uploadProfileImage(
    Uint8List imageBytes,
    String userId, {
    String fileExtension = 'jpg',
  }) async {
    // 1. Clean up old images to free space and ensure unique URLs (cache busting)
    try {
      final objects = await _client.storage.from('avatars').list(path: userId);

      if (objects.isNotEmpty) {
        final pathsToDelete = objects
            .map((obj) => '$userId/${obj.name}')
            .toList();
        await _client.storage.from('avatars').remove(pathsToDelete);
      }
    } catch (e) {
      // Ignore cleanup errors, maybe folder doesn't exist yet
      // or we don't have list permissions (public select usually covers this)
    }

    // 2. Generate timestamped filename to force UI refresh (busts the cache)
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '$userId/profile_$timestamp.$fileExtension';

    // 3. Upload the file
    // We maintain the folder structure avatars/{userId}/... for RLS
    await _client.storage
        .from('avatars')
        .uploadBinary(
          path,
          imageBytes,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );

    // 4. Get the public URL
    final imageUrl = _client.storage.from('avatars').getPublicUrl(path);

    // 5. Update the profile with the new URL
    await updateUserProfile(userId, avatarUrl: imageUrl);

    return imageUrl;
  }

  /// Deletes the user's account and all associated data.
  ///
  /// 1. Tries to clean up storage files (best effort).
  /// 2. Calls RPC to delete database records (including FK cleanup).
  /// 3. Signs out.
  Future<void> deleteAccount(String userId) async {
    // 1. Delete avatar from storage (clean up)
    try {
      final objects = await _client.storage.from('avatars').list(path: userId);
      if (objects.isNotEmpty) {
        final paths = objects.map((o) => '$userId/${o.name}').toList();
        await _client.storage.from('avatars').remove(paths);
      }
    } catch (_) {
      // Ignore errors if bucket is empty or inaccessible
      // We proceed to delete account anyway
    }

    // 2. Execute the nuclear option (RPC)
    await _client.rpc('delete_my_account');

    // 3. Sign out locally
    await signOut();
  }
}
