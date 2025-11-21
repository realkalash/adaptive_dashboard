# Adaptive Dashboard

A Flutter package for creating responsive, adaptive dashboard layouts where users can drag, resize, and arrange widgets on a grid.

## Features

- 📱 **Responsive Design**: Automatically adapts to screen width based on column configuration.
- 🎨 **Customizable Grid**: Configure columns, rows, and aspect ratios.
- 🖱️ **Interactive Editing**:
    - **Drag & Drop**: Move widgets freely with collision handling (snap-back).
    - **Resizing**: Resize widgets from both bottom-right and top-left corners.
    - **Minimum Size**: Prevents resizing smaller than 1x1 grid cells.
- 📏 **Grid Visualization**: Optional grid lines to help with alignment.
- ⚡ **Optimized Performance**: Efficient O(1) state management for item updates.

## Usage

### Basic Example

```dart
import 'package:flutter/material.dart';
import 'package:adaptive_dashboard/adaptive_dashboard.dart';

class MyDashboard extends StatefulWidget {
  @override
  State<MyDashboard> createState() => _MyDashboardState();
}

class _MyDashboardState extends State<MyDashboard> {
  late final DashboardController controller;
  bool _editMode = false;

  @override
  void initState() {
    super.initState();
    controller = DashboardController();
    
    // Add initial items
    controller.addWidget(DashboardItem(
        id: '1', 
        type: 'chart', 
        sizeX: 4, 
        sizeY: 3, 
        posX: 0, 
        posY: 0
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(_editMode ? Icons.check : Icons.edit),
            onPressed: () => setState(() => _editMode = !_editMode),
          ),
        ],
      ),
      body: AdaptiveDashboardCanvas(
        controller: controller,
        editMode: _editMode,
        showGrid: _editMode, // Show grid lines in edit mode
        config: const DashboardConfig(
          maxColumns: 12,
          itemAspectRatio: 1.0,
        ),
        widgetBuilder: (context, id, item) {
            // Return your custom widget based on item type/id
            return Card(child: Center(child: Text('Item $id')));
        },
      ),
    );
  }
}
```

## API Reference

### AdaptiveDashboardCanvas

The main widget for displaying the grid.

| Property | Type | Description |
|---|---|---|
| `controller` | `DashboardController` | Manages the state of items (add, remove, move, resize). |
| `config` | `DashboardConfig` | Configuration for grid layout (columns, rows, aspect ratio). |
| `widgetBuilder` | `DashboardWidgetBuilder` | Builder function to render content for each item. |
| `editMode` | `bool` | Enables drag and resize interactions. |
| `showGrid` | `bool` | Renders background grid lines for visual guidance. |

### DashboardConfig

| Property | Type | Description |
|---|---|---|
| `maxColumns` | `int` | Total number of columns in the grid. |
| `maxRows` | `int?` | Maximum rows (optional). If null, height expands infinitely. |
| `itemAspectRatio` | `double` | Width/height ratio of a single grid cell. Default is 1.0. |

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  adaptive_dashboard:
    git:
      url: https://github.com/yourusername/adaptive_dashboard.git
```

## Development

### Running the Example

```bash
cd example
flutter run
```

## License

This project is licensed under the MIT License.
