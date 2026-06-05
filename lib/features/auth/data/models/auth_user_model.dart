import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../domain/entities/auth_user.dart';

class AuthUserModel extends AuthUser {
  const AuthUserModel({required super.id, required super.email});

  factory AuthUserModel.fromSupabaseUser(supabase.User user) {
    return AuthUserModel(id: user.id, email: user.email ?? '');
  }
}
