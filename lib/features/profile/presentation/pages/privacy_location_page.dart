import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/toch_theme.dart';
import '../../../../app/widgets/toch_design_system.dart';

class PrivacyLocationPage extends StatefulWidget {
  const PrivacyLocationPage({this.requestLocationPermission, super.key});

  final Future<LocationPermission> Function()? requestLocationPermission;

  @override
  State<PrivacyLocationPage> createState() => _PrivacyLocationPageState();
}

class _PrivacyLocationPageState extends State<PrivacyLocationPage> {
  bool _isRequestingLocation = false;
  String? _locationStatusMessage;

  Future<void> _requestLocationPermission() async {
    if (_isRequestingLocation) {
      return;
    }

    setState(() {
      _isRequestingLocation = true;
      _locationStatusMessage = null;
    });

    final request =
        widget.requestLocationPermission ?? _requestDeviceLocationPermission;
    final permission = await request();
    if (!mounted) {
      return;
    }

    setState(() {
      _isRequestingLocation = false;
      _locationStatusMessage = _locationMessageFor(permission);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Scaffold(
      backgroundColor: colors.cream,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                  child: Row(
                    children: [
                      TochRoundButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onPressed: () => context.pop(),
                        size: 40,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Privacy en locatie',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
                  children: [
                    const _PrivacyMapPreview(),
                    const SizedBox(height: TochSpacing.md),
                    _PrivacyTile(
                      icon: Icons.my_location_rounded,
                      title: 'Locatie gebruiken',
                      body:
                          'TOCH gebruikt je locatie om activiteiten in de buurt te tonen. Je live locatie wordt niet als eventlocatie opgeslagen.',
                      actionLabel: 'Locatie toestaan',
                      isBusy: _isRequestingLocation,
                      statusMessage: _locationStatusMessage,
                      onActionPressed: _requestLocationPermission,
                    ),
                    const _PrivacyTile(
                      icon: Icons.place_outlined,
                      title: 'Meetingplek',
                      body:
                          'Bij een activiteit wordt alleen de plek opgeslagen die de organisator zelf kiest, zoals een plein, cafe of adres.',
                    ),
                    const _PrivacyTile(
                      icon: Icons.phone_android_rounded,
                      title: 'Telefoonstatus',
                      body:
                          'Je telefoonnummer wordt alleen gebruikt om je account te bevestigen. Andere gebruikers zien je nummer niet.',
                    ),
                    const _PrivacyTile(
                      icon: Icons.analytics_outlined,
                      title: 'Analytics',
                      body:
                          'Analytics mag geen telefoonnummer, chattekst, exacte GPS of vrije rapporttekst bevatten.',
                    ),
                    const _PrivacyTile(
                      icon: Icons.flag_outlined,
                      title: 'Meldingen en blokkades',
                      body:
                          'Rapporten, blokkades en moderatiegegevens zijn afgeschermd en niet publiek zichtbaar.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<LocationPermission> _requestDeviceLocationPermission() async {
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.unableToDetermine) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.deniedForever) {
    await Geolocator.openAppSettings();
  }

  return permission;
}

String _locationMessageFor(LocationPermission permission) {
  return switch (permission) {
    LocationPermission.always ||
    LocationPermission.whileInUse => 'Locatie is toegestaan.',
    LocationPermission.denied =>
      'Locatie is geweigerd. Je kunt dit later opnieuw toestaan.',
    LocationPermission.deniedForever =>
      'Locatie is permanent geweigerd. Pas dit aan via app-instellingen.',
    LocationPermission.unableToDetermine =>
      'Locatiestatus kon niet worden bepaald. Probeer het opnieuw.',
  };
}

class _PrivacyMapPreview extends StatelessWidget {
  const _PrivacyMapPreview();

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return ClipRRect(
      borderRadius: BorderRadius.circular(TochRadius.lg),
      child: SizedBox(
        height: 170,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFD4DDD6),
                gradient: LinearGradient(
                  colors: [colors.green100, const Color(0xFFC4D1D8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            CustomPaint(painter: _PrivacyMapPainter(colors)),
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: colors.green.withValues(alpha: .18),
                      spreadRadius: 8,
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const SizedBox.square(dimension: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyMapPainter extends CustomPainter {
  const _PrivacyMapPainter(this.colors);

  final TochTokens colors;

  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = const Color(0xFFB8C4BA)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final smallRoad = Paint()
      ..color = const Color(0xFFC2CEBD)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, size.height * .42),
      Offset(size.width, size.height * .56),
      road,
    );
    canvas.drawLine(
      Offset(size.width * .36, 0),
      Offset(size.width * .44, size.height),
      road,
    );
    canvas.drawLine(
      Offset(0, size.height * .72),
      Offset(size.width, size.height * .65),
      smallRoad,
    );
    canvas.drawCircle(
      Offset(size.width * .2, size.height * .55),
      22,
      Paint()..color = colors.orange,
    );
    canvas.drawCircle(
      Offset(size.width * .72, size.height * .32),
      20,
      Paint()..color = colors.verified,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PrivacyTile extends StatelessWidget {
  const _PrivacyTile({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.statusMessage,
    this.isBusy = false,
    this.onActionPressed,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final String? statusMessage;
  final bool isBusy;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Padding(
      padding: const EdgeInsets.only(bottom: TochSpacing.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(TochRadius.lg),
          boxShadow: TochShadows.card(colors),
        ),
        child: Padding(
          padding: const EdgeInsets.all(TochSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: colors.green, size: 24),
              const SizedBox(width: TochSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.green700.withValues(alpha: .72),
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (statusMessage != null) ...[
                      const SizedBox(height: TochSpacing.sm),
                      Text(
                        statusMessage!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.green,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                    if (actionLabel != null) ...[
                      const SizedBox(height: TochSpacing.sm),
                      FilledButton(
                        onPressed: isBusy ? null : onActionPressed,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 42),
                          shape: const StadiumBorder(),
                        ),
                        child: isBusy
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(actionLabel!),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
