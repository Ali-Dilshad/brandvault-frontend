import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../brand_kit/data/models/brand_model.dart';
import '../../../brand_kit/data/services/brand_service.dart';
import '../../../brand_kit/presentation/pages/brand_kit_page.dart';
import '../../../brand_kit/presentation/widgets/brand_kit_summary_card.dart';
import '../../data/models/asset_model.dart';
import '../../data/models/folder_model.dart';
import '../../data/services/asset_service.dart';
import '../widgets/asset_detail_panel.dart';
import '../widgets/folder_card.dart';
import '../widgets/ledger_row.dart';

enum _View { library, trash }

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}


class _MoveResult {
  final String? folderId;
  const _MoveResult(this.folderId);
}

class _DashboardPageState extends State<DashboardPage> {
  final _service = AssetService();
  final _brandService = BrandService();
  final _authService = AuthService();

  static const double _sidebarBreakpoint = 1100;
  static const double _panelBreakpoint = 1300;
  static const double _mobileBreakpoint = 700;
  static const double _compactTopBarBreakpoint = 560;

  _View _view = _View.library;
  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  String _sort = 'updated_desc';
  String? _selectedFolderId;
  String? _selectedAssetId;
  Timer? _searchDebounce;
  int _refreshSeq = 0;

  List<FolderModel> _folders = [];
  List<AssetModel> _assets = [];
  BrandModel? _brand;

