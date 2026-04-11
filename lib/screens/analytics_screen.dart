import 'package:flutter/material.dart';
import '../services/analytics_service.dart';
import '../services/task_manager.dart';
import '../services/eisenhower_task_manager.dart';
import '../config/kanban_config.dart';
import '../config/eisenhower_config.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late AnalyticsService _analyticsService;
  late TaskManager _taskManager;
  late EisenhowerTaskManager _eisenhowerManager;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeAnalytics();
  }

  Future<void> _initializeAnalytics() async {
    try {
      _taskManager = TaskManager();
      _eisenhowerManager = EisenhowerTaskManager();
      _analyticsService = AnalyticsService();
      
      await _taskManager.loadTasks();
      await _eisenhowerManager.loadTasks();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load analytics: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    await _initializeAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Analytics'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshData,
            tooltip: 'Refresh Analytics',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _buildAnalyticsContent(),
    );
  }

  Widget _buildAnalyticsContent() {
    final kanbanStats = _analyticsService.getKanbanAnalytics(_taskManager);
    final eisenhowerStats = _analyticsService.getEisenhowerAnalytics(_eisenhowerManager);
    final combinedStats = _analyticsService.getCombinedAnalytics(_taskManager, _eisenhowerManager);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(combinedStats),
          const SizedBox(height: 24),
          _buildCompletionChart(combinedStats),
          const SizedBox(height: 24),
          _buildColumnDistribution(kanbanStats),
          const SizedBox(height: 24),
          _buildPriorityAnalysis(kanbanStats),
          const SizedBox(height: 24),
          _buildEisenhowerAnalysis(eisenhowerStats),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildSummaryCard('Total Tasks', stats['totalTasks']?.toString() ?? '0', Colors.blue),
        _buildSummaryCard('Completed', stats['totalCompleted']?.toString() ?? '0', Colors.green),
        _buildSummaryCard('Pending', ((stats['totalTasks'] as int) - (stats['totalCompleted'] as int)).toString(), Colors.orange),
        _buildSummaryCard('Completion Rate', '${(stats['overallCompletionRate'] as double).toStringAsFixed(1)}%', Colors.purple),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.8), color],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionChart(Map<String, dynamic> stats) {
    final completionRate = stats['overallCompletionRate'] as double;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Task Completion Progress',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: completionRate / 100,
                minHeight: 20,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${completionRate.toStringAsFixed(1)}% Complete',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumnDistribution(Map<String, dynamic> stats) {
    final distribution = stats['columnDistribution'] as Map<String, int>;
    final total = distribution.values.fold(0, (sum, count) => sum + count);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tasks by Column',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...KanbanConfig.columns.map((column) => _buildBarChartItem(
              column,
              distribution[column] ?? 0,
              total,
              KanbanConfig.columnColors[column] ?? Colors.grey,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityAnalysis(Map<String, dynamic> stats) {
    final highPriority = stats['highPriorityTasks'] as int;
    final total = stats['totalTasks'] as int;
    final normal = total - highPriority;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Priority Distribution',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPieChartItem('High Priority', highPriority, total, Colors.red),
            _buildPieChartItem('Normal', normal, total, Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildEisenhowerAnalysis(Map<String, dynamic> stats) {
    final distribution = stats['quadrantDistribution'] as Map<String, int>;
    final total = distribution.values.fold(0, (sum, count) => sum + count);
    
    if (total == 0) return const SizedBox.shrink();
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Eisenhower Matrix Distribution',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...EisenhowerQuadrant.values.map((quadrant) {
              final name = EisenhowerConfig.getQuadrantName(quadrant);
              return _buildPieChartItem(
                name,
                distribution[name] ?? 0,
                total,
                EisenhowerConfig.getQuadrantColor(quadrant, false),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartItem(String label, int value, int total, Color color) {
    final percentage = total > 0 ? (value / total) : 0.0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(KanbanConfig.columnIcons[label] ?? Icons.list, size: 16, color: color),
                  const SizedBox(width: 8),
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
              Text('$value', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartItem(String label, int value, int total, Color color) {
    final percentage = total > 0 ? (value / total) * 100 : 0.0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Text('$value (${percentage.toStringAsFixed(1)}%)', 
               style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
