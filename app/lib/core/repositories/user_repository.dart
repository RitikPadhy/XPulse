import '../models/user_snapshot.dart';
import '../services/api_client.dart';

class UserRepository {
  UserRepository({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;

  /// Fetches the user's full snapshot from the backend. All three pages
  /// (home/quests/friends) bind to the result.
  Future<UserSnapshot> loadCurrent() => _api.getSnapshot();
}
