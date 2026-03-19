// lib/screens/home_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/watering_event.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double>   _pulseAnimation;

  bool _watering = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleWaterNow() async {
    if (_watering) return;
    setState(() => _watering = true);
    try {
      await FirebaseService.triggerManualWatering();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Watering command sent',
                style: GoogleFonts.inter(fontSize: 14)),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not reach device. Check internet.',
                style: GoogleFonts.inter(fontSize: 14)),
            backgroundColor: AppColors.statusRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _watering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<PlantStatus>(
        stream: FirebaseService.statusStream(),
        builder: (context, snapshot) {
          final status = snapshot.data ?? PlantStatus.empty();
          final connected = snapshot.hasData &&
              snapshot.connectionState == ConnectionState.active;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(connected),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (status.alert.isNotEmpty) ...[
                      _buildAlertBanner(status.alert),
                      const SizedBox(height: 16),
                    ],
                    _buildMoistureCard(status),
                    const SizedBox(height: 16),
                    _buildReservoirCard(status),
                    const SizedBox(height: 16),
                    _buildLastWateredCard(status),
                    const SizedBox(height: 28),
                    _buildWaterButton(),
                    const SizedBox(height: 16),
                    _buildHistoryButton(context),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── App Bar ──────────────────────────────────────────────────────────────

  SliverAppBar _buildAppBar(bool connected) {
    return SliverAppBar(
      floating:           true,
      backgroundColor:    AppColors.background,
      surfaceTintColor:   AppColors.background,
      expandedHeight:     80,
      collapsedHeight:    60,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Leaf icon
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.eco_rounded,
                  color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Text('Lumo',
                style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const Spacer(),
            // Connection dot
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: connected
                    ? AppColors.statusGreen.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: connected
                          ? AppColors.statusGreen
                          : AppColors.textHint,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    connected ? 'Live' : 'Offline',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: connected
                            ? AppColors.statusGreen
                            : AppColors.textHint),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Alert Banner ─────────────────────────────────────────────────────────

  Widget _buildAlertBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.statusAmber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.statusAmber.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.statusAmber, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.statusAmber,
                    fontWeight: FontWeight.w500)),
          ),
          GestureDetector(
            onTap: FirebaseService.clearAlert,
            child: const Icon(Icons.close_rounded,
                color: AppColors.statusAmber, size: 16),
          ),
        ],
      ),
    );
  }

  // ── Moisture Card ────────────────────────────────────────────────────────

  Widget _buildMoistureCard(PlantStatus status) {
    return _Card(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Soil Moisture',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(status.moistureLabel,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          color: _moistureColor(status.moisture),
                          fontWeight: FontWeight.w500)),
                ],
              ),
              // Moisture percentage in a circle
              ScaleTransition(
                scale: _pulseAnimation,
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background circle
                      SizedBox.expand(
                        child: CustomPaint(
                          painter: _ArcPainter(
                            value: status.moisture / 100,
                            color: _moistureColor(status.moisture),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${status.moisture}',
                            style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary),
                          ),
                          Text(
                            '%',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: status.moisture / 100,
              minHeight: 8,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                  _moistureColor(status.moisture)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Dry', style: Theme.of(context).textTheme.bodyMedium),
              Text('Wet', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }

  Color _moistureColor(int pct) {
    if (pct >= 60) return AppColors.statusGreen;
    if (pct >= 35) return AppColors.statusAmber;
    return AppColors.statusRed;
  }

  // ── Reservoir Card ───────────────────────────────────────────────────────

  Widget _buildReservoirCard(PlantStatus status) {
    final (icon, color, label, sublabel) = switch (status.reservoir) {
      'EMPTY' => (
          Icons.water_drop_outlined,
          AppColors.statusRed,
          'Empty',
          'Please refill the reservoir'
        ),
      'FULL' => (
          Icons.water_rounded,
          AppColors.statusAmber,
          'Full',
          'Check for overflow risk'
        ),
      _ => (
          Icons.water_drop_rounded,
          AppColors.statusGreen,
          'Good',
          'Reservoir has enough water'
        ),
    };

    return _Card(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reservoir',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 2),
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ],
            ),
          ),
          Text(sublabel,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ── Last Watered ─────────────────────────────────────────────────────────

  Widget _buildLastWateredCard(PlantStatus status) {
    return _Card(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.history_rounded,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Last Watered',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 2),
              Text(status.lastWatered,
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Water Button ─────────────────────────────────────────────────────────

  Widget _buildWaterButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _watering ? null : _handleWaterNow,
        icon: _watering
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.water_drop_rounded, size: 20),
        label: Text(_watering ? 'Watering…' : 'Water Now'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _watering
              ? AppColors.primary.withValues(alpha: 0.7)
              : AppColors.primary,
        ),
      ),
    );
  }

  // ── History Button ───────────────────────────────────────────────────────

  Widget _buildHistoryButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HistoryScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timeline_rounded,
                color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text(
              'View Watering History',
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.primary, size: 13),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Reusable Card
// ─────────────────────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Arc / Gauge painter
// ─────────────────────────────────────────────────────────────────────────────
class _ArcPainter extends CustomPainter {
  final double value; // 0.0 – 1.0
  final Color  color;
  const _ArcPainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 5;
    const stroke = 6.0;

    // Background track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.surfaceVariant
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    // Foreground arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,           // start from top
      2 * math.pi * value,    // sweep angle
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.value != value || old.color != color;
}
