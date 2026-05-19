import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox
    hide Size;

const _mapboxAccessToken = String.fromEnvironment('MAPBOX_ACCESS_TOKEN');
const _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080',
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (_mapboxAccessToken.isNotEmpty) {
    mapbox.MapboxOptions.setAccessToken(_mapboxAccessToken);
  }
  runApp(const BebazoteApp());
}

class BebazoteApp extends StatelessWidget {
  const BebazoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bebazote',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF05A357),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F7F4),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

class DemoAuthService {
  static const email = 'rider@bebazote.app';
  static const password = 'demo123';

  Future<bool> signIn({
    required String enteredEmail,
    required String enteredPassword,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return enteredEmail.trim().toLowerCase() == email &&
        enteredPassword == password;
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = DemoAuthService();
  final _emailController = TextEditingController(text: DemoAuthService.email);
  final _passwordController = TextEditingController(
    text: DemoAuthService.password,
  );
  var _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final ok = await _auth.signIn(
      enteredEmail: _emailController.text,
      enteredPassword: _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const RideHomeScreen()),
      );
    } else {
      setState(() => _error = 'Use rider@bebazote.app / demo123 for now.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.local_taxi,
                    size: 54,
                    color: Color(0xFF05A357),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Bebazote',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF17221B),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Book quick rides around town',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF58635C),
                        ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.mail_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    onSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _loading ? null : _submit,
                    icon: _loading
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_forward),
                    label: const Text('Sign in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RideHomeScreen extends StatefulWidget {
  const RideHomeScreen({super.key});

  @override
  State<RideHomeScreen> createState() => _RideHomeScreenState();
}

class _RideHomeScreenState extends State<RideHomeScreen> {
  final _api = const RideApiClient(baseUrl: _apiBaseUrl);
  final _pickupController = TextEditingController(text: 'Kongowe, Kibaha');
  final _dropoffController = TextEditingController(text: 'Mathias, Kibaha');
  RideType _rideType = RideType.standard;
  RideQuote _quote = const RideQuote(
    etaMinutes: 4,
    priceKes: 620,
    distanceKm: 6.8,
    apiBaseUrl: _apiBaseUrl,
  );
  var _loadingQuote = false;
  String _status = 'Drivers nearby';

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

  Future<void> _estimate() async {
    setState(() {
      _loadingQuote = true;
      _status = 'Checking fare...';
    });

    final quote = await _api.quote(
      pickup: _pickupController.text,
      dropoff: _dropoffController.text,
      rideType: _rideType,
    );

    if (!mounted) return;
    setState(() {
      _quote = quote;
      _loadingQuote = false;
      _status = 'Quote refreshed';
    });
  }

  Future<void> _requestRide() async {
    setState(() => _status = 'Requesting ride...');
    final status = await _api.requestRide(
      pickup: _pickupController.text,
      dropoff: _dropoffController.text,
      rideType: _rideType,
    );
    if (!mounted) return;
    setState(() => _status = status);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Request sent to Go backend at ${_quote.apiBaseUrl}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: RideMap()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () {},
                    icon: const Icon(Icons.menu),
                    label: const Text('Bebazote'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () {},
                    icon: const Icon(Icons.person_outline),
                    label: const Text('Rider'),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: RideBookingPanel(
              pickupController: _pickupController,
              dropoffController: _dropoffController,
              rideType: _rideType,
              quote: _quote,
              status: _status,
              loadingQuote: _loadingQuote,
              onRideTypeChanged: (value) {
                setState(() => _rideType = value);
                _estimate();
              },
              onEstimate: _estimate,
              onRequestRide: _requestRide,
            ),
          ),
        ],
      ),
    );
  }
}

class RideMap extends StatelessWidget {
  const RideMap({super.key});

  @override
  Widget build(BuildContext context) {
    if (_mapboxAccessToken.isEmpty) {
      return const MapFallback();
    }

    return mapbox.MapWidget(
      key: const ValueKey('mapbox-map'),
      cameraOptions: mapbox.CameraOptions(
        center: mapbox.Point(coordinates: mapbox.Position(36.8219, -1.2921)),
        zoom: 12.8,
        bearing: -18,
        pitch: 42,
      ),
      styleUri: mapbox.MapboxStyles.MAPBOX_STREETS,
    );
  }
}

class MapFallback extends StatelessWidget {
  const MapFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFFE6ECE7)),
      child: CustomPaint(
        painter: _RoutePainter(),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.only(bottom: 180),
            child: _MapTokenNotice(),
          ),
        ),
      ),
    );
  }
}

