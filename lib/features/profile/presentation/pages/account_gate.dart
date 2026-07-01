import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/toch_theme.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/account_trust_service.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/profile_trust.dart';

class AccountGate extends StatefulWidget {
  const AccountGate({required this.child, super.key});

  final Widget child;

  static void resetSessionCache() {
    _AccountGateState.resetSessionCache();
  }

  @override
  State<AccountGate> createState() => _AccountGateState();
}

class _AccountGateState extends State<AccountGate> {
  late Future<ProfileTrust> _trustFuture = _syncTrust();

  static String? _sessionUserKey;
  static ProfileTrust? _sessionTrust;
  static Future<ProfileTrust>? _sessionTrustFuture;

  static void resetSessionCache() {
    _sessionUserKey = null;
    _sessionTrust = null;
    _sessionTrustFuture = null;
  }

  Future<ProfileTrust> _syncTrust({bool forceRefresh = false}) {
    final userKey = _currentGateUserKey(context);
    final cachedTrust = _sessionTrust;
    if (!forceRefresh &&
        _sessionUserKey == userKey &&
        cachedTrust != null &&
        cachedTrust.phoneVerified) {
      return Future.value(cachedTrust);
    }

    final currentFuture = _sessionTrustFuture;
    if (!forceRefresh && _sessionUserKey == userKey && currentFuture != null) {
      return currentFuture;
    }

    _sessionUserKey = userKey;
    late final Future<ProfileTrust> future;
    future = sl<AccountTrustService>()
        .syncTrust()
        .then((trust) {
          if (trust.phoneVerified) {
            _sessionUserKey = userKey;
            _sessionTrust = trust;
          }
          return trust;
        })
        .whenComplete(() {
          if (identical(_sessionTrustFuture, future)) {
            _sessionTrustFuture = null;
          }
        });
    _sessionTrustFuture = future;
    return future;
  }

  void _retry() {
    setState(() {
      _trustFuture = _syncTrust(forceRefresh: true);
    });
  }

  void _complete(ProfileTrust trust) {
    if (trust.phoneVerified) {
      _sessionUserKey = _currentGateUserKey(context);
      _sessionTrust = trust;
      _sessionTrustFuture = null;
    }
    setState(() {
      _trustFuture = Future.value(trust);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProfileTrust>(
      future: _trustFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _AccountGateLoading();
        }

        final trust = snapshot.data;
        if (snapshot.hasError || trust == null) {
          return _AccountGateError(onRetry: _retry);
        }

        if (!trust.phoneVerified) {
          return _PhoneVerificationPage(onCompleted: _complete);
        }

        return widget.child;
      },
    );
  }
}

class _PhoneVerificationPage extends StatefulWidget {
  const _PhoneVerificationPage({required this.onCompleted});

  final ValueChanged<ProfileTrust> onCompleted;

  @override
  State<_PhoneVerificationPage> createState() => _PhoneVerificationPageState();
}

