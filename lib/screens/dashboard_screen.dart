import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:aahar_app/theme.dart';
import 'package:aahar_app/services/weather_service.dart';
import 'package:aahar_app/services/api_service.dart';
import 'package:aahar_app/screens/soil_data_screen.dart';
import 'package:aahar_app/screens/live_parameters_screen.dart';
import 'package:aahar_app/screens/npk_recommendation_screen.dart';
import 'package:aahar_app/screens/alerts_screen.dart';
import 'package:aahar_app/screens/chatbot_screen.dart';
import 'package:aahar_app/screens/disease_detection_screen.dart';
import 'package:aahar_app/screens/community_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String farmerName;
  final String fieldName;

  const DashboardScreen({
    super.key,
    required this.farmerName,
    required this.fieldName,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<DailyRainfall>? _rainfallData;
  CurrentWeather? _currentWeather;
  bool _isLoadingWeather = true;
  String? _weatherError;

  // Field Analysis live data
  Map<String, double>? _currentNpk;
  Map<String, double>? _predictedNpk;
  Map<String, double>? _inputFeatures;
  bool _isLoadingFieldAnalysis = true;
  String? _fieldAnalysisError;

  @override
  void initState() {
    super.initState();
    _fetchWeatherData();
    _fetchFieldAnalysis();
  }

  Future<void> _fetchWeatherData() async {
    try {
      final results = await Future.wait([
        WeatherService.fetchDailyRainfall(),
        WeatherService.fetchCurrentWeather(),
      ]);
      if (mounted) {
        setState(() {
          _rainfallData = results[0] as List<DailyRainfall>;
          _currentWeather = results[1] as CurrentWeather;
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _weatherError = e.toString();
          _isLoadingWeather = false;
        });
      }
    }
  }

  Future<void> _fetchFieldAnalysis() async {
    setState(() {
      _isLoadingFieldAnalysis = true;
      _fieldAnalysisError = null;
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
          _isLoadingFieldAnalysis = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fieldAnalysisError = e.toString();
          _isLoadingFieldAnalysis = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreetingCard(context),
              const SizedBox(height: 16),
              _buildAlertBanner(context),
              const SizedBox(height: 20),
              _buildRainfallForecast(context),
              const SizedBox(height: 20),
              _buildActionGrid(context),
              const SizedBox(height: 20),
              _buildFieldAnalysis(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingCard(BuildContext context) {
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
              Text(
                'Aahar',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.water_drop,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _currentWeather != null
                          ? '${_currentWeather!.humidity.toStringAsFixed(0)}%'
                          : '...',
                      style:
                          Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: Colors.white,
                              ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Namaste / नमस्ते',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.farmerName,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.landscape, color: Colors.white70, size: 14),
                const SizedBox(width: 6),
                Text(
                  'Field ${widget.fieldName}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBanner(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AlertsScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.errorContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.notifications_active,
                color: AppTheme.error,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'View Alerts / सूचनाएं देखें',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.onErrorContainer,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Weather & NPK alerts • Tap to view',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.onErrorContainer.withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.onErrorContainer),
          ],
        ),
      ),
    );
  }

  // ─── Live Rainfall Forecast (OpenWeatherMap API) ───
  Widget _buildRainfallForecast(BuildContext context) {
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rainfall Forecast',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'वर्षा पूर्वानुमान • Patiala, Punjab',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              // Refresh button
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isLoadingWeather = true;
                    _weatherError = null;
                  });
                  _fetchWeatherData();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isLoadingWeather ? Icons.hourglass_top : Icons.refresh,
                    color: AppTheme.primaryContainer,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Current weather summary
          if (_currentWeather != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.secondaryContainer.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.thermostat,
                      size: 16, color: AppTheme.secondary),
                  const SizedBox(width: 6),
                  Text(
                    '${_currentWeather!.temperature.toStringAsFixed(1)}°C',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppTheme.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.water_drop,
                      size: 14, color: AppTheme.secondary),
                  const SizedBox(width: 4),
                  Text(
                    '${_currentWeather!.humidity.toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppTheme.secondary,
                        ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _currentWeather!.description,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Chart area
          if (_isLoadingWeather)
            SizedBox(
              height: 180,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: AppTheme.primaryContainer,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Fetching weather data...',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            )
          else if (_weatherError != null)
            Container(
              height: 180,
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off,
                        color: AppTheme.onSurfaceVariant, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'Could not load weather data',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isLoadingWeather = true;
                          _weatherError = null;
                        });
                        _fetchWeatherData();
                      },
                      child: Text(
                        'Tap to retry',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: AppTheme.secondary,
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_rainfallData != null && _rainfallData!.isNotEmpty)
            _buildRainfallChart(context, _rainfallData!),
        ],
      ),
    );
  }

  Widget _buildRainfallChart(
      BuildContext context, List<DailyRainfall> rainfall) {
    // Calculate max for Y-axis (at least 5mm so bars are visible)
    final maxRain = rainfall.fold<double>(
        0.0, (max, r) => r.rainfallMm > max ? r.rainfallMm : max);
    final chartMaxY = (maxRain < 5 ? 5.0 : maxRain * 1.3).ceilToDouble();

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: chartMaxY,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipRoundedRadius: 10,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final day = rainfall[group.x];
                    return BarTooltipItem(
                      '${day.dayName}\n${day.rainfallMm} mm',
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
                    reservedSize: 38,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= rainfall.length) {
                        return const SizedBox.shrink();
                      }
                      final day = rainfall[idx];
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              day.dayName,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            Text(
                              '${day.date.day}/${day.date.month}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    fontSize: 8,
                                    color: AppTheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    interval: chartMaxY > 20
                        ? (chartMaxY / 4).ceilToDouble()
                        : 5,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toStringAsFixed(0),
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(fontSize: 9),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: chartMaxY > 20
                    ? (chartMaxY / 4).ceilToDouble()
                    : 5,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: AppTheme.outlineVariant.withValues(alpha: 0.25),
                    strokeWidth: 1,
                  );
                },
              ),
              barGroups: rainfall.asMap().entries.map((entry) {
                final i = entry.key;
                final r = entry.value;
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: r.rainfallMm,
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: r.rainfallMm > 0
                            ? [AppTheme.primaryContainer, AppTheme.secondary]
                            : [
                                AppTheme.outlineVariant.withValues(alpha: 0.3),
                                AppTheme.outlineVariant.withValues(alpha: 0.3),
                              ],
                      ),
                      width: 28,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Total rainfall summary
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.water, size: 16, color: AppTheme.secondary),
              const SizedBox(width: 8),
              Text(
                'Total forecast: ${rainfall.fold<double>(0, (sum, r) => sum + r.rainfallMm).toStringAsFixed(1)} mm',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              Text(
                'via OpenWeather',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                      fontSize: 9,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Main Actions / मुख्य क्रियाएं',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.9,
          children: [
            _ActionButton(
              icon: Icons.science,
              label: 'Soil Data',
              labelHindi: 'मिट्टी का डेटा',
              color: const Color(0xFF5D4037),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SoilDataScreen()),
                );
              },
            ),
            _ActionButton(
              icon: Icons.monitor_heart,
              label: 'Live Params',
              labelHindi: 'लाइव पैरामीटर',
              color: const Color(0xFF0277BD),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => LiveParametersScreen(
                            farmerName: widget.farmerName,
                            fieldName: widget.fieldName,
                          )),
                );
              },
            ),
            _ActionButton(
              icon: Icons.grass,
              label: 'NPK Guide',
              labelHindi: 'उर्वरक सलाह',
              color: const Color(0xFF2E7D32),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => NpkRecommendationScreen(
                            farmerName: widget.farmerName,
                            fieldName: widget.fieldName,
                          )),
                );
              },
            ),
            _ActionButton(
              icon: Icons.smart_toy,
              label: 'Krishi AI',
              labelHindi: 'सहायक',
              color: const Color(0xFF6A1B9A),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ChatbotScreen()),
                );
              },
            ),
            _ActionButton(
              icon: Icons.search,
              label: 'Detect Disease',
              labelHindi: 'रोग पहचान',
              color: const Color(0xFFE65100),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const DiseaseDetectionScreen()),
                );
              },
            ),
            _ActionButton(
              icon: Icons.groups,
              label: 'Community',
              labelHindi: 'किसान समुदाय',
              color: const Color(0xFF00838F),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CommunityScreen()),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  // ─── Live Field Analysis with NPK comparison + warnings ───
  Widget _buildFieldAnalysis(BuildContext context) {
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Field ${widget.fieldName} Analysis',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.farmerName} • Current vs Predicted NPK',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _fetchFieldAnalysis,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isLoadingFieldAnalysis
                        ? Icons.hourglass_top
                        : Icons.refresh,
                    color: AppTheme.primaryContainer,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_isLoadingFieldAnalysis)
            const SizedBox(
              height: 120,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppTheme.primaryContainer,
                ),
              ),
            )
          else if (_fieldAnalysisError != null)
            _buildFieldAnalysisError(context)
          else if (_currentNpk != null && _predictedNpk != null) ...[
            // NPK comparison cards
            Row(
              children: [
                _buildNpkComparisonCard(context, 'N',
                    _currentNpk!['N']!, _predictedNpk!['N']!),
                const SizedBox(width: 12),
                _buildNpkComparisonCard(context, 'P',
                    _currentNpk!['P']!, _predictedNpk!['P']!),
                const SizedBox(width: 12),
                _buildNpkComparisonCard(context, 'K',
                    _currentNpk!['K']!, _predictedNpk!['K']!),
              ],
            ),
            const SizedBox(height: 12),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendDot(context, '±10%', AppTheme.statusOptimal),
                const SizedBox(width: 14),
                _buildLegendDot(context, '±10-25%', AppTheme.statusWarning),
                const SizedBox(width: 14),
                _buildLegendDot(context, '>25%', AppTheme.statusAlert),
              ],
            ),
            const SizedBox(height: 16),
            // Actionable warnings
            ..._buildWarnings(context),
          ],
        ],
      ),
    );
  }

  Widget _buildFieldAnalysisError(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off,
                color: AppTheme.onSurfaceVariant, size: 28),
            const SizedBox(height: 8),
            Text('Could not load field data',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _fetchFieldAnalysis,
              child: Text('Tap to retry',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.secondary,
                      )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNpkComparisonCard(
      BuildContext context, String symbol, double current, double predicted) {
    final color = _getNpkDeviationColor(current, predicted);
    final deviation = _getDeviationPercent(current, predicted);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              symbol,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              current.toStringAsFixed(1),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            Text(
              'Ideal: ${predicted.toStringAsFixed(1)}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color.withValues(alpha: 0.7),
                    fontSize: 9,
                  ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${deviation > 0 ? '+' : ''}${deviation.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendDot(BuildContext context, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.onSurfaceVariant,
                fontSize: 9,
              ),
        ),
      ],
    );
  }

  List<Widget> _buildWarnings(BuildContext context) {
    final warnings = <Widget>[];
    final nutrients = ['N', 'P', 'K'];
    final names = {'N': 'Nitrogen', 'P': 'Phosphorus', 'K': 'Potassium'};

    for (final n in nutrients) {
      final current = _currentNpk![n]!;
      final predicted = _predictedNpk![n]!;
      final devPercent = _getDeviationPercent(current, predicted).abs();
      final severity = _getDeviationSeverity(current, predicted);

      if (severity == 'red' || severity == 'yellow') {
        final isLow = current < predicted;
        final direction = isLow ? 'low' : 'high';
        final severityLabel = severity == 'red' ? 'critically' : 'moderately';
        final colorLabel = severity == 'red' ? 'Red' : 'Yellow';

        String message =
            '${names[n]} is $severityLabel $direction ($colorLabel, ${devPercent.toStringAsFixed(0)}% deviation).';

        // Add weather-based actionable advice
        if (_inputFeatures != null) {
          final rh = _inputFeatures!['RH2M'] ?? 0;
          final dwsi = _inputFeatures!['DWSI'] ?? 0;

          if (isLow && rh > 50) {
            message +=
                ' High humidity detected (RH: ${rh.toStringAsFixed(0)}%) suggesting upcoming rain. Apply ${names[n]?.toLowerCase()}-rich fertilizer before the rain to maximize absorption.';
          } else if (isLow && dwsi < 1.0) {
            message +=
                ' Dry conditions (DWSI: ${dwsi.toStringAsFixed(2)}). Irrigate before applying ${names[n]?.toLowerCase()} fertilizer for better uptake.';
          } else if (!isLow) {
            message +=
                ' Consider reducing ${names[n]?.toLowerCase()} application. Excess can cause nutrient lockout.';
          }
        }

        final warningColor =
            severity == 'red' ? AppTheme.statusAlert : AppTheme.statusWarning;

        warnings.add(
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: warningColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: warningColor.withValues(alpha: 0.15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  severity == 'red'
                      ? Icons.warning_amber
                      : Icons.info_outline,
                  color: warningColor,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.onSurface.withValues(alpha: 0.8),
                          height: 1.5,
                        ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    if (warnings.isEmpty) {
      warnings.add(
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.statusOptimal.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle,
                  color: AppTheme.statusOptimal, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'All NPK levels are within optimal range. No action needed.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.statusOptimal,
                        height: 1.4,
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

  // ─── NPK deviation helpers ───
  static double _getDeviationPercent(double current, double predicted) {
    if (predicted == 0) return 0;
    return ((current - predicted) / predicted) * 100;
  }

  static Color _getNpkDeviationColor(double current, double predicted) {
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
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String labelHindi;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.labelHindi,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.subtleShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
            ),
            Text(
              labelHindi,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 9,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
