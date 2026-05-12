// Login Screen — Email/Password + Register toggle
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/constants/app_constants.dart';
import 'widgets/shared_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();

  bool _isRegister   = false;
  bool _obscurePass  = true;
  late AnimationController _ctrl;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _slideAnim = Tween<double>(begin: 60, end: 0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    bool ok;
    if (_isRegister) {
      ok = await auth.register(_nameCtrl.text.trim(), _emailCtrl.text.trim(), _passCtrl.text);
    } else {
      ok = await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
    }
    if (ok && mounted) Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        // Căn giữa toàn bộ giao diện theo cả 2 trục trên Desktop/Tablet
        child: Center(
          // Giới hạn chiều rộng của form (chuẩn UX cho màn hình lớn)
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: AnimatedBuilder(
              animation: _slideAnim,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, _slideAnim.value),
                child: child,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch, // Kéo giãn các widget con vừa khung 480px
                  children: [
                    // ── Logo ──────────────────────────────────────────────
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 16, offset: const Offset(0, 6)),
                              ],
                            ),
                            child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 44),
                          ),
                          const SizedBox(height: 16),
                          const Text('LingoPro',
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
                                  color: AppColors.primary)),
                          const SizedBox(height: 4),
                          Text(
                            _isRegister ? 'Create your account' : 'Welcome back!',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // ── Form ──────────────────────────────────────────────
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          if (_isRegister) ...[
                            _InputField(
                              ctrl: _nameCtrl,
                              label: 'Full Name',
                              icon: Icons.person_outline,
                              textInputAction: TextInputAction.next,
                              validator: (v) => (v == null || v.isEmpty) ? 'Enter your name' : null,
                            ),
                            const SizedBox(height: 16),
                          ],
                          _InputField(
                            ctrl: _emailCtrl,
                            label: 'Email',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: (v) => (v == null || !v.contains('@')) ? 'Enter valid email' : null,
                          ),
                          const SizedBox(height: 16),
                          _InputField(
                            ctrl: _passCtrl,
                            label: 'Password',
                            icon: Icons.lock_outline,
                            obscure: _obscurePass,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(), // Enter để submit trên Desktop
                            suffix: IconButton(
                              icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility,
                                  color: AppColors.textSecondary),
                              onPressed: () => setState(() => _obscurePass = !_obscurePass),
                            ),
                            validator: (v) =>
                                (v == null || v.length < 6) ? 'Min 6 characters' : null,
                          ),
                        ],
                      ),
                    ),

                    // ── Error ─────────────────────────────────────────────
                    if (auth.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(auth.errorMessage!,
                                  style: const TextStyle(color: AppColors.error, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),

                    // ── Submit ────────────────────────────────────────────
                    GradientButton(
                      text: _isRegister ? 'Create Account' : 'Sign In',
                      onTap: _submit,
                      isLoading: auth.isLoading,
                      icon: _isRegister ? Icons.person_add : Icons.login,
                    ),
                    const SizedBox(height: 20),

                    // ── Toggle ────────────────────────────────────────────
                    Center(
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click, // Hiển thị con trỏ click trên Desktop/Web
                        child: GestureDetector(
                          onTap: () => setState(() => _isRegister = !_isRegister),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0), // Tăng vùng bấm (hitbox)
                            child: RichText(
                              text: TextSpan(
                                text: _isRegister
                                    ? 'Already have an account? '
                                    : "Don't have an account? ",
                                style: AppTextStyles.bodySmall,
                                children: [
                                  TextSpan(
                                    text: _isRegister ? 'Sign In' : 'Sign Up',
                                    style: const TextStyle(
                                      color: AppColors.primary, fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;

  const _InputField({
    required this.ctrl, required this.label, required this.icon,
    this.obscure = false, this.suffix, this.keyboardType, this.validator,
    this.textInputAction, this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      style: AppTextStyles.body,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.textHint),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }
}