class _PhoneVerificationPageState extends State<_PhoneVerificationPage> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  bool _codeRequested = false;
  bool _isBusy = false;
  String? _message;
  String? _normalizedPhone;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    final phone = _normalizePhone(_phoneController.text);
    if (!_isValidE164Phone(phone)) {
      setState(() {
        _message = 'Vul een geldig telefoonnummer in, bijvoorbeeld 0612345678.';
      });
      return;
    }

    setState(() {
      _isBusy = true;
      _message = null;
    });

    try {
      await sl<AccountTrustService>().requestPhoneCode(phone);
      setState(() {
        _normalizedPhone = phone;
        _codeRequested = true;
        _message = tochFakePhoneVerificationEnabled
            ? 'Ontwikkelcode klaar. Vul een code van minimaal 4 tekens in.'
            : 'We hebben een SMS-code gestuurd.';
      });
      AnalyticsService.instance.track(
        'phone_verification_code_requested',
        properties: {'fake_mode': tochFakePhoneVerificationEnabled},
      );
    } catch (error, stackTrace) {
      AppLogger.debug(
        'Phone verification request failed in account gate',
        error: error,
        stackTrace: stackTrace,
      );
      setState(() {
        _message = _phoneRequestErrorMessage(error);
      });
      AnalyticsService.instance.track(
        'phone_verification_code_request_failed',
        properties: {'fake_mode': tochFakePhoneVerificationEnabled},
      );
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _verifyCode() async {
    final phone = _normalizedPhone ?? _normalizePhone(_phoneController.text);
    final token = _codeController.text.trim();
    if (!_isValidE164Phone(phone) || token.length < 4) {
      setState(() {
        _message = 'Vul de SMS-code in die je hebt ontvangen.';
      });
      return;
    }

    setState(() {
      _isBusy = true;
      _message = null;
    });

    try {
      final trust = await sl<AccountTrustService>().verifyPhoneCode(
        phoneNumber: phone,
        token: token,
      );
      if (!trust.phoneVerified) {
        setState(() {
          _message = 'Telefoon is nog niet bevestigd. Probeer de code opnieuw.';
        });
        AnalyticsService.instance.track(
          'phone_verification_failed',
          properties: {'fake_mode': tochFakePhoneVerificationEnabled},
        );
        return;
      }
      AnalyticsService.instance.track(
        'phone_verification_completed',
        properties: {'fake_mode': tochFakePhoneVerificationEnabled},
      );
      widget.onCompleted(trust);
    } catch (error, stackTrace) {
      AppLogger.debug(
        'Phone verification check failed in account gate',
        error: error,
        stackTrace: stackTrace,
      );
      setState(() {
        _message = _phoneVerifyErrorMessage(error);
      });
      AnalyticsService.instance.track(
        'phone_verification_failed',
        properties: {'fake_mode': tochFakePhoneVerificationEnabled},
      );
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Scaffold(
      backgroundColor: colors.cream,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: TochShadows.raised(colors),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.green100,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: SizedBox.square(
                          dimension: 64,
                          child: Icon(
                            Icons.sms_outlined,
                            color: colors.green,
                            size: 34,
                          ),
                        ),
                      ),
                      const SizedBox(height: TochSpacing.md),
                      Text(
                        'Bevestig je telefoonnummer',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: colors.ink,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: TochSpacing.xs),
                      Text(
                        tochFakePhoneVerificationEnabled
                            ? 'Testmodus: we sturen nu geen echte sms. Gebruik dit alleen tijdens testen.'
                            : 'Dit helpt wegwerpaccounts en spam beperken. Je nummer wordt veilig bevestigd.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colors.ink3,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                      if (tochFakePhoneVerificationEnabled) ...[
                        const SizedBox(height: TochSpacing.md),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.orangeSoft,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(TochSpacing.md),
                            child: Text(
                              'Gebruik na Code sturen bijvoorbeeld 1234. In productie werkt dit niet.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: colors.ink2,
                                    fontWeight: FontWeight.w800,
                                    height: 1.35,
                                  ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: TochSpacing.lg),
                      TextField(
                        controller: _phoneController,
                        enabled: !_isBusy && !_codeRequested,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Telefoonnummer',
                          hintText: '0612345678',
                        ),
                      ),
                      if (_codeRequested) ...[
                        const SizedBox(height: TochSpacing.md),
                        TextField(
                          controller: _codeController,
                          enabled: !_isBusy,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: tochFakePhoneVerificationEnabled
                                ? 'Ontwikkelcode'
                                : 'SMS-code',
                            hintText: '123456',
                          ),
                          onSubmitted: (_) => _verifyCode(),
                        ),
                      ],
                      if (_message != null) ...[
                        const SizedBox(height: TochSpacing.md),
                        Text(
                          _message!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.green700),
                        ),
                      ],
                      const SizedBox(height: TochSpacing.lg),
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton.icon(
                          onPressed: _isBusy
                              ? null
                              : _codeRequested
                              ? _verifyCode
                              : _requestCode,
                          icon: _isBusy
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  _codeRequested
                                      ? Icons.verified_user_outlined
                                      : Icons.send_to_mobile_outlined,
                                ),
                          label: Text(
                            _codeRequested ? 'Code controleren' : 'Code sturen',
                          ),
                        ),
                      ),
                      if (_codeRequested) ...[
                        const SizedBox(height: TochSpacing.sm),
                        Center(
                          child: TextButton(
                            onPressed: _isBusy
                                ? null
                                : () {
                                    setState(() {
                                      _codeRequested = false;
                                      _normalizedPhone = null;
                                      _codeController.clear();
                                      _message = null;
                                    });
                                  },
                            child: const Text('Nummer aanpassen'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountGateLoading extends StatelessWidget {
  const _AccountGateLoading();

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Scaffold(
      backgroundColor: colors.cream,
      body: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(26),
            boxShadow: TochShadows.card(colors),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [CircularProgressIndicator(color: colors.green)],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountGateError extends StatelessWidget {
  const _AccountGateError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Scaffold(
      backgroundColor: colors.cream,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: TochShadows.raised(colors),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.green100,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: SizedBox.square(
                          dimension: 64,
                          child: Icon(
                            Icons.phone_android_outlined,
                            color: colors.green,
                            size: 34,
                          ),
                        ),
                      ),
                      const SizedBox(height: TochSpacing.md),
                      Text(
                        'Verificatiestatus onbekend',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: colors.ink,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: TochSpacing.xs),
                      Text(
                        'We kunnen je telefoonstatus nu niet controleren.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colors.ink3,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: TochSpacing.lg),
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton.icon(
                          onPressed: onRetry,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Opnieuw proberen'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _normalizePhone(String input) {
  final compact = input.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  if (compact.startsWith('+')) {
    return compact;
  }
  if (compact.startsWith('00')) {
    return '+${compact.substring(2)}';
  }
  if (compact.startsWith('0')) {
    return '+31${compact.substring(1)}';
  }
  return compact;
}

bool _isValidE164Phone(String phone) {
  return RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(phone);
}

String _phoneRequestErrorMessage(Object error) {
  if (error is AccountTrustException) {
    return error.message;
  }

  final message = error.toString().toLowerCase();
  if (message.contains('rate') || message.contains('too many')) {
    return 'Er zijn te veel codes aangevraagd. Wacht even en probeer opnieuw.';
  }
  if (message.contains('sms') ||
      message.contains('provider') ||
      message.contains('disabled') ||
      message.contains('not enabled')) {
    return 'Telefoonverificatie is nu nog niet beschikbaar. Probeer het later opnieuw.';
  }
  if (message.contains('phone') || message.contains('invalid')) {
    return 'Controleer het telefoonnummer en probeer opnieuw.';
  }

  return 'Code sturen lukt nu niet. Probeer het later opnieuw.';
}

String _phoneVerifyErrorMessage(Object error) {
  if (error is AccountTrustException) {
    return error.message;
  }

  final message = error.toString().toLowerCase();
  if (message.contains('expired')) {
    return 'Deze code is verlopen. Vraag een nieuwe code aan.';
  }
  if (message.contains('invalid') || message.contains('token')) {
    return 'Deze code klopt niet. Controleer de code opnieuw.';
  }

  return 'Code controleren lukt nu niet. Probeer het opnieuw.';
}

String _currentGateUserKey(BuildContext context) {
  try {
    final state = context.read<AuthBloc>().state;
    if (state is AuthAuthenticated && state.user.id.isNotEmpty) {
      return state.user.id;
    }
  } catch (_) {
    // Tests and early app startup can build the gate without an AuthBloc.
  }
  return '__unknown_user__';
}
