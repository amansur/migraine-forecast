import 'dart:math' as math;

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../state/settings_provider.dart';

class RiskDisplay extends StatelessWidget {
  final RiskAssessment assessment;
  final RiskDisplayMode mode;
  const RiskDisplay({super.key, required this.assessment, required this.mode});

  @override
  Widget build(BuildContext context) {
    switch (mode) {
      case RiskDisplayMode.gauge:
        return _GaugeDisplay(assessment: assessment);
      case RiskDisplayMode.numeric:
        return _NumericDisplay(assessment: assessment);
      case RiskDisplayMode.weatherIcon:
        return _WeatherIconDisplay(assessment: assessment);
    }
  }
}

class _GaugeDisplay extends StatelessWidget {
  final RiskAssessment assessment;
  const _GaugeDisplay({required this.assessment});

  @override
  Widget build(BuildContext context) {
    final color = colorForBand(assessment.band.name);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 220,
          height: 130,
          child: CustomPaint(
            painter: _GaugePainter(value: assessment.score / 100.0, color: color),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Text(
                  assessment.score.toString(),
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(color: color),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(_bandLabel(assessment.band), style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value; // 0..1
  final Color color;
  _GaugePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final track = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final arc = Paint()
      ..color = color
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromLTWH(8, 8, size.width - 16, (size.height - 16) * 2);
    canvas.drawArc(rect, math.pi, math.pi, false, track);
    canvas.drawArc(rect, math.pi, math.pi * value.clamp(0, 1), false, arc);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) => old.value != value || old.color != color;
}

class _NumericDisplay extends StatelessWidget {
  final RiskAssessment assessment;
  const _NumericDisplay({required this.assessment});

  @override
  Widget build(BuildContext context) {
    final color = colorForBand(assessment.band.name);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          assessment.score.toString(),
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 96,
              ),
        ),
        Text(_bandLabel(assessment.band), style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _WeatherIconDisplay extends StatelessWidget {
  final RiskAssessment assessment;
  const _WeatherIconDisplay({required this.assessment});

  @override
  Widget build(BuildContext context) {
    final color = colorForBand(assessment.band.name);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_iconForBand(assessment.band), size: 96, color: color),
        const SizedBox(height: 8),
        Text(_bandLabel(assessment.band), style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }

  IconData _iconForBand(RiskBand b) {
    switch (b) {
      case RiskBand.low: return Icons.wb_sunny_outlined;
      case RiskBand.moderate: return Icons.cloud_outlined;
      case RiskBand.high: return Icons.thunderstorm_outlined;
      case RiskBand.veryHigh: return Icons.warning_amber_rounded;
    }
  }
}

String _bandLabel(RiskBand b) {
  switch (b) {
    case RiskBand.low: return 'Low';
    case RiskBand.moderate: return 'Moderate';
    case RiskBand.high: return 'High';
    case RiskBand.veryHigh: return 'Very High';
  }
}
