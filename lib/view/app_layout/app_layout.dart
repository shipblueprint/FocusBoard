import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:focusboard/view/apps/analytics/analytics_screen.dart';
import 'package:focusboard/view/apps/eisenhower/eisenhower_screen.dart';
import 'package:focusboard/view/apps/kanban/kanban_screen.dart';

/// Root shell hosting the 3 main tabs.
///
/// Uses [IndexedStack] so each tab keeps its state when switching.
class AppLayout extends StatefulWidget {
  const AppLayout({super.key});

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  int _currentIndex = 0;

  static const List<_TabSpec> _tabs = <_TabSpec>[
    _TabSpec(
      name: 'Kanban',
      icon: LucideIcons.layout_panel_top,
      builder: _KanbanTab.new,
    ),
    _TabSpec(
      name: 'Eisenhower',
      icon: LucideIcons.grid_3x3,
      builder: _EisenhowerTab.new,
    ),
    _TabSpec(
      name: 'Analytics',
      icon: LucideIcons.chart_column,
      builder: _AnalyticsTab.new,
    ),
  ];

  void _onTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs
            .map((_TabSpec t) => t.builder())
            .toList(growable: false),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTap,
        destinations: _tabs
            .map(
              (_TabSpec t) => NavigationDestination(
                icon: Icon(t.icon),
                label: t.name,
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec({
    required this.name,
    required this.icon,
    required this.builder,
  });
  final String name;
  final IconData icon;
  final Widget Function() builder;
}

class _KanbanTab extends StatelessWidget {
  const _KanbanTab();
  @override
  Widget build(BuildContext context) => const KanbanScreen();
}

class _EisenhowerTab extends StatelessWidget {
  const _EisenhowerTab();
  @override
  Widget build(BuildContext context) => const EisenhowerScreen();
}

class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab();
  @override
  Widget build(BuildContext context) => const AnalyticsScreen();
}
