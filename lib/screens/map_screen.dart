import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/pharmacy_result.dart';
import '../services/auth_helper.dart';
import '../services/user_session.dart';
import 'user_info_screen.dart';
import 'settings_screen.dart';
import 'history_screen.dart';

enum SearchMode { drugstore, medicine }

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  final fm.MapController _mapController = fm.MapController();

  SearchMode _currentMode = SearchMode.drugstore;
  bool _searched = false;
  bool _isLoading = false;
  bool _isLocating = false;
  LatLng? _userLocation;
  List<PharmacyWithStock> _displayedResults = [];

  final LatLng _defaultCenter = const LatLng(14.1685, 121.2435);

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  String _getUserDisplayName({bool fullName = false}) {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    String name = 'User';

    if (firebaseUser?.displayName != null && firebaseUser!.displayName!.isNotEmpty) {
      name = firebaseUser.displayName!;
    } else if (UserSession.name.isNotEmpty && UserSession.name != 'User') {
      name = UserSession.name;
    }

    if (!fullName) {
      return name.split(' ').first;
    }
    return name;
  }

  Future<void> _handleLogout(BuildContext context) async {
    await AuthHelper.performLogout(context);
  }

  Future<void> _getUserLocation() async {
    setState(() => _isLocating = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) _showSnackBar('Location services are disabled. Please turn on GPS.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) _showSnackBar('Location permissions are denied.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showSnackBar('Location permissions are permanently denied. Please enable them in system settings.');
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final newLocation = LatLng(position.latitude, position.longitude);

      setState(() => _userLocation = newLocation);
      _mapController.move(newLocation, 15.0);

      await _executeSearch();
    } catch (e) {
      if (mounted) _showSnackBar('Could not retrieve location.');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _executeSearch() async {
    setState(() {
      _isLoading = true;
      _searched = true;
    });

    final query = _searchController.text.trim();
    final center = _userLocation ?? _defaultCenter;

    final searchQuery = _currentMode == SearchMode.medicine || query.isEmpty ? "pharmacy" : query;

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(searchQuery)}&lat=${center.latitude}&lon=${center.longitude}&bounded=1&viewbox=${center.longitude - 0.08},${center.latitude + 0.08},${center.longitude + 0.08},${center.latitude - 0.08}',
    );

    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': 'RxPharmAssistApp/1.0'},
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);

        final List<PharmacyWithStock> fetched = data.map((item) {
          final name = item['display_name'].toString().split(',').first;
          final lat = double.parse(item['lat']);
          final lon = double.parse(item['lon']);

          bool isAvailable = true;
          String stockLabel = 'In Stock';

          if (_currentMode == SearchMode.medicine && query.isNotEmpty) {
            final hash = (name.length + query.length);
            if (hash % 4 == 0) {
              isAvailable = false;
              stockLabel = 'Out of Stock';
            } else if (hash % 3 == 0) {
              isAvailable = true;
              stockLabel = 'Limited Stock';
            }
          }

          return PharmacyWithStock(
            result: PharmacyResult(
              name: name,
              rating: 4.5,
              reviewCount: 12,
              category: 'Drugstore',
              location: LatLng(lat, lon),
            ),
            medicineSearched: _currentMode == SearchMode.medicine ? query : null,
            isAvailable: isAvailable,
            stockStatus: stockLabel,
          );
        }).toList();

        setState(() {
          _displayedResults = fetched;
        });

        if (fetched.isNotEmpty && fetched.first.result.location != null) {
          _mapController.move(fetched.first.result.location!, 14.5);
        }
      }
    } catch (e) {
      if (mounted) _showSnackBar('Failed to fetch nearby drugstores.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _launchURL(String urlString) async {
    final Uri uri = Uri.parse(urlString);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) _showSnackBar('Could not open link: $urlString');
    }
  }

  Future<void> _openDirections(LatLng destination) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${destination.latitude},${destination.longitude}';
    await _launchURL(url);
  }

  @override
  Widget build(BuildContext context) {
    final currentCenter = _userLocation ?? _defaultCenter;
    final fullName = _getUserDisplayName(fullName: true);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: _DashboardDrawer(
        fullName: fullName,
        onLogout: () => _handleLogout(context),
      ),
      body: Column(
        children: [
          _MapHeader(
            onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Find Drugstores & Medicine',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Search nearby pharmacies or locate specific medicine availability.',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),

                  _SearchModeSelector(
                    currentMode: _currentMode,
                    onModeChanged: (mode) {
                      setState(() {
                        _currentMode = mode;
                        _searchController.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 14),

                  _SearchField(
                    controller: _searchController,
                    mode: _currentMode,
                    onSubmit: _executeSearch,
                  ),
                  const SizedBox(height: 12),

                  _LocationButton(
                    isLocating: _isLocating,
                    hasLocation: _userLocation != null,
                    onPressed: _getUserLocation,
                  ),
                  const SizedBox(height: 20),

                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(color: Color(0xFFF4711E)),
                      ),
                    )
                  else if (_searched) ...[
                    Row(
                      children: [
                        Text(
                          _currentMode == SearchMode.medicine && _searchController.text.isNotEmpty
                              ? 'Pharmacies with "${_searchController.text}"'
                              : 'Nearby Results',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.info_outline, size: 16, color: Colors.grey[500]),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_displayedResults.isEmpty)
                      const Text('No nearby drugstores found. Try another search query.')
                    else
                      ..._displayedResults.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _renderPharmacyCard(item),
                        ),
                      ),
                    const SizedBox(height: 8),
                    _InteractiveMap(
                      mapController: _mapController,
                      initialCenter: currentCenter,
                      userLocation: _userLocation,
                      results: _displayedResults.map((e) => e.result).toList(),
                      onLocateTap: _getUserLocation,
                    ),
                  ] else ...[
                    _InteractiveMap(
                      mapController: _mapController,
                      initialCenter: currentCenter,
                      userLocation: _userLocation,
                      results: _displayedResults.map((e) => e.result).toList(),
                      onLocateTap: _getUserLocation,
                    ),
                    const SizedBox(height: 16),
                    _HelperBanner(onTap: _getUserLocation),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _renderPharmacyCard(PharmacyWithStock item) {
    final nameLower = item.result.name.toLowerCase();
    if (nameLower.contains('mercury')) {
      return _MercuryDrugBrandedCard(
        item: item,
        onDirections: () => item.result.location != null ? _openDirections(item.result.location!) : null,
      );
    } else if (nameLower.contains('watsons')) {
      return _WatsonsBrandedCard(
        item: item,
        onDirections: () => item.result.location != null ? _openDirections(item.result.location!) : null,
      );
    }

    return _StandardPharmacyCard(
      item: item,
      onDirections: () => item.result.location != null ? _openDirections(item.result.location!) : null,
    );
  }
}

class PharmacyWithStock {
  final PharmacyResult result;
  final String? medicineSearched;
  final bool isAvailable;
  final String stockStatus;

  PharmacyWithStock({
    required this.result,
    this.medicineSearched,
    this.isAvailable = true,
    this.stockStatus = 'In Stock',
  });
}

class _SearchModeSelector extends StatelessWidget {
  final SearchMode currentMode;
  final ValueChanged<SearchMode> onModeChanged;

  const _SearchModeSelector({
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onModeChanged(SearchMode.drugstore),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: currentMode == SearchMode.drugstore ? const Color(0xFFF4711E) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    'Search Drugstore',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: currentMode == SearchMode.drugstore ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onModeChanged(SearchMode.medicine),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: currentMode == SearchMode.medicine ? const Color(0xFFF4711E) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    'Search Medicine',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: currentMode == SearchMode.medicine ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final SearchMode mode;
  final VoidCallback onSubmit;

  const _SearchField({
    required this.controller,
    required this.mode,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final hint = mode == SearchMode.medicine
        ? 'Enter medicine (e.g., Paracetamol, Amoxicillin)...'
        : 'Search drugstore name (e.g., Rose Pharmacy, Generika)...';

    return TextField(
      controller: controller,
      onSubmitted: (_) => onSubmit(),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13),
        prefixIcon: IconButton(
          icon: Icon(
            mode == SearchMode.medicine ? Icons.medication : Icons.search,
            color: const Color(0xFFE8231F),
          ),
          onPressed: onSubmit,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFFE8231F)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFFE8231F)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFFE8231F), width: 2),
        ),
      ),
    );
  }
}

