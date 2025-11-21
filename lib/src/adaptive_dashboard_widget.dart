import 'package:flutter/material.dart';
import 'dashboard_config.dart';
import 'dashboard_controller.dart';
import 'dashboard_item.dart';

/// A builder for the content of a dashboard item.
typedef DashboardWidgetBuilder = Widget Function(BuildContext context, String widgetId, DashboardItem item);

/// A responsive dashboard widget that adapts to different screen sizes.
class AdaptiveDashboardCanvas extends StatefulWidget {
  /// Creates an adaptive dashboard.
  const AdaptiveDashboardCanvas({
    super.key,
    required this.config,
    required this.controller,
    required this.widgetBuilder,
    this.editMode = false,
    this.showGrid = false,
  });

  /// The configuration for the dashboard grid.
  final DashboardConfig config;

  /// The controller that manages dashboard items.
  final DashboardController controller;

  /// A builder that provides the widget for each item.
  final DashboardWidgetBuilder widgetBuilder;

  /// Whether the dashboard is in edit mode.
  final bool editMode;

  /// Whether to show grid lines.
  final bool showGrid;

  @override
  State<AdaptiveDashboardCanvas> createState() => _AdaptiveDashboardCanvasState();
}

class _AdaptiveDashboardCanvasState extends State<AdaptiveDashboardCanvas> {
  String? _activeItemId;

  void _onInteractionStart(String id) {
    setState(() {
      _activeItemId = id;
    });
  }

