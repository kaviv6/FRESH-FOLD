import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/detail_app_bar.dart';
import '../../../core/widgets/pill_filter_row.dart';
import '../data/rider_repository.dart';

const _targetStates = ['cleaning', 'ready', 'delivered'];
const _targetStateLabels = {
  'cleaning': 'Cleaning',
  'ready': 'Ready',
  'delivered': 'Delivered',
};

/// Rider — Scan Garment. Wraps `POST /api/v1/garment/scan`, which had no
/// UI before this. The rider picks the stage they're moving garments to,
/// then scans each tag's barcode — the server enforces the linear
/// received→cleaning→ready→delivered transition per garment.
class GarmentScanScreen extends ConsumerStatefulWidget {
  const GarmentScanScreen({super.key});

  @override
  ConsumerState<GarmentScanScreen> createState() => _GarmentScanScreenState();
}

class _GarmentScanScreenState extends ConsumerState<GarmentScanScreen> {
  final _controller = MobileScannerController();
  String _targetState = 'cleaning';
  bool _processing = false;
  String? _lastMessage;
  bool _lastSuccess = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing || capture.barcodes.isEmpty) return;
    final barcode = capture.barcodes.first.rawValue;
    if (barcode == null || barcode.isEmpty) return;

    setState(() => _processing = true);
    await _controller.stop();
    try {
      final garment = await ref.read(riderRepositoryProvider).scanGarment(barcode, _targetState);
      setState(() {
        _lastSuccess = true;
        _lastMessage = '${garment.name} · ${garment.barcode} → ${_targetStateLabels[garment.state] ?? garment.state}';
      });
    } catch (e) {
      setState(() {
        _lastSuccess = false;
        _lastMessage = e is ApiException ? e.toString() : 'Could not process scan.';
      });
    } finally {
      if (mounted) setState(() => _processing = false);
      await Future.delayed(const Duration(milliseconds: 1400));
      if (mounted) await _controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: DetailAppBar(
        title: 'Scan Garment',
        backgroundColor: Colors.black,
        titleColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
            color: Colors.black,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mark scanned garments as', style: AppText.caption(Colors.white70)),
                const SizedBox(height: 8),
                PillFilterRow(
                  options: _targetStates,
                  selected: _targetState,
                  accentColor: AppColors.coral,
                  onSelected: (v) => setState(() => _targetState = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(controller: _controller, onDetect: _onDetect),
                Center(
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                if (_processing)
                  const Center(child: CircularProgressIndicator(color: Colors.white)),
              ],
            ),
          ),
          if (_lastMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              color: _lastSuccess ? AppColors.greenChipBg : AppColors.redChipBg,
              child: Row(
                children: [
                  Icon(
                    _lastSuccess ? Icons.check_circle : Icons.error_outline,
                    size: 18,
                    color: _lastSuccess ? AppColors.greenChipText : AppColors.redChipText,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _lastMessage!,
                      style: AppText.bodySmallBold(_lastSuccess ? AppColors.greenChipText : AppColors.redChipText),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
