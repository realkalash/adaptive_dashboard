
/// Represents an item in the adaptive dashboard.
class DashboardItem {
  DashboardItem({
    required this.id,
    required this.type,
    this.sizeX = 2,
    this.sizeY = 2,
    this.minSizeX = 1,
    this.minSizeY = 1,
    this.posX = 0,
    this.posY = 0,
  });

  int sizeX;
  int sizeY;

  int minSizeX;
  int minSizeY;

  int posX;
  int posY;

  String id;
  String type;

  Map<String, Object> toJson() {
    return {
      'id': id,
      'type': type,
      'sizeX': sizeX,
      'sizeY': sizeY,
      'minSizeX': minSizeX,
      'minSizeY': minSizeY,
      'posX': posX,
      'posY': posY,
    };
  }

  static DashboardItem fromJson(Map<String, Object> json) {
    return DashboardItem(
      id: json['id'] as String,
      type: json['type'] as String,
      sizeX: json['sizeX'] as int,
      sizeY: json['sizeY'] as int,
      minSizeX: json['minSizeX'] as int,
      minSizeY: json['minSizeY'] as int,
      posX: json['posX'] as int,
      posY: json['posY'] as int,
    );
  }
}
