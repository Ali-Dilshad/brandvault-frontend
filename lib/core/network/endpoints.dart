class Endpoints {
  static const String baseUrl = String.fromEnvironment(
    '',
    defaultValue: 'http://localhost:3000',
  );

  static const String signUp = '/auth/signup';
  static const String signIn = '/auth/signin';

  static const String brand = '/brand';
  static const String folders = '/folders';
  static const String assets = '/assets';

  static String asset(String id) => '/assets/$id';
  static String assetTrash(String id) => '/assets/$id/trash';
  static String assetRestore(String id) => '/assets/$id/restore';
  static String assetAiTags(String id) => '/assets/$id/ai-tags';
  static String assetAiTagsSave(String id) => '/assets/$id/ai-tags/save';
}
