class AppConstants {
  static const String appName = 'Music Vibes';
  static const String appVersion = '1.0.0';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String postsCollection = 'posts';
  static const String timelinesCollection = 'timelines';
  static const String followsCollection = 'follows';
  static const String followersCollection = 'followers';
  static const String likesCollection = 'likes';

  // Pagination
  static const int postsPerPage = 20;
  static const int usersPerPage = 30;

  // Validation
  static const int maxBioLength = 150;
  static const int maxPostLength = 500;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 20;

  // Ad Configuration
  static const int minAdInterval = 1;
  static const int maxAdInterval = 10;
}