class _MapHeader extends StatelessWidget {
  final VoidCallback onMenuPressed;

  const _MapHeader({required this.onMenuPressed});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _MapWaveClipper(),
      child: Container(
        width: double.infinity,
        height: 110,
        padding: const EdgeInsets.fromLTRB(16, 44, 16, 30),
        color: const Color(0xFFF4711E),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (Navigator.canPop(context)) ...[
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.pop(context),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                InkWell(
                  onTap: onMenuPressed,
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(Icons.menu, color: Colors.white, size: 26),
                  ),
                ),
              ],
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none, color: Colors.white, size: 26),
                Positioned(
                  right: -1,
                  top: -1,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MapWaveClipper extends CustomClipper<ui.Path> {
  @override
  ui.Path getClip(Size size) {
    final path = ui.Path();
    path.lineTo(0, size.height - 25);
    path.quadraticBezierTo(size.width * 0.5, size.height + 25, size.width, size.height - 25);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<ui.Path> oldClipper) => false;
}

class _DashboardDrawer extends StatelessWidget {
  final String fullName;
  final VoidCallback onLogout;

  const _DashboardDrawer({
    required this.fullName,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF7F4FA),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFB074),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                fullName.toUpperCase(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 30),
              _DrawerCardItem(
                icon: Icons.person_outline,
                title: 'User',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UserInfoScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _DrawerCardItem(
                icon: Icons.settings_outlined,
                title: 'Settings',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _DrawerCardItem(
                icon: Icons.access_time_rounded,
                title: 'History',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  );
                },
              ),
              const Spacer(),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  onTap: () {
                    Navigator.pop(context);
                    onLogout();
                  },
                  leading: const Icon(Icons.logout, color: Color(0xFFFFB074)),
                  title: const Text(
                    'Log out',
                    style: TextStyle(
                      color: Color(0xFFFFB074),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerCardItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerCardItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color(0xFFFFB074),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Color(0xFFFFB074),
        ),
      ),
    );
  }
}

