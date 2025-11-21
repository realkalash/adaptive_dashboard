import 'package:example/flutter_map_test_widget.dart';
import 'package:flutter/material.dart';
import 'package:adaptive_dashboard/adaptive_dashboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Adaptive Dashboard Demo',
      home: const DashboardDemo(),
    );
  }
}

class DashboardDemo extends StatefulWidget {
  const DashboardDemo({super.key});

  @override
  State<DashboardDemo> createState() => _DashboardDemoState();
}

class _DashboardDemoState extends State<DashboardDemo> {
  bool _editMode = false;
  late final DashboardController controller;

  @override
  void initState() {
    super.initState();
    controller = DashboardController();
    reinitialize();
  }

  void reinitialize() {
    controller.clearCanvas();
    controller.addWidget(DashboardItem(id: '1', type: 'test_text', sizeX: 1, sizeY: 1));
    controller.addWidget(DashboardItem(id: '2', type: 'placeholder', sizeX: 2, sizeY: 2, posX: 1));
    controller.addWidget(
      DashboardItem(id: '3', type: 'flutter_map', sizeX: 2, sizeY: 2, minSizeX: 2, minSizeY: 2, posX: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Dashboard'),
        actions: [
          IconButton(
            icon: Icon(_editMode ? Icons.visibility : Icons.edit),
            onPressed: () => setState(() => _editMode = !_editMode),
          ),
          IconButton(icon: Icon(Icons.refresh), onPressed: reinitialize),
        ],
      ),
      body: AdaptiveDashboardCanvas(
        config: const DashboardConfig(maxColumns: 12, maxRows: null),
        showGrid: true,
        controller: controller,
        editMode: _editMode,
        widgetBuilder: (context, widgetId, item) {
          return _buildWidgetFromType(context, item.type);
        },
      ),
    );
  }

  Widget _buildWidgetFromType(BuildContext context, String type) {
    switch (type) {
      case 'test_text':
        return Text('test text');
      case 'placeholder':
        return Placeholder();
      case 'flutter_map':
        return FlutterMapTestWidget();
    }
    return Placeholder();
  }
}