  List<AssetModel> _trashed = [];
  bool _trashLoading = false;
  bool _trashLoaded = false;
  String? _trashError;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final folders = await _service.getFolders();
      final assets = await _service.getAssets(query: _searchQuery, sort: _sort, trashed: false);
      if (!mounted) return;
      setState(() {
        _folders = folders;
        _assets = assets;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = errorMessage(e, fallback: 'Could not load your vault. Try again.');
        _loading = false;
      });
    }
    unawaited(_loadBrand());
  }


  Future<void> _loadBrand() async {
    try {
      final brand = await _brandService.getBrand();
      if (!mounted) return;
      setState(() => _brand = brand);
    } catch (_) {
    }
  }

  Future<void> _refreshAssets() async {
    final seq = ++_refreshSeq;
    try {
      final assets = await _service.getAssets(query: _searchQuery, sort: _sort, trashed: false);
      if (!mounted || seq != _refreshSeq) return;
      setState(() => _assets = assets);
    } catch (e) {
      _showMessage(errorMessage(e, fallback: 'Could not refresh your assets.'));
    }
  }

  Future<void> _loadTrash() async {
    setState(() {
      _trashLoading = true;
      _trashError = null;
    });
    try {
      final trashed = await _service.getAssets(trashed: true);
      if (!mounted) return;
      setState(() {
        _trashed = trashed;
        _trashLoading = false;
        _trashLoaded = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _trashError = errorMessage(e, fallback: 'Could not load the Trash.');
        _trashLoading = false;
      });
    }
  }

  Future<void> _reloadFolders() async {
    try {
      final folders = await _service.getFolders();
      if (!mounted) return;
      setState(() => _folders = folders);
    } catch (e) {
      _showMessage(errorMessage(e, fallback: 'Could not refresh your folders.'));
    }
  }

  void _showMessage(String message, {SnackBarAction? action}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), action: action ,duration: const Duration(seconds: 10),));
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    });
  }

  void _onSearchChanged(String value) {
    _searchQuery = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), _refreshAssets);
  }

  void _setView(_View view) {
    setState(() => _view = view);
    if (view == _View.trash && !_trashLoaded) _loadTrash();
  }


  List<AssetModel> get _visibleAssets =>
      _selectedFolderId == null ? _assets : _assets.where((a) => a.folderId == _selectedFolderId).toList();

  AssetModel? get _selectedAsset {
    final id = _selectedAssetId;
    if (id == null) return null;
    for (final a in _assets) {
      if (a.id == id) return a;
    }
    return null;
  }

  String? _folderName(String? id) {
    if (id == null) return null;
    for (final f in _folders) {
      if (f.id == id) return f.name;
    }
    return null;
  }

  String get _emptyMessage {
    if (_searchQuery.trim().isNotEmpty) return 'No assets match "${_searchQuery.trim()}".';
    if (_selectedFolderId != null) return 'This folder is empty.';
    return 'No assets yet — add your first one.';
  }

  List<DropdownMenuItem<String?>> _folderItems({int? maxParentDepth}) {
    final nodes = buildFolderTree(_folders).where((n) => maxParentDepth == null || n.depth < maxParentDepth);
    return nodes
        .map((n) => DropdownMenuItem<String?>(
      value: n.folder.id,
      child: Text('${'\u2003' * (n.depth - 1)}${n.folder.name}', overflow: TextOverflow.ellipsis),
    ))
        .toList();
  }

  void _onAssetUpdated(AssetModel updated) {
    setState(() {
      final i = _assets.indexWhere((a) => a.id == updated.id);
      if (i != -1) _assets[i] = updated;
    });
  }

  Future<void> _trash(AssetModel asset) async {
    try {
      await _service.trashAsset(asset.id);
      if (_selectedAssetId == asset.id) setState(() => _selectedAssetId = null);
      await _refreshAssets();
      _trashLoaded = false;
      _showMessage(
        '"${asset.name}" moved to Trash',
        action: SnackBarAction(label: 'Undo', onPressed: () => _restoreFromLibraryUndo(asset)),
      );
    } catch (e) {
      _showMessage(errorMessage(e, fallback: 'Could not move that asset to Trash.'));
    }
  }

  Future<void> _restoreFromLibraryUndo(AssetModel asset) async {
    try {
      await _service.restoreAsset(asset.id);
      await _refreshAssets();
    } catch (e) {
      _showMessage(errorMessage(e, fallback: 'Could not restore that asset.'));
    }
  }

  Future<void> _restoreFromTrash(AssetModel asset) async {
    try {
      await _service.restoreAsset(asset.id);
      await _loadTrash();
      await _refreshAssets();
      _showMessage('"${asset.name}" restored');
    } catch (e) {
      _showMessage(errorMessage(e, fallback: 'Could not restore that asset.'));
    }
  }

  Future<void> _deleteForever(AssetModel asset) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete permanently?'),
        content: Text('"${asset.name}" will be gone for good. This can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.rust),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _service.deleteAssetForever(asset.id);
      await _loadTrash();
      _showMessage('"${asset.name}" deleted');
    } catch (e) {
      _showMessage(errorMessage(e, fallback: 'Could not delete that asset.'));
    }
  }

  void _openAssetDetail(AssetModel asset, bool showPanel) {
    if (showPanel) {
      setState(() => _selectedAssetId = asset.id);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AssetDetailPage(
          asset: asset,
          folderName: _folderName(asset.folderId),
          service: _service,
          onUpdated: _onAssetUpdated,
          onMove: () => _promptMove(asset),
          onTrash: () => _trash(asset),
        ),
      ),
    );
  }

  Future<void> _promptMove(AssetModel asset) async {
    String? target = asset.folderId;

    final result = await showDialog<_MoveResult>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text('Move "${asset.name}"'),
          content: SizedBox(
            width: 360,
            child: DropdownButtonFormField<String?>(
              value: target,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Folder'),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('No folder')),
                ..._folderItems(),
              ],
              onChanged: (v) => setDialogState(() => target = v),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: target == asset.folderId ? null : () => Navigator.pop(dialogContext, _MoveResult(target)),
              child: const Text('Move'),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;

    try {
      await _service.moveAsset(asset.id, result.folderId);
      await _refreshAssets();
      _showMessage('Moved to ${_folderName(result.folderId) ?? 'the library root'}');
    } catch (e) {
      _showMessage(errorMessage(e, fallback: 'Could not move that asset.'));
    }
  }
  Future<void> _openAddAssetDialog() async {
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    AssetType type = AssetType.image;
    String? folderId = _selectedFolderId;
    String? formError;
    bool saving = false;

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Add asset'),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, autofocus: true, decoration: const InputDecoration(labelText: 'Name')),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<AssetType>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: AssetType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                    onChanged: (v) => setDialogState(() => type = v!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: urlController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(labelText: 'URL (https://…)'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    value: folderId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Folder (optional)'),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('No folder')),
                      ..._folderItems(),
                    ],
                    onChanged: (v) => setDialogState(() => folderId = v),
                  ),
                  if (formError != null) ...[
                    const SizedBox(height: 8),
                    Text(formError!, style: const TextStyle(color: AppColors.rust, fontSize: 12)),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                setDialogState(() {
                  saving = true;
                  formError = null;
                });
                try {
                  await _service.createAsset(name: nameController.text, type: type, url: urlController.text, folderId: folderId);
                  if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                } catch (e) {
                  if (!dialogContext.mounted) return;
                  setDialogState(() {
                    formError = errorMessage(e, fallback: 'Could not add asset.');
                    saving = false;
                  });
                }
              },
              child: const Text('Add asset'),
            ),
          ],
        ),
      ),
    );

    if (created == true) await _refreshAssets();
  }

  Future<void> _promptNewFolder() async {
    final controller = TextEditingController();
    final parentItems = _folderItems(maxParentDepth: maxFolderDepth);
    final canNestInSelected = _selectedFolderId != null && parentItems.any((i) => i.value == _selectedFolderId);
    String? parentId = canNestInSelected ? _selectedFolderId : null;
    String? formError;
    bool saving = false;

    final created = await showDialog<FolderModel>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('New folder'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'Folder name')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  value: parentId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Inside'),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Top level')),
                    ...parentItems,
                  ],
                  onChanged: (v) => setDialogState(() => parentId = v),
                ),
                if (formError != null) ...[
                  const SizedBox(height: 8),
                  Text(formError!, style: const TextStyle(color: AppColors.rust, fontSize: 12)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                setDialogState(() {
                  saving = true;
                  formError = null;
                });
                try {
                  final folder = await _service.createFolder(controller.text, parentId: parentId);
                  if (dialogContext.mounted) Navigator.pop(dialogContext, folder);
                } catch (e) {
                  if (!dialogContext.mounted) return;
                  setDialogState(() {
                    formError = errorMessage(e, fallback: 'Could not create folder.');
                    saving = false;
                  });
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    if (created == null) return;
    await _reloadFolders();
    if (mounted) setState(() => _selectedFolderId = created.id);
  }
  Future<void> _openBrandKit() async {
    final saved = await Navigator.push<bool>(context, MaterialPageRoute<bool>(builder: (_) => const BrandKitPage()));
    if (saved == true) {
      _showMessage('Brand kit saved');
      await _loadBrand();
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (_) => false,
    );
  }


  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isDesktop = width >= _sidebarBreakpoint;
        final showPanel = width >= _panelBreakpoint;
        final isMobile = width < _mobileBreakpoint;
        final showTabsInBar = width >= _compactTopBarBreakpoint;

        return Scaffold(
          appBar: _buildAppBar(showMenuButton: !isDesktop, showTabs: showTabsInBar, showWorkspacePill: isDesktop),
          drawer: isDesktop ? null : Drawer(child: SafeArea(child: _buildFolderShelf(inDrawer: true))),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, style: const TextStyle(color: AppColors.rust)),
                const SizedBox(height: 8),
                TextButton(onPressed: _loadAll, child: const Text('Try again')),
              ],
            ),
          )
              : Column(
            children: [
              if (!showTabsInBar) _buildCompactTabStrip(),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isDesktop) SizedBox(width: 220, child: _buildFolderShelf()),
                    Expanded(child: _buildMainColumn(isMobile: isMobile, showPanel: showPanel)),
                    if (showPanel) SizedBox(width: 300, child: _buildDetailPanel()),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildCompactTabStrip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.paperRaised,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(children: [_navTab('Library', _View.library), const SizedBox(width: 4), _navTab('Trash', _View.trash)]),
    );
  }

  PreferredSizeWidget _buildAppBar({required bool showMenuButton, required bool showTabs, required bool showWorkspacePill}) {
    return AppBar(
      backgroundColor: AppColors.paperRaised,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 68,
      shape: const Border(
        bottom: BorderSide(
          color: AppColors.line,
          width: 1,
        ),
      ),

      leading: showMenuButton
          ? Builder(
        builder: (ctx) => IconButton(
          tooltip: 'Open menu',
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      )
          : null,

      titleSpacing: showMenuButton ? 8 : 24,

      title: Row(
        children: [
          Text.rich(
            TextSpan(
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
              children: const [
                TextSpan(text: 'Brand'),
                TextSpan(
                  text: 'Vault',
                  style: TextStyle(
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),

          if (showTabs) ...[
            const SizedBox(width: 40),

            Container(
              height: 40,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.line.withOpacity(0.35),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _navTab('Library', _View.library),
                  const SizedBox(width: 2),
                  _navTab('Trash', _View.trash),
                ],
              ),
            )          ],
        ],
      ),

      actions: [
        if (showWorkspacePill && AppApiClient.useMock)
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: AppColors.paperRaised,
              border: Border.all(
                color: AppColors.line,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.workspaces_outline,
                  size: 16,
                  color: AppColors.muted,
                ),
                SizedBox(width: 7),
                Text(
                  'Demo workspace',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkSoft,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: AppColors.muted,
                ),
              ],
            ),
          ),

        PopupMenuButton<String>(
          tooltip: 'Account',
          offset: const Offset(0, 48),
          onSelected: (value) {
            if (value == 'brand') {
              _openBrandKit();
            }

            if (value == 'signout') {
              _signOut();
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'brand',
              height: 48,
              child: Row(
                children: [
                  Icon(
                    Icons.palette_outlined,
                    size: 19,
                    color: AppColors.accent,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Brand kit',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'signout',
              child: Row(
                children: [
                  Icon(
                    Icons.logout_rounded,
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Text('Sign out'),
                ],
              ),
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.only(
              left: 6,
              right: 20,
            ),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accent.withOpacity(0.25),
                ),
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                size: 19,
                color: AppColors.accent,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _navTab(String label, _View view) {
    final active = _view == view;
    return Material(
      color: active ? AppColors.accentSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => _setView(view),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          child: Text(label, style: TextStyle(fontSize: 13, color: active ? AppColors.accent : AppColors.inkSoft, fontWeight: active ? FontWeight.w500 : FontWeight.w400)),
        ),
      ),
    );
  }
  Widget _buildFolderShelf({bool inDrawer = false}) {
    void select(String? id) {
      setState(() => _selectedFolderId = id);
      _setView(_View.library);
      if (inDrawer) Navigator.pop(context);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(border: Border(right: BorderSide(color: AppColors.line))),
      child: ListView(
        children: [
          const Text('Folders', style: TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 8),
          FolderCard(
            folder: FolderModel(id: '', name: 'All assets'),
            selected: _view == _View.library && _selectedFolderId == null,
            onTap: () => select(null),
          ),
          ...buildFolderTree(_folders).map((n) => FolderCard(
            folder: n.folder,
            depth: n.depth,
            selected: _view == _View.library && _selectedFolderId == n.folder.id,
            onTap: () => select(n.folder.id),
          )),
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: _promptNewFolder,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              child: Text('+ New folder', style: TextStyle(fontSize: 13, color: AppColors.accent, fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb() {
    final path = folderPath(_selectedFolderId, _folders);

    Widget crumb(String label, VoidCallback onTap, {required bool active}) => InkWell(
      onTap: active ? null : onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20, color: active ? AppColors.ink : AppColors.muted),
        ),
      ),
    );

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        crumb('All assets', () => setState(() => _selectedFolderId = null), active: path.isEmpty),
        for (final folder in path) ...[
          const Icon(Icons.chevron_right, size: 20, color: AppColors.muted),
          crumb(folder.name, () => setState(() => _selectedFolderId = folder.id), active: identical(folder, path.last)),
        ],
      ],
    );
  }

  Widget _buildMainColumn({required bool isMobile, required bool showPanel}) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 14 : 24),
      child: _view == _View.library ? _buildLibrary(isMobile: isMobile, showPanel: showPanel) : _buildTrash(),
    );
  }

  Widget _buildLibrary({required bool isMobile, required bool showPanel}) {
    final visible = _visibleAssets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBreadcrumb(),
        const SizedBox(height: 16),
        _buildToolbar(isMobile: isMobile),
        const SizedBox(height: 12),
        if (!isMobile) _buildLedgerHead(),
        Expanded(
          child: visible.isEmpty
              ? Center(child: Text(_emptyMessage, style: const TextStyle(color: AppColors.muted)))
              : ListView.separated(
            itemCount: visible.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.line),
            itemBuilder: (_, i) => LedgerRow(
              asset: visible[i],
              index: i,
              selected: showPanel && visible[i].id == _selectedAssetId,
              onTap: () => _openAssetDetail(visible[i], showPanel),
              onTrash: () => _trash(visible[i]),
              onMove: () => _promptMove(visible[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLedgerHead() {
    const style = TextStyle(fontSize: 11.5, color: AppColors.muted);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
      child: const Row(
        children: [
          SizedBox(width: 24, child: Text('#', style: style)),
          SizedBox(width: 8),
          Expanded(child: Text('Name', style: style)),
          SizedBox(width: 90, child: Text('Type', style: style)),
          SizedBox(width: 110, child: Text('Updated', style: style)),
          SizedBox(width: 76),
        ],
      ),
    );
  }
  Widget _buildTrash() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: AppColors.rustSoft, borderRadius: BorderRadius.circular(6)),
          child: const Text(
            'Items here are hidden from the library. Restore them to bring them back, or delete them permanently.',
            style: TextStyle(color: AppColors.rust, fontSize: 13),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _trashLoading
              ? const Center(child: CircularProgressIndicator())
              : _trashError != null
              ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_trashError!, style: const TextStyle(color: AppColors.rust)),
                const SizedBox(height: 8),
                TextButton(onPressed: _loadTrash, child: const Text('Try again')),
              ],
            ),
          )
              : _trashed.isEmpty
              ? const Center(child: Text('Trash is empty.', style: TextStyle(color: AppColors.muted)))
              : ListView.separated(
            itemCount: _trashed.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.line),
            itemBuilder: (_, i) => LedgerRow(
              asset: _trashed[i],
              index: i,
              isTrashView: true,
              onTap: () {},
              onRestore: () => _restoreFromTrash(_trashed[i]),
              onDeleteForever: () => _deleteForever(_trashed[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailPanel() {
    final selected = _selectedAsset;
    return Container(
      decoration: const BoxDecoration(border: Border(left: BorderSide(color: AppColors.line))),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Brand kit', style: TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 10),
            BrandKitSummaryCard(brand: _brand, onEdit: _openBrandKit),
            const SizedBox(height: 22),
            const Text('Selected asset', style: TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 4),
            if (selected == null)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text('Select an asset to see its details.', style: TextStyle(fontSize: 12.5, color: AppColors.muted)),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: AssetDetailPanel(
                  key: ValueKey(selected.id),
                  asset: selected,
                  folderName: _folderName(selected.folderId),
                  service: _service,
                  onUpdated: _onAssetUpdated,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar({required bool isMobile}) {
    final searchField = TextField(
      decoration: const InputDecoration(hintText: 'Search assets by name…', prefixIcon: Icon(Icons.search, size: 18)),
      onChanged: _onSearchChanged,
    );

    final sortDropdown = DropdownButton<String>(
      value: _sort,
      underline: const SizedBox.shrink(),
      items: const [
        DropdownMenuItem(value: 'updated_desc', child: Text('Recently updated')),
        DropdownMenuItem(value: 'name_asc', child: Text('Name A-Z')),
      ],
      onChanged: (v) {
        setState(() => _sort = v!);
        _refreshAssets();
      },
    );

    final addButton = ElevatedButton(
      onPressed: _openAddAssetDialog,
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.ink),
      child: const Text('+ Add asset'),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchField,
          const SizedBox(height: 10),
          Row(children: [Expanded(child: sortDropdown), const SizedBox(width: 10), addButton]),
        ],
      );
    }

    return Row(children: [Expanded(child: searchField), const SizedBox(width: 10), sortDropdown, const SizedBox(width: 10), addButton]);
  }
}

class _AssetDetailPage extends StatelessWidget {
  final AssetModel asset;
  final String? folderName;
  final AssetService service;
  final ValueChanged<AssetModel> onUpdated;
  final VoidCallback onMove;
  final VoidCallback onTrash;

  const _AssetDetailPage({
    required this.asset,
    required this.service,
    required this.onUpdated,
    required this.onMove,
    required this.onTrash,
    this.folderName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.paperRaised,
        foregroundColor: AppColors.ink,
        title: Text(asset.name, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(icon: const Icon(Icons.drive_file_move_outline), tooltip: 'Move to folder', onPressed: onMove),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.rust),
            tooltip: 'Move to Trash',
            onPressed: () {
              onTrash();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: AssetDetailPanel(asset: asset, folderName: folderName, service: service, onUpdated: onUpdated),
    );
  }
}
