const int maxFolderDepth = 3;

class FolderModel {
  final String id;
  final String name;
  final String? parentId;


  FolderModel({required this.id, required this.name, required this.parentId});

  factory FolderModel.fromJson(Map<String, dynamic> json) => FolderModel(
      id: json['id'],
      name: json['name'],
      parentId: json['parentId']);
}

class FolderNode{
  final FolderModel folder;
  final int depth;

  const FolderNode(this.folder, this.depth);
}

List<FolderNode> buildFolderTree(List<FolderModel> folders){
  final ids = folders.map((f) => f.id).toSet();
  final byParent = <String?, List<FolderModel>>{};
  for (final f in folders){
    final key = (f.parentId != null && ids.contains(f.parentId)) ?f.parentId : null;
    byParent.putIfAbsent(key, () => <FolderModel>[]).add(f);
  }

  final result = <FolderNode>[];
  void walk(String? parentId, int depth){
    final children = [...(byParent[parentId] ?? const <FolderModel>[])]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    for (final f in children){
      result.add(FolderNode(f, depth));
      walk(f.id, depth + 1);
    }
  }

  walk(null,1);
  return result;
}

int folderDepth(FolderModel folder, List<FolderModel>all){
  final byId = {for (final f in all) f.id: f};
  final seen = <String>{folder.id};
  var depth = 1;
  var current = folder;
  while (current.parentId !=null){
    final parent = byId[current.parentId];
    if (parent == null || !seen.add(parent.id)) break;
    depth++;
    current = parent;
  }
  return depth;
}

List <FolderModel> folderPath(String? folderId, List<FolderModel>all){
  final byId = {for (final f in all) f.id: f};
  final seen = <String>{};
  final path = <FolderModel>[];

  var current = folderId == null ? null : byId[folderId];
  while (current !=null && seen.add(current.id)) {
    path.insert(0, current);
    current = current.parentId == null ? null: byId[current.parentId];
  }
  return path;
}