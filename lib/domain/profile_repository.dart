import 'user_profile.dart';

abstract interface class ProfileRepository {
  String get ownerId;

  Future<UserProfile?> loadProfile();

  Future<void> saveProfile(UserProfile profile);

  Future<void> deleteProfile();
}
