import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:aahar_app/theme.dart';
import 'package:aahar_app/services/api_service.dart';

class NpkRecommendationScreen extends StatefulWidget {
  final String farmerName;
  final String fieldName;

  const NpkRecommendationScreen({
    super.key,
    required this.farmerName,
    required this.fieldName,
  });

  @override
  State<NpkRecommendationScreen> createState() =>
      _NpkRecommendationScreenState();
}

class _NpkRecommendationScreenState extends State<NpkRecommendationScreen> {
  Map<String, double>? _currentNpk;
  Map<String, double>? _predictedNpk;
  Map<String, double>? _inputFeatures;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ApiService.getAllData(widget.farmerName, widget.fieldName),
        ApiService.predict(widget.farmerName, widget.fieldName),
      ]);
      final allData = results[0];
      final predictData = results[1];
      if (mounted) {
        setState(() {
          _currentNpk = ApiService.extractCurrentNpk(
              allData, widget.farmerName, widget.fieldName);
          _predictedNpk = ApiService.extractPredictedNpk(predictData);
          _inputFeatures = ApiService.extractInputFeatures(predictData);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('NPK Report / उर्वरक सलाह'),
        actions: [
          IconButton(
            icon: Icon(_isLoading ? Icons.hourglass_top : Icons.refresh),
            onPressed: _isLoading ? null : _fetchData,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppTheme.primaryContainer,
                ),
              )
            : _error != null
                ? _buildErrorState(context)
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 20),
                        _buildNutrientCard(context, 'N', 'Nitrogen (N)',
                            'नाइट्रोजन'),
                        const SizedBox(height: 12),
                        _buildNutrientCard(context, 'P', 'Phosphorus (P)',
                            'फास्फोरस'),
                        const SizedBox(height: 12),
                        _buildNutrientCard(context, 'K', 'Potassium (K)',
                            'पोटेशियम'),
                        const SizedBox(height: 24),
                        _buildNpkBarChart(context),
                        const SizedBox(height: 24),
                        _buildWarningSystem(context),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off,
              color: AppTheme.onSurfaceVariant, size: 40),
          const SizedBox(height: 12),
          Text('Could not load NPK data',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _fetchData,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Retry / पुनः प्रयास',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppTheme.primaryContainer,
                      )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.ambientShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Aahar NPK Report',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          Text(
            'आहार एनपीके रिपोर्ट',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${widget.farmerName} • Field ${widget.fieldName} • Live Data',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientCard(
      BuildContext context, String key, String name, String nameHindi) {
    final current = _currentNpk![key]!;
    final predicted = _predictedNpk![key]!;
    final devPercent = _getDeviationPercent(current, predicted);
    final statusColor = _getDeviationColor(current, predicted);
    final severity = _getDeviationSeverity(current, predicted);
    final statusLabel = _getSeverityLabel(severity);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.eco, color: statusColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text(nameHindi,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusLabel,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Current: ${current.toStringAsFixed(1)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'Predicted: ${predicted.toStringAsFixed(1)}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.statusOptimal,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: predicted > 0
                            ? (current / predicted).clamp(0.0, 1.5)
                            : 0,
                        minHeight: 10,
                        backgroundColor: statusColor.withValues(alpha: 0.12),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(statusColor),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Deviation: ${devPercent > 0 ? '+' : ''}${devPercent.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Current vs Predicted Bar Chart ───
  Widget _buildNpkBarChart(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart,
                  color: AppTheme.primaryContainer, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Current vs Predicted / वर्तमान vs अनुमानित',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildChartLegendDot(
                  context, 'Current', const Color(0xFF1E88E5)),
              const SizedBox(width: 16),
              _buildChartLegendDot(
                  context, 'Predicted', const Color(0xFF43A047)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceEvenly,
                maxY: _chartMaxY(),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 10,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final labels = ['N', 'P', 'K'];
                      final type = rodIndex == 0 ? 'Current' : 'Predicted';
                      return BarTooltipItem(
                        '${labels[groupIndex]} $type\n${rod.toY.toStringAsFixed(1)}',
                        TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const labels = ['N', 'P', 'K'];
                        final idx = value.toInt();
                        if (idx < 0 || idx >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(labels[idx],
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppTheme.outlineVariant.withValues(alpha: 0.25),
                      strokeWidth: 1,
                    );
                  },
                ),
                barGroups: [
                  _makeBarGroup(0, _currentNpk!['N']!, _predictedNpk!['N']!),
                  _makeBarGroup(1, _currentNpk!['P']!, _predictedNpk!['P']!),
                  _makeBarGroup(2, _currentNpk!['K']!, _predictedNpk!['K']!),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeBarGroup(
      int x, double current, double predicted) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: current,
          color: const Color(0xFF1E88E5),
          width: 20,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
        ),
        BarChartRodData(
          toY: predicted,
          color: const Color(0xFF43A047),
          width: 20,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
        ),
      ],
    );
  }

  double _chartMaxY() {
    final values = [
      _currentNpk!['N']!, _currentNpk!['P']!, _currentNpk!['K']!,
      _predictedNpk!['N']!, _predictedNpk!['P']!, _predictedNpk!['K']!,
    ];
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    return (maxVal * 1.3).ceilToDouble();
  }

  Widget _buildChartLegendDot(
      BuildContext context, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 10,
                )),
      ],
    );
  }

  // ─── Actionable Warning System ───
  Widget _buildWarningSystem(BuildContext context) {
    final warnings = _generateWarnings();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.health_and_safety,
                  color: AppTheme.primaryContainer, size: 22),
              const SizedBox(width: 10),
              Text(
                'Actionable Insights / कार्रवाई योग्य',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...warnings,
        ],
      ),
    );
  }

  List<Widget> _generateWarnings() {
    final warnings = <Widget>[];
    final nutrients = ['N', 'P', 'K'];
    final names = {'N': 'Nitrogen', 'P': 'Phosphorus', 'K': 'Potassium'};
    final namesHindi = {
      'N': 'नाइट्रोजन',
      'P': 'फास्फोरस',
      'K': 'पोटेशियम'
    };
    final fertilizers = {
      'N': 'Urea (यूरिया)',
      'P': 'DAP (डीएपी)',
      'K': 'MOP (एमओपी)'
    };

    final rh = _inputFeatures?['RH2M'] ?? 0;
    final dwsi = _inputFeatures?['DWSI'] ?? 0;

    for (final n in nutrients) {
      final current = _currentNpk![n]!;
      final predicted = _predictedNpk![n]!;
      final devPercent = _getDeviationPercent(current, predicted).abs();
      final severity = _getDeviationSeverity(current, predicted);

      if (severity == 'green') continue;

      final isLow = current < predicted;
      final direction = isLow ? 'low' : 'high';
      final severityLabel = severity == 'red' ? 'critically' : 'moderately';
      final colorLabel = severity == 'red' ? 'Red' : 'Yellow';
      final warningColor =
          severity == 'red' ? AppTheme.statusAlert : AppTheme.statusWarning;

      String message =
          'Warning: ${names[n]} is $severityLabel $direction ($colorLabel, ${devPercent.toStringAsFixed(0)}% off).';

      if (isLow && rh > 50) {
        message +=
            ' High humidity detected (RH: ${rh.toStringAsFixed(0)}%) suggesting upcoming rain. Apply ${fertilizers[n]} before the rain to maximize absorption.';
      } else if (isLow && dwsi < 1.0) {
        message +=
            ' Dry conditions detected (DWSI: ${dwsi.toStringAsFixed(2)}). Irrigate before applying ${fertilizers[n]} for better uptake.';
      } else if (!isLow) {
        message +=
            ' Reduce ${names[n]?.toLowerCase()} application. Excess ${namesHindi[n]} can cause nutrient lockout and soil degradation.';
      }

      warnings.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: warningColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: warningColor.withValues(alpha: 0.15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: warningColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    severity == 'red'
                        ? Icons.warning_amber
                        : Icons.info_outline,
                    color: warningColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.6,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (warnings.isEmpty) {
      warnings.add(
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.statusOptimal.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.statusOptimal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check_circle,
                    color: AppTheme.statusOptimal, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'All NPK levels are within optimal range (±10%). No immediate action needed.\nसभी एनपीके स्तर अनुकूल सीमा में हैं।',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.statusOptimal,
                        height: 1.5,
                      ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Weather context
    if (_inputFeatures != null) {
      warnings.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.cloud, size: 14, color: AppTheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Weather: RH ${rh.toStringAsFixed(0)}% • DWSI ${dwsi.toStringAsFixed(2)} • Data via Flask API',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                        fontSize: 9,
                      ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return warnings;
  }

  // ─── Deviation helpers ───
  static double _getDeviationPercent(double current, double predicted) {
    if (predicted == 0) return 0;
    return ((current - predicted) / predicted) * 100;
  }

  static Color _getDeviationColor(double current, double predicted) {
    final dev = _getDeviationPercent(current, predicted).abs();
    if (dev <= 10) return AppTheme.statusOptimal;
    if (dev <= 25) return AppTheme.statusWarning;
    return AppTheme.statusAlert;
  }

  static String _getDeviationSeverity(double current, double predicted) {
    final dev = _getDeviationPercent(current, predicted).abs();
    if (dev <= 10) return 'green';
    if (dev <= 25) return 'yellow';
    return 'red';
  }

  static String _getSeverityLabel(String severity) {
    switch (severity) {
      case 'green':
        return 'Optimal ✓';
      case 'yellow':
        return 'Caution ⚠';
      case 'red':
        return 'Critical ✕';
      default:
        return '';
    }
  }
}