  void _onInteractionEnd(String id) {
    setState(() {
      _activeItemId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final double availableWidth = constraints.maxWidth;
            final int columnCount = widget.config.maxColumns;
            final double cellWidth = availableWidth / columnCount;
            final double cellHeight = cellWidth / widget.config.itemAspectRatio;

            // Calculate total height
            int maxRowIndex = 0;
            if (widget.config.maxRows != null) {
              maxRowIndex = widget.config.maxRows!;
            } else {
              for (final item in widget.controller.items) {
                final bottomY = item.posY + item.sizeY;
                if (bottomY > maxRowIndex) {
                  maxRowIndex = bottomY;
                }
              }
              // Add some padding rows if expanding infinitely
              if (widget.editMode) maxRowIndex += 2;
            }

            final double totalHeight = maxRowIndex * cellHeight;

            // Sort items to ensure the active one is on top (last in list)
            final items = List<DashboardItem>.from(widget.controller.items);
            if (_activeItemId != null) {
              final index = items.indexWhere((i) => i.id == _activeItemId);
              if (index != -1) {
                final activeItem = items.removeAt(index);
                items.add(activeItem);
              }
            }

            return SizedBox(
              height: totalHeight,
              child: Stack(
                children: [
                  if (widget.showGrid)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _GridPainter(
                          cellWidth: cellWidth,
                          cellHeight: cellHeight,
                          rows: maxRowIndex,
                          columns: columnCount,
                          color: Theme.of(context).dividerColor.withOpacity(0.3),
                        ),
                      ),
                    ),
                  for (final item in items)
                    _DashboardItemWrapper(
                      key: ValueKey(item.id),
                      item: item,
                      cellWidth: cellWidth,
                      cellHeight: cellHeight,
                      editMode: widget.editMode,
                      config: widget.config,
                      controller: widget.controller,
                      onInteractionStart: () => _onInteractionStart(item.id),
                      onInteractionEnd: () => _onInteractionEnd(item.id),
                      child: widget.widgetBuilder(context, item.id, item),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({
    required this.cellWidth,
    required this.cellHeight,
    required this.rows,
    required this.columns,
    required this.color,
  });

  final double cellWidth;
  final double cellHeight;
  final int rows;
  final int columns;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw vertical lines
    for (int i = 0; i <= columns; i++) {
      final x = i * cellWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (int i = 0; i <= rows; i++) {
      final y = i * cellHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.cellWidth != cellWidth ||
        oldDelegate.cellHeight != cellHeight ||
        oldDelegate.rows != rows ||
        oldDelegate.columns != columns ||
        oldDelegate.color != color;
  }
}

class _DashboardItemWrapper extends StatefulWidget {
  const _DashboardItemWrapper({
    super.key,
    required this.item,
    required this.cellWidth,
    required this.cellHeight,
    required this.editMode,
    required this.config,
    required this.controller,
    required this.child,
    required this.onInteractionStart,
    required this.onInteractionEnd,
  });

  final DashboardItem item;
  final double cellWidth;
  final double cellHeight;
  final bool editMode;
  final DashboardConfig config;
  final DashboardController controller;
  final Widget child;
  final VoidCallback onInteractionStart;
  final VoidCallback onInteractionEnd;

  @override
  State<_DashboardItemWrapper> createState() => _DashboardItemWrapperState();
}

class _DashboardItemWrapperState extends State<_DashboardItemWrapper> {
  bool _isDragging = false;
  bool _isResizing = false;
  bool _isResizingTopLeft = false;
  Offset _dragOffset = Offset.zero;
  Offset _resizeOffset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final double left = widget.item.posX * widget.cellWidth;
    final double top = widget.item.posY * widget.cellHeight;
    final double width = widget.item.sizeX * widget.cellWidth;
    final double height = widget.item.sizeY * widget.cellHeight;

    // Dragging moves the whole item
    double renderLeft = _isDragging ? left + _dragOffset.dx : left;
    double renderTop = _isDragging ? top + _dragOffset.dy : top;
    double renderWidth = width;
    double renderHeight = height;

    // Resizing
    if (_isResizing) {
      if (_isResizingTopLeft) {
        // When resizing from top-left:
        // 1. The visual position (left, top) shifts by the drag amount
        // 2. The visual size (width, height) shrinks by the drag amount

        double newWidth = width - _resizeOffset.dx;
        double newHeight = height - _resizeOffset.dy;

        // Clamp to minimum size of 1x1 cell
        if (newWidth < widget.cellWidth) {
          newWidth = widget.cellWidth;
          // If clamped, we shouldn't shift the position either for that axis
          // (effectively ignoring the drag beyond the limit)
          // But simply clamping renderLeft to (originalRight - minWidth) is easier.
          renderLeft = (left + width) - newWidth;
        } else {
          renderLeft += _resizeOffset.dx;
        }

        if (newHeight < widget.cellHeight) {
          newHeight = widget.cellHeight;
          renderTop = (top + height) - newHeight;
        } else {
          renderTop += _resizeOffset.dy;
        }

        renderWidth = newWidth;
        renderHeight = newHeight;
      } else {
        // Bottom-right resize only affects width/height
        renderWidth += _resizeOffset.dx;
        renderHeight += _resizeOffset.dy;

        if (renderWidth < widget.cellWidth) renderWidth = widget.cellWidth;
        if (renderHeight < widget.cellHeight) renderHeight = widget.cellHeight;
      }
    }

    final Duration animationDuration = (_isDragging || _isResizing) ? Duration.zero : const Duration(milliseconds: 300);
    final theme = Theme.of(context);

    return AnimatedPositioned(
      duration: animationDuration,
      curve: Curves.easeInOut,
      left: renderLeft,
      top: renderTop,
      width: renderWidth,
      height: renderHeight,
      child: Stack(
        children: [
          SizedBox.expand(
            child: Container(
              margin: const EdgeInsets.all(2),
              // elevation: (_isDragging || _isResizing) ? 8 : 1,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.all(Radius.circular(8)),
                boxShadow: (_isDragging || _isResizing) ? kElevationToShadow[2] : null,
              ),
              child: widget.editMode
                  ? GestureDetector(
                      onPanStart: (_) {
                        setState(() {
                          _isDragging = true;
                          _dragOffset = Offset.zero;
                        });
                        widget.onInteractionStart();
                      },
                      onPanUpdate: (details) => setState(() {
                        _dragOffset += details.delta;
                      }),
                      onPanEnd: (details) => _handleDragEnd(),
                      child: Stack(
                        children: [
                          AbsorbPointer(child: widget.child),
                          const Positioned.fill(child: ColoredBox(color: Colors.transparent)),
                        ],
                      ),
                    )
                  : widget.child,
            ),
          ),
          if (widget.editMode)
            Positioned(
              left: 0,
              top: 0,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeUpLeftDownRight,
                child: GestureDetector(
                  onPanStart: (_) {
                    setState(() {
                      _isResizing = true;
                      _isResizingTopLeft = true;
                      _resizeOffset = Offset.zero;
                    });
                    widget.onInteractionStart();
                  },
                  onPanUpdate: (details) => setState(() {
                    _resizeOffset += details.delta;
                  }),
                  onPanEnd: (_) => _handleResizeEnd(),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.5),
                      borderRadius: const BorderRadius.only(bottomRight: Radius.circular(12)),
                    ),
                    child: const Icon(Icons.drag_handle, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
          if (widget.editMode)
            Positioned(
              right: 0,
              bottom: 0,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeUpLeftDownRight,
                child: GestureDetector(
                  onPanStart: (_) {
                    setState(() {
                      _isResizing = true;
                      _isResizingTopLeft = false;
                      _resizeOffset = Offset.zero;
                    });
                    widget.onInteractionStart();
                  },
                  onPanUpdate: (details) => setState(() {
                    _resizeOffset += details.delta;
                  }),
                  onPanEnd: (_) => _handleResizeEnd(),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.5),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(12)),
                    ),
                    child: const Icon(Icons.drag_handle, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handleDragEnd() {
    setState(() {
      _isDragging = false;
    });
    widget.onInteractionEnd();

    final double finalX = (widget.item.posX * widget.cellWidth) + _dragOffset.dx;
    final double finalY = (widget.item.posY * widget.cellHeight) + _dragOffset.dy;

    final int newGridX = (finalX / widget.cellWidth).round();
    final int newGridY = (finalY / widget.cellHeight).round();

    setState(() {
      _dragOffset = Offset.zero;
    });

    if (newGridX != widget.item.posX || newGridY != widget.item.posY) {
      widget.controller.updateItemPosition(
        widget.item.id,
        newGridX,
        newGridY,
        widget.config.maxColumns,
        maxRows: widget.config.maxRows,
      );
    }
  }

  void _handleResizeEnd() {
    setState(() {
      _isResizing = false;
    });
    widget.onInteractionEnd();

    int newGridX = widget.item.posX;
    int newGridY = widget.item.posY;
    int newSizeX = widget.item.sizeX;
    int newSizeY = widget.item.sizeY;

    if (_isResizingTopLeft) {
      // Calculate new position (top-left corner)
      final double finalX = (widget.item.posX * widget.cellWidth) + _resizeOffset.dx;
      final double finalY = (widget.item.posY * widget.cellHeight) + _resizeOffset.dy;

      newGridX = (finalX / widget.cellWidth).round();
      newGridY = (finalY / widget.cellHeight).round();

      // Calculate new size based on the shift in position
      final int deltaX = newGridX - widget.item.posX;
      final int deltaY = newGridY - widget.item.posY;

      newSizeX = widget.item.sizeX - deltaX;
      newSizeY = widget.item.sizeY - deltaY;
    } else {
      // Standard bottom-right resize
      final double finalWidth = (widget.item.sizeX * widget.cellWidth) + _resizeOffset.dx;
      final double finalHeight = (widget.item.sizeY * widget.cellHeight) + _resizeOffset.dy;

      newSizeX = (finalWidth / widget.cellWidth).round();
      newSizeY = (finalHeight / widget.cellHeight).round();
    }

    // Enforce minimum size of 1x1
    if (newSizeX < 1) newSizeX = 1;
    if (newSizeY < 1) newSizeY = 1;

    setState(() {
      _resizeOffset = Offset.zero;
    });

    if (_isResizingTopLeft) {
      final int originalX = widget.item.posX;
      final int originalY = widget.item.posY;

      // If we clamped size, we might need to adjust the grid X/Y so we don't just "move" without resizing
      // (e.g. if user dragged way past the left edge, we clamped width to 1, so we must ensure
      // newGridX is at most (originalRight - 1)).
      // Actually, if newSizeX was calculated as (sizeX - deltaX) and we clamped it to 1,
      // then deltaX must have been (sizeX - 1).
      // So newGridX = originalX + (sizeX - 1).
      // Let's re-calculate X/Y based on the clamped size if needed.

      // More robust approach:
      // We want the bottom-right corner to stay fixed (roughly) for top-left resize.
      // Right = originalX + originalSizeX
      // NewRight = newGridX + newSizeX
      // We want Right == NewRight => newGridX = originalX + originalSizeX - newSizeX

      // Recalculate grid pos to anchor the bottom-right corner
      newGridX = widget.item.posX + widget.item.sizeX - newSizeX;
      newGridY = widget.item.posY + widget.item.sizeY - newSizeY;

      // Try moving first
      final bool moved = widget.controller.updateItemPosition(
        widget.item.id,
        newGridX,
        newGridY,
        widget.config.maxColumns,
        maxRows: widget.config.maxRows,
      );

      if (moved) {
        final bool resized = widget.controller.updateItemSize(
          widget.item.id,
          newSizeX,
          newSizeY,
          widget.config.maxColumns,
          maxRows: widget.config.maxRows,
        );

        if (!resized) {
          // If resize failed, try to revert move
          widget.controller.updateItemPosition(
            widget.item.id,
            originalX,
            originalY,
            widget.config.maxColumns,
            maxRows: widget.config.maxRows,
          );
        }
      }
    } else {
      // Bottom-right resize
      if (newSizeX != widget.item.sizeX || newSizeY != widget.item.sizeY) {
        widget.controller.updateItemSize(
          widget.item.id,
          newSizeX,
          newSizeY,
          widget.config.maxColumns,
          maxRows: widget.config.maxRows,
        );
      }
    }
  }
}
