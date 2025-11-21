/// Configuration for the [AdaptiveDashboardCanvas].
class DashboardConfig {
  /// Creates a dashboard configuration.
  const DashboardConfig({required this.maxColumns, this.maxRows, this.itemAspectRatio = 1.0});

  /// The maximum number of columns in the grid.
  ///
  /// This determines the width density of items.
  final int maxColumns;

  /// The maximum number of rows in the grid.
  ///
  /// If null, the grid expands infinitely as needed.
  final int? maxRows;

  /// The aspect ratio (width / height) of a single grid cell.
  ///
  /// Defaults to 1.0 (square).
  final double itemAspectRatio;
}
