import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/location/location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/detail_app_bar.dart';
import '../../../core/widgets/primary_button.dart';

/// Full-screen map picker — the map pans under a fixed center pin;
/// "Confirm Location" returns the pin's coordinate (the map's current
/// center) to the caller. Pushed from AddressFormScreen's "Adjust on Map"
/// action so the customer can drag to their exact doorstep rather than
/// trusting GPS/geocoding alone.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, this.initial});

  /// Starting position — the address's existing coordinates when editing,
  /// or null to open centered on the device's current location instead.
  final LatLng? initial;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _mapController = MapController();

  // Rajkot — the city this module currently serves (see
  // laundry.service.zone) — used only as a last-resort fallback center if
  // there's no existing address and location can't be determined.
  static const _fallbackCenter = LatLng(22.3039, 70.8022);

  bool _locating = false;

  @override
  void initState() {
    super.initState();
    if (widget.initial == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _locateMe(silent: true));
    }
  }

  Future<void> _locateMe({bool silent = false}) async {
    setState(() => _locating = true);
    try {
      final position = await determinePosition();
      _mapController.move(LatLng(position.latitude, position.longitude), 16);
    } catch (e) {
      if (!silent && mounted) {
        final message = e is LocationException ? e.toString() : 'Could not get your location.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _confirm() {
    Navigator.of(context).pop(_mapController.camera.center);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const DetailAppBar(title: 'Set Location'),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initial ?? _fallbackCenter,
              initialZoom: widget.initial != null ? 16 : 13,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.freshfold_app',
              ),
            ],
          ),
          // Fixed center pin — the map moves underneath it. FractionalTranslation
          // shifts the icon up by half its own height so its tip (not its
          // center) lands on the screen's visual center, i.e. the actual
          // coordinate `_mapController.camera.center` refers to.
          const IgnorePointer(
            child: Center(
              child: FractionalTranslation(
                translation: Offset(0, -0.5),
                child: Icon(Icons.location_on, size: 44, color: AppColors.coral),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            top: 14,
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: AppColors.ink900.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Text(
                  'Move the map so the pin marks your exact address',
                  textAlign: TextAlign.center,
                  style: AppText.caption(AppColors.ink600),
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 100,
            child: FloatingActionButton(
              heroTag: 'locate-me',
              mini: true,
              backgroundColor: Colors.white,
              foregroundColor: AppColors.teal,
              onPressed: _locating ? null : () => _locateMe(),
              child: _locating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal),
                    )
                  : const Icon(Icons.my_location),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: SafeArea(
              top: false,
              child: PrimaryButton(label: 'Confirm Location', onPressed: _confirm),
            ),
          ),
        ],
      ),
    );
  }
}
