import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  var _isLogin = true;
  var _obscurePass = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthProvider>();

    if (_isLogin) {
      await auth.signIn(_emailCtrl.text.trim(), _passwordCtrl.text);
    } else {
      final ok = await auth.signUp(_emailCtrl.text.trim(), _passwordCtrl.text);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Account created! Check your email to verify, then sign in.',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
            ),
            backgroundColor: AppColors.success,
          ),
        );
        setState(() => _isLogin = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Gradient backdrop ────────────────────────────────
          Positioned(
            top: -size.height * 0.15,
            left: -size.width * 0.3,
            child: Container(
              width: size.width * 1.6,
              height: size.height * 0.55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                children: [
                  const SizedBox(height: 32),

                  // Logo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.self_improvement_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  )
                      .animate()
                      .scale(
                          delay: 100.ms,
                          duration: 500.ms,
                          curve: Curves.elasticOut),

                  const SizedBox(height: 20),

                  Text(
                    'PrayerWalk',
                    style: GoogleFonts.dmSans(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -1,
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 6),

                  Text(
                    'Walk in faith, together.',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 44),

                  // ── Tab toggle ────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        _TabButton(
                          label: 'Sign In',
                          selected: _isLogin,
                          onTap: () {
                            context.read<AuthProvider>().clearError();
                            setState(() => _isLogin = true);
                          },
                        ),
                        _TabButton(
                          label: 'Create Account',
                          selected: !_isLogin,
                          onTap: () {
                            context.read<AuthProvider>().clearError();
                            setState(() => _isLogin = false);
                          },
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 350.ms),

                  const SizedBox(height: 28),

                  // ── Form card ─────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel('Email'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            style: GoogleFonts.dmSans(
                                color: AppColors.textPrimary, fontSize: 15),
                            decoration: const InputDecoration(
                              hintText: 'you@example.com',
                              prefixIcon: Icon(Icons.mail_outline_rounded,
                                  color: AppColors.textMuted, size: 20),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Enter your email';
                              }
                              if (!v.contains('@')) return 'Invalid email';
                              return null;
                            },
                            onChanged: (_) => auth.clearError(),
                          ),
                          const SizedBox(height: 16),
                          _FieldLabel('Password'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscurePass,
                            style: GoogleFonts.dmSans(
                                color: AppColors.textPrimary, fontSize: 15),
                            decoration: InputDecoration(
                              hintText: _isLogin
                                  ? '••••••••'
                                  : 'Min. 6 characters',
                              prefixIcon: const Icon(Icons.lock_outline_rounded,
                                  color: AppColors.textMuted, size: 20),
                              suffixIcon: GestureDetector(
                                onTap: () => setState(
                                    () => _obscurePass = !_obscurePass),
                                child: Icon(
                                  _obscurePass
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.textMuted,
                                  size: 20,
                                ),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) => _submit(),
                            onChanged: (_) => auth.clearError(),
                          ),

                          if (auth.error != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color:
                                        AppColors.danger.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: AppColors.danger, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      auth.error!,
                                      style: GoogleFonts.dmSans(
                                          color: AppColors.danger,
                                          fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),

                          SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: auth.loading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(16)),
                                shadowColor:
                                    AppColors.primary.withOpacity(0.4),
                                elevation: auth.loading ? 0 : 8,
                              ),
                              child: auth.loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white),
                                    )
                                  : Text(
                                      _isLogin
                                          ? 'Sign In'
                                          : 'Create Account',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.05),

                  const SizedBox(height: 28),

                  Text(
                    'By continuing you agree to our Terms of Service\nand Privacy Policy.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      height: 1.6,
                    ),
                  ).animate().fadeIn(delay: 500.ms),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: selected ? Colors.white : AppColors.textMuted,
              ),
            ),
          ),
        ),
      );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.3,
        ),
      );
}