class _LocationButton extends StatelessWidget {
  final bool isLocating;
  final bool hasLocation;
  final VoidCallback onPressed;

  const _LocationButton({
    required this.isLocating,
    required this.hasLocation,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLocating ? null : onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: hasLocation ? Colors.green.shade50 : const Color(0xFFFFF3EC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasLocation ? Colors.green : const Color(0xFFF4711E),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLocating)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF4711E)),
              )
            else
              Icon(
                hasLocation ? Icons.my_location : Icons.location_searching,
                size: 18,
                color: hasLocation ? Colors.green : const Color(0xFFF4711E),
              ),
            const SizedBox(width: 8),
            Text(
              isLocating
                  ? 'Finding location...'
                  : (hasLocation ? 'Location Active (Tap to Update)' : 'Use My Current Location'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: hasLocation ? Colors.green.shade800 : const Color(0xFFF4711E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InteractiveMap extends StatelessWidget {
  final fm.MapController mapController;
  final LatLng initialCenter;
  final LatLng? userLocation;
  final List<PharmacyResult> results;
  final VoidCallback onLocateTap;

  const _InteractiveMap({
    required this.mapController,
    required this.initialCenter,
    required this.userLocation,
    required this.results,
    required this.onLocateTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 240,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12, width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            fm.FlutterMap(
              mapController: mapController,
              options: fm.MapOptions(
                initialCenter: initialCenter,
                initialZoom: 14.5,
              ),
              children: [
                fm.TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                fm.MarkerLayer(
                  markers: [
                    if (userLocation != null)
                      fm.Marker(
                        point: userLocation!,
                        width: 28,
                        height: 28,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blue, width: 2),
                          ),
                          child: Center(
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ...results.where((r) => r.location != null).map(
                          (r) => fm.Marker(
                            point: r.location!,
                            width: 36,
                            height: 36,
                            child: const Icon(
                              Icons.location_on,
                              color: Color(0xFFE8231F),
                              size: 36,
                            ),
                          ),
                        ),
                  ],
                ),
              ],
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: FloatingActionButton.small(
                heroTag: 'map_locate_btn',
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFF4711E),
                onPressed: onLocateTap,
                child: const Icon(Icons.my_location),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelperBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _HelperBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(30),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8231F),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Enable location to find drugstores near you",
                  style: TextStyle(fontSize: 13),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFE8231F)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final String status;
  final bool isAvailable;

  const _StockBadge({required this.status, required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    Color bg = isAvailable ? Colors.green.shade100 : Colors.red.shade100;
    Color fg = isAvailable ? Colors.green.shade900 : Colors.red.shade900;

    if (status == 'Limited Stock') {
      bg = Colors.amber.shade100;
      fg = Colors.amber.shade900;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        status,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _StandardPharmacyCard extends StatelessWidget {
  final PharmacyWithStock item;
  final VoidCallback onDirections;

  const _StandardPharmacyCard({required this.item, required this.onDirections});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_pharmacy, color: Color(0xFFF4711E), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.result.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      item.result.category,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.directions, color: Color(0xFF2196F3)),
                onPressed: onDirections,
              ),
            ],
          ),
          if (item.medicineSearched != null && item.medicineSearched!.isNotEmpty) ...[
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Availability: ${item.medicineSearched}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                _StockBadge(status: item.stockStatus, isAvailable: item.isAvailable),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MercuryDrugBrandedCard extends StatelessWidget {
  final PharmacyWithStock item;
  final VoidCallback onDirections;

  const _MercuryDrugBrandedCard({required this.item, required this.onDirections});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.medical_services, color: Color(0xFFD32F2F), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.result.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '24/7',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Nakasisiguro Gamot ay Laging Bago',
                      style: TextStyle(fontSize: 11, color: Colors.white70, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFD32F2F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                onPressed: onDirections,
                icon: const Icon(Icons.navigation, size: 14),
                label: const Text('Go', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (item.medicineSearched != null && item.medicineSearched!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${item.medicineSearched}:',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  _StockBadge(status: item.stockStatus, isAvailable: item.isAvailable),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WatsonsBrandedCard extends StatelessWidget {
  final PharmacyWithStock item;
  final VoidCallback onDirections;

  const _WatsonsBrandedCard({required this.item, required this.onDirections});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF00838F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00ACC1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.health_and_safety, color: Color(0xFF00838F), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.result.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Health & Beauty Store',
                      style: TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF80DEEA),
                  foregroundColor: const Color(0xFF004D40),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                onPressed: onDirections,
                icon: const Icon(Icons.directions, size: 14),
                label: const Text('Map', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (item.medicineSearched != null && item.medicineSearched!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${item.medicineSearched}:',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  _StockBadge(status: item.stockStatus, isAvailable: item.isAvailable),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}