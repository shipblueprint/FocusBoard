import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/analytics_service.dart';
import '../services/task_manager.dart';
import '../services/eisenhower_task_manager.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late AnalyticsService _analyticsService;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeAnalytics();
  }

  Future<void> _initializeAnalytics() async {
    try {
      final taskManager = TaskManager();
      final eisenhowerManager = EisenhowerTaskManager();
      
      await taskManager.loadTasks();
      await eisenhowerManager.loadTasks();
      
      _analyticsService = AnalyticsService(taskManager, eisenhowerManager);
      await _analyticsService.refreshAnalytics();
      
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
    final stats = _analyticsService.getQuickStats();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(stats),
          const SizedBox(height: 24),
          _buildCompletionChart(),
          const SizedBox(height: 24),
          _buildColumnDistribution(),
          const SizedBox(height: 24),
          _buildPriorityAnalysis(),
          const SizedBox(height: 24),
          _buildEisenhowerAnalysis(),
          const SizedBox(height: 16),
          _buildLastUpdated(),
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
        _buildSummaryCard('Total Tasks', stats['total']?.toString() ?? '0', Colors.blue),
        _buildSummaryCard('Completed', stats['completed']?.toString() ?? '0', Colors.green),
        _buildSummaryCard('Pending', stats['pending']?.toString() ?? '0', Colors.orange),
        _buildSummaryCard('Completion Rate', '${stats['completionRate'] ?? '0.0'}%', Colors.purple),
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

  Widget _buildCompletionChart() {
    final stats = _analyticsService.getQuickStats();
    final completionRate = double.tryParse(stats['completionRate']?.toString() ?? '0') ?? 0;
    
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

  Widget _buildColumnDistribution() {
    final columnData = _analyticsService.getColumnChartData();
    
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
            ...columnData.map((data) => _buildBarChartItem(
              data['column'] as String,
              data['count'] as int,
              columnData.fold(0, (sum, item) => sum + (item['count'] as int)),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityAnalysis() {
    final priorityData = _analyticsService.getPriorityChartData();
    
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
            ...priorityData.map((data) => _buildPieChartItem(
              data['priority'] as String,
              data['count'] as int,
              priorityData.fold(0, (sum, item) => sum + (item['count'] as int)),
              data['priority'] == 'High Priority' ? Colors.red : Colors.blue,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildEisenhowerAnalysis() {
    final eisenhowerData = _analyticsService.getEisenhowerChartData();
    
    if (eisenhowerData.isEmpty) return const SizedBox.shrink();
    
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
            ...eisenhowerData.map((data) => _buildPieChartItem(
              data['quadrant'] as String,
              data['count'] as int,
              eisenhowerData.fold(0, (sum, item) => sum + (item['count'] as int)),
              Color(int.parse((data['color'] as String).substring(1), radix: 16) + 0xFF000000),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartItem(String label, int value, int total) {
    final percentage = total > 0 ? (value / total) : 0.0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
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
              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple.shade400),
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

  Widget _buildLastUpdated() {
    final lastUpdated = _analyticsService.currentAnalytics?.lastUpdated;
    
    if (lastUpdated == null) return const SizedBox.shrink();
    
    return Center(
      child: Text(
        'Last updated: ${_formatDateTime(lastUpdated)}',
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 12,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}