class _MapTokenNotice extends StatelessWidget {
  const _MapTokenNotice();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            blurRadius: 20,
            color: Color(0x22000000),
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          'Add MAPBOX_ACCESS_TOKEN to show live Mapbox',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class RideBookingPanel extends StatelessWidget {
  const RideBookingPanel({
    super.key,
    required this.pickupController,
    required this.dropoffController,
    required this.rideType,
    required this.quote,
    required this.status,
    required this.loadingQuote,
    required this.onRideTypeChanged,
    required this.onEstimate,
    required this.onRequestRide,
  });

  final TextEditingController pickupController;
  final TextEditingController dropoffController;
  final RideType rideType;
  final RideQuote quote;
  final String status;
  final bool loadingQuote;
  final ValueChanged<RideType> onRideTypeChanged;
  final VoidCallback onEstimate;
  final VoidCallback onRequestRide;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 16,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Where to?',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  Text(
                    status,
                    style: const TextStyle(
                      color: Color(0xFF05A357),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _LocationField(
                controller: pickupController,
                icon: Icons.my_location,
                label: 'Pickup',
              ),
              const SizedBox(height: 10),
              _LocationField(
                controller: dropoffController,
                icon: Icons.flag_outlined,
                label: 'Drop-off',
              ),
              const SizedBox(height: 14),
              SegmentedButton<RideType>(
                segments: const [
                  ButtonSegment(
                    value: RideType.boda,
                    icon: Icon(Icons.two_wheeler),
                    label: Text('Boda'),
                  ),
                  ButtonSegment(
                    value: RideType.standard,
                    icon: Icon(Icons.local_taxi),
                    label: Text('Car'),
                  ),
                  ButtonSegment(
                    value: RideType.comfort,
                    icon: Icon(Icons.airline_seat_recline_extra),
                    label: Text('Comfort'),
                  ),
                ],
                selected: {rideType},
                onSelectionChanged: (values) => onRideTypeChanged(values.first),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _QuoteMetric(
                      label: 'ETA',
                      value: '${quote.etaMinutes} min',
                    ),
                  ),
                  Expanded(
                    child: _QuoteMetric(
                      label: 'Distance',
                      value: '${quote.distanceKm.toStringAsFixed(1)} km',
                    ),
                  ),
                  Expanded(
                    child: _QuoteMetric(
                      label: 'Fare',
                      value: 'KES ${quote.priceKes}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: loadingQuote ? null : onEstimate,
                    tooltip: 'Refresh quote',
                    icon: loadingQuote
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onRequestRide,
                      icon: const Icon(Icons.near_me),
                      label: const Text('Request ride'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationField extends StatelessWidget {
  const _LocationField({
    required this.controller,
    required this.icon,
    required this.label,
  });

  final TextEditingController controller;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}

class _QuoteMetric extends StatelessWidget {
  const _QuoteMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: const Color(0xFF69736C),
              ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFCAD6CE)
      ..strokeWidth = 1;
    for (var x = -size.height; x < size.width + size.height; x += 58) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        gridPaint,
      );
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        gridPaint,
      );
    }

    final routePaint = Paint()
      ..color = const Color(0xFF05A357)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * 0.24, size.height * 0.42)
      ..cubicTo(
        size.width * 0.38,
        size.height * 0.28,
        size.width * 0.56,
        size.height * 0.60,
        size.width * 0.73,
        size.height * 0.44,
      );
    canvas.drawPath(path, routePaint);

    final pointPaint = Paint()..color = const Color(0xFF17221B);
    canvas.drawCircle(
      Offset(size.width * 0.24, size.height * 0.42),
      10,
      pointPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.73, size.height * 0.44),
      10,
      pointPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum RideType { boda, standard, comfort }

class RideQuote {
  const RideQuote({
    required this.etaMinutes,
    required this.priceKes,
    required this.distanceKm,
    required this.apiBaseUrl,
  });

  final int etaMinutes;
  final int priceKes;
  final double distanceKm;
  final String apiBaseUrl;
}

class RideApiClient {
  const RideApiClient({required this.baseUrl});

  final String baseUrl;

  Future<RideQuote> quote({
    required String pickup,
    required String dropoff,
    required RideType rideType,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/quotes'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'pickup': pickup,
              'dropoff': dropoff,
              'rideType': rideType.apiValue,
            }),
          )
          .timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return RideQuote(
          etaMinutes: json['etaMinutes'] as int,
          priceKes: json['priceKes'] as int,
          distanceKm: (json['distanceKm'] as num).toDouble(),
          apiBaseUrl: baseUrl,
        );
      }
    } catch (_) {
      // Keep the app usable while the local Go backend is stopped.
    }

    return _fallbackQuote(rideType);
  }

  Future<String> requestRide({
    required String pickup,
    required String dropoff,
    required RideType rideType,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/rides'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'pickup': pickup,
              'dropoff': dropoff,
              'rideType': rideType.apiValue,
              'riderId': 'hardcoded_supabase_user',
            }),
          )
          .timeout(const Duration(seconds: 2));

      if (response.statusCode == 202) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return (json['status'] as String).replaceAll('_', ' ');
      }
    } catch (_) {
      return 'Offline demo request saved';
    }

    return 'Request failed';
  }

  RideQuote _fallbackQuote(RideType rideType) {
    final multiplier = switch (rideType) {
      RideType.boda => 0.62,
      RideType.standard => 1.0,
      RideType.comfort => 1.35,
    };
    return RideQuote(
      etaMinutes: rideType == RideType.boda ? 3 : 5,
      priceKes: (620 * multiplier).round(),
      distanceKm: 6.8,
      apiBaseUrl: baseUrl,
    );
  }
}

extension RideTypeApi on RideType {
  String get apiValue {
    return switch (this) {
      RideType.boda => 'boda',
      RideType.standard => 'standard',
      RideType.comfort => 'comfort',
    };
  }
}
