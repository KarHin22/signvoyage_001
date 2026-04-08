import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:vibration/vibration.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {

  bool _isMalay = false;


  String _streetName = "Locating...";
  String _cityCountry = "Please wait";
  String _latLong = "";
  bool _isLoadingGPS = false;


  bool _isSOSActive = false;
  String _sosStatus = "";


  String _emergencyContactName = "Keluarga / Family";
  String _emergencyContactNumber = "01128283725";

  @override
  void initState() {
    super.initState();
    NotificationService.initialize();
    _autoFetchLocation();
  }

  Future<void> _autoFetchLocation() async {
    setState(() => _isLoadingGPS = true);

    try {
      Position? pos = await LocationService.getCurrentLocation();
      if (pos != null) {
        List<Placemark> placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          setState(() {
            String road = place.thoroughfare ?? "";
            String taman = place.subLocality ?? "";
            if (road.isNotEmpty && taman.isNotEmpty) {
              _streetName = "$road, $taman";
            } else {
              _streetName = road.isNotEmpty ? road : (taman.isNotEmpty ? taman : "Location Found");
            }
            _cityCountry = "${place.locality ?? ''}, ${place.country ?? ''}";
            _latLong = "${pos.latitude.toStringAsFixed(4)}° N, ${pos.longitude.toStringAsFixed(4)}° E";
          });
        }
      }
    } catch (e) {
      print("Auto Location Error: $e");
      setState(() {
        _streetName = "Location Access Required";
        _cityCountry = "Please enable GPS";
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingGPS = false);
      }
    }
  }

  Future<void> _triggerSOS() async {
    setState(() {
      _isSOSActive = true;
      _sosStatus = _isMalay ? "Memulakan amaran..." : "Initializing alerts...";
    });

    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [500, 500, 500, 500], repeat: 0);
    }

    NotificationService.showSOSNotification(_isMalay);

    String currentCity = _cityCountry.split(',').first.trim();
    if (currentCity.isEmpty || currentCity == "Please wait") {
      currentCity = _isMalay ? "Berdekatan" : "Local";
    }

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _sosStatus = _isMalay
        ? "Menghantar ke Hospital $currentCity..."
        : "Sending to $currentCity Hospital...");

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _sosStatus = _isMalay
        ? "Menghantar SMS ke $_emergencyContactName..."
        : "Sending SMS to $_emergencyContactName...");

    _sendEmergencySMS(_emergencyContactNumber);
  }

  void _sendEmergencySMS(String phone) async {
    final String msg = _isMalay
        ? "KECEMASAN! Saya perlukan bantuan di: $_streetName ($_latLong)"
        : "EMERGENCY! I need help at: $_streetName ($_latLong)";
    final Uri uri = Uri.parse("sms:$phone?body=${Uri.encodeComponent(msg)}");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _stopSOS() {
    Vibration.cancel();
    setState(() {
      _isSOSActive = false;
    });
  }

  void _showSettingsDialog() {
    TextEditingController nameCtrl = TextEditingController();
    TextEditingController phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isMalay ? "Tetapan Kenalan" : "Emergency Contact Setup", style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: _isMalay ? "Nama (cth: Ibu)" : "Name (e.g. Mom)",
                hintText: _emergencyContactName,
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: _isMalay ? "Nombor Telefon" : "Phone Number",
                hintText: _emergencyContactNumber,
                prefixIcon: const Icon(Icons.phone),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_isMalay ? "Batal" : "Cancel"),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                if (nameCtrl.text.trim().isNotEmpty) {
                  _emergencyContactName = nameCtrl.text.trim();
                }
                if (phoneCtrl.text.trim().isNotEmpty) {
                  _emergencyContactNumber = phoneCtrl.text.trim();
                }
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isMalay
                      ? "Disimpan: $_emergencyContactName"
                      : "Saved: $_emergencyContactName"),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text(_isMalay ? "Simpan" : "Save"),
          ),
        ],
      ),
    );
  }

  void _showDeafCommunicationCard() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hearing_disabled, size: 80, color: Theme.of(context).colorScheme.onSecondaryContainer),
              const SizedBox(height: 24),
              Text(
                _isMalay ? "SAYA PEKAK\n/ KURANG PENDENGARAN" : "I AM DEAF\n/ HARD OF HEARING",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, height: 1.2),
              ),
              const SizedBox(height: 20),
              Text(
                _isMalay
                    ? "Tolong berkomunikasi dengan saya melalui teks, isyarat tangan, atau menaip di telefon anda."
                    : "Please communicate with me using text, simple gestures, or by typing on your phone.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(_isMalay ? "Tutup" : "Close", style: const TextStyle(fontSize: 18)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showMedicalCard() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_hospital, size: 80, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 24),
              Text(
                _isMalay ? "KECEMASAN\nPERUBATAN" : "MEDICAL\nEMERGENCY",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, height: 1.2, color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 20),
              Text(
                _isMalay
                    ? "Saya memerlukan bantuan perubatan segera. Tolong hubungi ambulans (999) untuk saya."
                    : "I need immediate medical assistance. Please help me call an ambulance (999).",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                  onPressed: () => Navigator.pop(context),
                  child: Text(_isMalay ? "Tutup" : "Close", style: const TextStyle(fontSize: 18, color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
            _isMalay ? 'Sokongan Kecemasan' : 'Emergency Support',
            style: const TextStyle(fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: colorScheme.primary),
            onPressed: _showSettingsDialog,
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _isMalay = !_isMalay;
              });
            },
            child: Text(
                _isMalay ? "EN" : "MS",
                style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16)
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          _buildMainContent(context, colorScheme),
          if (_isSOSActive)
            _buildEmergencyOverlay(colorScheme),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLocationCard(context, colorScheme),
          const SizedBox(height: 30),
          Center(
            child: Column(
              children: [
                _buildSOSButton(colorScheme),
                const SizedBox(height: 16),
                Text(
                    _isMalay ? "Tahan selama 3 saat untuk SOS" : "Hold for 3 seconds to trigger SOS",
                    style: TextStyle(color: colorScheme.outline, fontSize: 13)
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Text(
              _isMalay ? "Kad Bantuan Pantas" : "Quick Help Cards",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface)
          ),
          const SizedBox(height: 12),
          _buildHelpCard(
            context,
            icon: Icons.record_voice_over,
            title: "I am Deaf / Hard of Hearing",
            subtitle: "Saya Pekak / Kurang Pendengaran",
            color: colorScheme.secondaryContainer,
            onTap: _showDeafCommunicationCard,
          ),
          const SizedBox(height: 12),
          _buildHelpCard(
            context,
            icon: Icons.local_hospital,
            title: "Medical Emergency",
            subtitle: "Kecemasan Perubatan",
            color: colorScheme.tertiaryContainer,
            onTap: _showMedicalCard,
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyOverlay(ColorScheme colorScheme) {
    return Container(
      color: Colors.red.withOpacity(0.96),
      width: double.infinity,
      height: double.infinity,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 120, color: Colors.white),
            const SizedBox(height: 30),
            Text(
              _isMalay ? "SOS AKTIF" : "SOS ACTIVE",
              style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(
              _sosStatus,
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const Divider(color: Colors.white24, height: 60, indent: 50, endIndent: 50),
            Text(
              _isMalay ? "Lokasi Semasa:\n$_streetName\n$_latLong" : "Current Location:\n$_streetName\n$_latLong",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: ElevatedButton.icon(
                onPressed: _stopSOS,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  minimumSize: const Size(250, 70),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
                ),
                icon: const Icon(Icons.stop_circle, size: 30),
                label: Text(
                  _isMalay ? "HENTIKAN SOS" : "STOP SOS",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  
  Widget _buildLocationCard(BuildContext context, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () async {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isMalay ? "Mengemas kini lokasi..." : "Updating location...")),
        );
        await _autoFetchLocation();
      },
      child: Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          
          gradient: LinearGradient(
            colors: [
              colorScheme.primaryContainer,
              colorScheme.primaryContainer.withOpacity(0.4),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(color: colorScheme.primary.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: colorScheme.primary,
                child: _isLoadingGPS
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : const Icon(Icons.my_location, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isMalay ? "Lokasi Tepat" : "Precise Location",
                      style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      _streetName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "$_cityCountry\n$_latLong",
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              
              Icon(Icons.refresh, color: colorScheme.primary.withOpacity(0.2), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSOSButton(ColorScheme colorScheme) {
    return GestureDetector(
      onLongPress: _triggerSOS,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.errorContainer.withOpacity(0.2),
        ),
        child: Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [colorScheme.error, const Color(0xFFFF5252)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(color: colorScheme.error.withOpacity(0.4), blurRadius: 20, spreadRadius: 5, offset: const Offset(0, 10))
            ],
          ),
          child: const Center(
            child: Text("SOS", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
          ),
        ),
      ),
    );
  }

  Widget _buildHelpCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(icon, size: 30),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.black.withOpacity(0.6))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}