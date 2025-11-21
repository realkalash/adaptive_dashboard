import 'package:flutter/material.dart';
import 'dashboard_item.dart';

/// Manages the state and logic of the dashboard.
class DashboardController extends ChangeNotifier {
  final Map<String, DashboardItem> _items = {};

  /// The list of items on the dashboard.
  List<DashboardItem> get items => List.unmodifiable(_items.values);

  /// Adds a widget to the dashboard.
  void addWidget(DashboardItem item) {
    _items[item.id] = item;
    notifyListeners();
  }

  /// Removes a widget from the dashboard.
  void removeWidget(String id) {
    _items.remove(id);
    notifyListeners();
  }

  void clearCanvas() {
    _items.clear();
    notifyListeners();
  }

  DashboardItem? getItemById(String id) {
    return _items[id];
  }

  /// Updates the position of an item.
  ///
  /// Returns true if the move was successful (no overlap), false otherwise.
  bool updateItemPosition(String id, int newX, int newY, int maxColumns, {int? maxRows}) {
    final item = _items[id];
    if (item == null) return false;

    // Check bounds
    if (newX < 0 || newX + item.sizeX > maxColumns) return false;
    if (newY < 0) return false;
    if (maxRows != null && newY + item.sizeY > maxRows) return false;

    // Check collisions
    if (_hasCollision(item, newX, newY, item.sizeX, item.sizeY)) {
      return false;
    }

    item.posX = newX;
    item.posY = newY;
    notifyListeners();
    return true;
  }

  /// Updates the size of an item.
  ///
  /// Returns true if the resize was successful (no overlap), false otherwise.
  bool updateItemSize(String id, int newWidth, int newHeight, int maxColumns, {int? maxRows}) {
    final item = _items[id];
    if (item == null) return false;

    // Enforce minimum size
    if (newWidth < item.minSizeX) newWidth = item.minSizeX;
    if (newHeight < item.minSizeY) newHeight = item.minSizeY;

    // Check bounds
    if (item.posX + newWidth > maxColumns) return false;
    if (maxRows != null && item.posY + newHeight > maxRows) return false;

    // Check collisions
    if (_hasCollision(item, item.posX, item.posY, newWidth, newHeight)) {
      return false;
    }

    item.sizeX = newWidth;
    item.sizeY = newHeight;
    notifyListeners();
    return true;
  }

  /// Checks if moving/resizing [item] to [x], [y], [w], [h] collides with any other item.
  bool _hasCollision(DashboardItem item, int x, int y, int w, int h) {
    for (final other in _items.values) {
      if (other.id == item.id) continue;

      if (x < other.posX + other.sizeX && x + w > other.posX && y < other.posY + other.sizeY && y + h > other.posY) {
        return true;
      }
    }
    return false;
  }
}
