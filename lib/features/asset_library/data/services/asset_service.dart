import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/endpoints.dart';
import '../../../../utils/validators.dart';
import '../models/asset_model.dart';
import '../models/folder_model.dart';

class AssetService {
  int _nextFolderId = 4;
  int _nextAssetId = 4;
  
  final List<FolderModel> _mockFolders = [
    FolderModel(id: 'f1', name: 'Campaigns'),
    FolderModel(id: 'f2', name: 'q3 lam', parentId: 'f1'),
    FolderModel(id: 'f3', name: 'Logos'),
  ];
  
  final List<AssetModel> _mockAssets = [
    AssetModel(
      id: 'a1',
      name: 'hero-banner-q4.png',
      type: AssetType.image,
      url: 'https://example.com/hero-banner-q4.png',
      folderId: 'f2',
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AssetModel(
      id: 'a2',
      name: 'brand-intro-reel.mp4',
      type: AssetType.video,
      url: 'https://example.com/brand-intro-reel.mp4',
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    AssetModel(
      id: 'a3',
      name: 'primary-logo-mark.svg',
      type: AssetType.logo,
      url: 'https://example.com/primary-logo-mark.svg',
      folderId: 'f3',
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];
  int _mockIndexOf(String id) {
    final i = _mockAssets.indexWhere((a) => a.id == id);
    if (i == -1) throw AppException.fromStatusCode(404);
    return i;
  }






  Future<List<FolderModel>> getFolders() async {
    if (AppApiClient.useMock) {
      await _delay();
      return List.of(_mockFolders);
    }
    final json = await AppApiClient.get(Endpoints.folders);
    return (json as List).map((e) => FolderModel.fromJson(e)).toList();
  }
  Future<FolderModel> createFolder(String name, {String? parentId}) async {
    if (name.trim().isEmpty) throw ArgumentError('Folder name is required');

    if (AppApiClient.useMock) {
      await _delay();
      final parent = parentId == null ? null : _mockFolders.where((f) => f.id == parentId).firstOrNull;
      if (parent != null && folderDepth(parent, _mockFolders) >= maxFolderDepth) {
        throw ArgumentError('Folders can only be nested $maxFolderDepth levels deep.');
      }
      final folder = FolderModel(id: 'f${_nextFolderId++}', name: name.trim(), parentId: parentId);
      _mockFolders.add(folder);
      return folder;
    }
    final json = await AppApiClient.post(
      Endpoints.folders,
      body: {'name': name.trim(), if (parentId != null) 'parentId': parentId},
    );
    return FolderModel.fromJson(json);
  }







  Future<List<AssetModel>> getAssets({
    String? query,
    String sort = 'updated_desc',
    bool trashed = false,
  }) async {
    if (AppApiClient.useMock) {
      await _delay();
      var results = _mockAssets.where((a) => a.isTrashed == trashed).toList();
      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        results = results.where((a) => a.name.toLowerCase().contains(q)).toList();
      }
      results.sort((a, b) => sort == 'name_asc'
          ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
          : b.updatedAt.compareTo(a.updatedAt));
      return results;
    }

    final json = await AppApiClient.get(Endpoints.assets, query: {
      if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      'sort': sort,
      'trashed': trashed.toString(),
    });
    return (json as List).map((e) => AssetModel.fromJson(e)).toList();
  }




  Future<AssetModel> createAsset({
    required String name,
    required AssetType type,
    required String url,
    String? folderId,
  }) async {
    if (name.trim().isEmpty) throw ArgumentError('Asset name is required');
    final urlError = Validators.httpUrl(url);
    if (urlError != null) throw ArgumentError(urlError);

    if (AppApiClient.useMock) {
      await _delay();
      final asset = AssetModel(
        id: 'a${_nextAssetId++}',
        name: name.trim(),
        type: type,
        url: url.trim(),
        folderId: folderId,
        updatedAt: DateTime.now(),
      );
      _mockAssets.add(asset);
      return asset;
    }

    final json = await AppApiClient.post(Endpoints.assets, body: {
      'name': name.trim(),
      'type': type.name,
      'url': url.trim(),
      if (folderId != null) 'folderId': folderId,
    });
    return AssetModel.fromJson(json);
  }


  Future<AssetModel> moveAsset(String assetId, String? folderId) async {
    if (AppApiClient.useMock) {
      await _delay();
      final i = _mockIndexOf(assetId);
      _mockAssets[i] = _mockAssets[i].copyWith(
        folderId: folderId,
        clearFolderId: folderId == null,
        updatedAt: DateTime.now(),
      );
      return _mockAssets[i];
    }
    final json = await AppApiClient.patch(Endpoints.asset(assetId), body: {'folderId': folderId});
    return AssetModel.fromJson(json);
  }

  Future<AssetModel> trashAsset(String id) async {
    if (AppApiClient.useMock) {
      await _delay();
      final i = _mockIndexOf(id);
      _mockAssets[i] = _mockAssets[i].copyWith(deletedAt: DateTime.now());
      return _mockAssets[i];
    }
    final json = await AppApiClient.post(Endpoints.assetTrash(id));
    return AssetModel.fromJson(json);
  }

  Future<AssetModel> restoreAsset(String id) async {
    if (AppApiClient.useMock) {
      await _delay();
      final i = _mockIndexOf(id);
      _mockAssets[i] = _mockAssets[i].copyWith(clearDeletedAt: true);
      return _mockAssets[i];
    }
    final json = await AppApiClient.post(Endpoints.assetRestore(id));
    return AssetModel.fromJson(json);
  }


  Future<void> deleteAssetForever(String id) async {
    if (AppApiClient.useMock) {
      await _delay();
      _mockAssets.removeAt(_mockIndexOf(id));
      return;
    }
    await AppApiClient.delete(Endpoints.asset(id));
  }






  Future<AiSuggestion> generateAiTags(String assetId) async {
    if (AppApiClient.useMock) {
      await _delay();
      return AiSuggestion(
        tags: const ['campaign', 'hero', 'social'],
        description: 'Wide banner image sized for hero placement.',
        usageSuggestion: 'Best used as a homepage hero or top-of-feed social post.',
      );
    }
    final json = await AppApiClient.post(Endpoints.assetAiTags(assetId));
    return AiSuggestion.fromJson(json);
  }

  Future<AssetModel> saveAiTags(String assetId, AiSuggestion suggestion) async {
    if (AppApiClient.useMock) {
      await _delay();
      final i = _mockIndexOf(assetId);
      _mockAssets[i] = _mockAssets[i].copyWith(
        tags: suggestion.tags,
        description: suggestion.description,
        usageSuggestion: suggestion.usageSuggestion,
        updatedAt: DateTime.now(),
      );
      return _mockAssets[i];
    }
    final json = await AppApiClient.patch(Endpoints.assetAiTagsSave(assetId), body: {
      'tags': suggestion.tags,
      'description': suggestion.description,
      'usage_suggestion': suggestion.usageSuggestion,
    });
    return AssetModel.fromJson(json);
  }

  Future<void> _delay() => Future.delayed(const Duration(milliseconds: 250));
}







