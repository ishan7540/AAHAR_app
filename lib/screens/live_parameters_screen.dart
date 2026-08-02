import 'package:flutter/material.dart';
import 'package:aahar_app/theme.dart';
import 'package:aahar_app/services/api_service.dart';

class LiveParametersScreen extends StatefulWidget {
  final String farmerName;
  final String fieldName;

  const LiveParametersScreen({
    super.key,
    required this.farmerName,
    required this.fieldName,
  });

  @override
  State<LiveParametersScreen> createState() => _LiveParametersScreenState();
}

class _LiveParametersScreenState extends State<LiveParametersScreen> {
  Map<String, double>? _features;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchParameters();
  }

  Future<void> _fetchParameters() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data =
          await ApiService.predict(widget.farmerName, widget.fieldName);
      if (mounted) {
        setState(() {
          _features = ApiService.extractInputFeatures(data);
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
        title: const Text('Live Field Parameters'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(_isLoading ? Icons.hourglass_top : Icons.refresh),
            onPressed: _isLoading ? null : _fetchParameters,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(context),
            const SizedBox(height: 20),

            if (_isLoading)
              const SizedBox(
                height: 300,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppTheme.primaryContainer,
                  ),
                ),
              )
            else if (_error != null)
              _buildErrorState(context)
            else if (_features != null) ...[
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.35,
                ),
                itemCount: _features!.length,
                itemBuilder: (context, index) {
                  final entry = _features!.entries.elementAt(index);
                  return _buildParameterCard(
                      context, entry.key, entry.value, index);
                },
              ),
              const SizedBox(height: 20),
              _buildConnectivityFooter(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.secondaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.monitor_heart,
                color: AppTheme.secondary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.farmerName} • Field ${widget.fieldName}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _isLoading
                            ? AppTheme.statusWarning
                            : (_error != null
                                ? AppTheme.statusAlert
                                : AppTheme.statusOptimal),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isLoading
                          ? 'Fetching...'
                          : (_error != null ? 'Error' : 'Live / लाइव'),
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: _isLoading
                                    ? AppTheme.statusWarning
                                    : (_error != null
                                        ? AppTheme.statusAlert
                                        : AppTheme.statusOptimal),
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Data from /predict API • 14 parameters',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParameterCard(
      BuildContext context, String name, double value, int index) {
    final meta = _getParamMeta(name);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: meta.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(meta.icon, color: meta.color, size: 18),
              ),
              const Spacer(),
              Icon(Icons.trending_flat,
                  size: 16, color: AppTheme.onSurfaceVariant),
            ],
          ),
          const Spacer(),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value.toStringAsFixed(
                      value == value.roundToDouble() ? 0 : 2),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: meta.color,
                      ),
                ),
                TextSpan(
                  text: meta.unit.isNotEmpty ? ' ${meta.unit}' : '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: meta.color.withValues(alpha: 0.7),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            meta.shortName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                  height: 1.3,
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off,
                color: AppTheme.onSurfaceVariant, size: 40),
            const SizedBox(height: 12),
            Text('Could not load parameters',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _fetchParameters,
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
      ),
    );
  }

  Widget _buildConnectivityFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppTheme.statusOptimal,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Field Connectivity Active',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppTheme.primaryContainer,
                      ),
                ),
                Text(
                  'Connected to Flask API • Port 5001',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.wifi, color: AppTheme.statusOptimal, size: 20),
        ],
      ),
    );
  }

  _ParamMeta _getParamMeta(String key) {
    final map = {
      'ARI': _ParamMeta('ARI', Icons.eco, const Color(0xFF2E7D32), ''),
      'CAI': _ParamMeta('CAI', Icons.forest, const Color(0xFF388E3C), ''),
      'CIRE': _ParamMeta('CIRE', Icons.spa, const Color(0xFF558B2F), ''),
      'DWSI': _ParamMeta('DWSI', Icons.waves, const Color(0xFF0288D1), ''),
      'EC (microsiemens per cm)': _ParamMeta(
          'EC', Icons.flash_on, const Color(0xFF6A1B9A), 'μS/cm'),
      'EVI': _ParamMeta('EVI', Icons.grass, const Color(0xFF388E3C), ''),
      'GCVI': _ParamMeta('GCVI', Icons.park, const Color(0xFF2E7D32), ''),
      'MCARI':
          _ParamMeta('MCARI', Icons.local_florist, const Color(0xFF689F38), ''),
      'PS': _ParamMeta(
          'Surface Pressure', Icons.speed, const Color(0xFF4527A0), 'kPa'),
      'RH2M': _ParamMeta(
          'Rel. Humidity', Icons.water_drop, const Color(0xFF0277BD), '%'),
      'SIPI': _ParamMeta('SIPI', Icons.wb_sunny, const Color(0xFFFF8F00), ''),
      'T2M': _ParamMeta(
          'Air Temp', Icons.thermostat, const Color(0xFFE65100), '°C'),
      'Temperature (Centigrate)': _ParamMeta(
          'Soil Temp', Icons.thermostat_auto, const Color(0xFF6D4C41), '°C'),
      'pH': _ParamMeta('pH', Icons.science, const Color(0xFF5D4037), ''),
    };
    return map[key] ?? _ParamMeta(key, Icons.analytics, const Color(0xFF546E7A), '');
  }
}

class _ParamMeta {
  final String shortName;
  final IconData icon;
  final Color color;
  final String unit;

  _ParamMeta(this.shortName, this.icon, this.color, this.unit);
}
