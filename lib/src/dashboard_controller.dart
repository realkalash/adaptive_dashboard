import 'package:adaptive_dashboard/src/dashboard_config.dart';
import 'package:flutter/material.dart';
import 'dashboard_item.dart';

/// Manages the state and logic of the dashboard.
class DashboardController extends ChangeNotifier {
  final Map<String, DashboardItem> _items = {};
  DashboardConfig? _config;

  void setConfig(DashboardConfig config) {
    _config = config;
    notifyListeners();
  }

  /// The list of items on the dashboard.
  List<DashboardItem> get items => List.unmodifiable(_items.values);

  /// Adds a widget to the dashboard.
  ///
  /// If the widget cannot be placed at its current position, it will automatically
  /// search for an available space. If no space is found:
  /// - For infinite canvas (maxRows == null): places the widget at the bottom
  /// - For finite canvas (maxRows != null): does nothing and returns without adding
  void addWidget(DashboardItem item) {
    if (_config == null) {
      // No config set, add widget as-is
      _items[item.id] = item;
      notifyListeners();
      return;
    }

    final maxColumns = _config!.maxColumns;
    final maxRows = _config!.maxRows;

    // Check if the widget can be placed at its current position
    if (canPlaceWidget(item.posX, item.posY, item.sizeX, item.sizeY, maxColumns, maxRows: maxRows)) {
      _items[item.id] = item;
      notifyListeners();
      return;
    }

    // Try to find an available position
    final availablePosition = _findAvailablePosition(item.sizeX, item.sizeY, maxColumns, maxRows: maxRows);

    if (availablePosition != null) {
      // Found a position, update item and add it
      item.posX = availablePosition.x;
      item.posY = availablePosition.y;
      _items[item.id] = item;
      notifyListeners();
      return;
    }

    // No available position found
    if (maxRows == null) {
      // Infinite canvas: place at the bottom
      final maxUsedRow = _calculateMaxUsedRow();
      item.posX = 0;
      item.posY = maxUsedRow;
      _items[item.id] = item;
      notifyListeners();
    }
    // Finite canvas with no space: do nothing (don't add the widget)
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

  /// Checks if a widget with the given dimensions can be placed at the specified position.
  ///
  /// Returns true if the widget can be placed without collisions and within bounds.
  bool canPlaceWidget(int x, int y, int width, int height, int maxColumns, {int? maxRows}) {
    // Check bounds
    if (x < 0 || y < 0) return false;
    if (x + width > maxColumns) return false;
    if (maxRows != null && y + height > maxRows) return false;

    // Check collisions with existing items
    for (final item in _items.values) {
      if (x < item.posX + item.sizeX && x + width > item.posX && y < item.posY + item.sizeY && y + height > item.posY) {
        return false;
      }
    }

    return true;
  }

  /// Finds an available position for a widget with the given dimensions.
  ///
  /// Scans the grid from top-left to bottom-right looking for the first available space.
  /// Returns a record (x, y) if a position is found, or null if no space is available
  /// in a finite canvas.
  ({int x, int y})? _findAvailablePosition(int width, int height, int maxColumns, {int? maxRows}) {
    // Calculate the maximum Y position to search
    int maxY = maxRows ?? _calculateMaxUsedRow() + 10; // Add buffer for infinite canvas

    // Scan from top-left to bottom-right
    for (int y = 0; y <= maxY; y++) {
      for (int x = 0; x <= maxColumns - width; x++) {
        if (canPlaceWidget(x, y, width, height, maxColumns, maxRows: maxRows)) {
          return (x: x, y: y);
        }
      }
    }

    return null;
  }

  /// Calculates the maximum row index currently used by any item.
  int _calculateMaxUsedRow() {
    int maxRow = 0;
    for (final item in _items.values) {
      final bottomY = item.posY + item.sizeY;
      if (bottomY > maxRow) {
        maxRow = bottomY;
      }
    }
    return maxRow;
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
