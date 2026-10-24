import 'package:flutter/material.dart';

import '../../core/app_controller.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const PageHeader('My Profile'),
            const SizedBox(height: 24),
            const Artwork('avatar', size: 100, radius: 100),
            const SizedBox(height: 20),
            Text(app.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              app.signedIn ? app.email : 'Make yourself at home',
              style: const TextStyle(color: EqualiColors.muted),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  NeuBox(
                    radius: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        for (final (count, label) in [
                          (app.tracks.length, 'Songs'),
                          (app.playlists.length, 'Playlists'),
                          (app.favorites.length, 'Favorites'),
                        ])
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              children: [
                                Text('$count', style: Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 4),
                                Text(label, style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ListTile(
                    key: const ValueKey('edit-profile'),
                    leading: const Icon(Icons.person_outline_rounded),
                    title: const Text('Edit profile'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => openPage(context, const CreateProfilePage(editing: true)),
                  ),
                  ListTile(
                    key: const ValueKey('sign-in'),
                    leading: const Icon(Icons.login_rounded),
                    title: Text(app.signedIn ? 'Switch profile' : 'Sign in / Sign up'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => openPage(context, const AuthPage()),
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded),
                    title: const Text('About Equali'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Equali 1.0'),
                        content: const Text(
                          'Your music. Your sound.\n\nUI inspired by the Equali Pixso kit. Bundled tracks are original synthesized demos. Profiles stay on this device.\n\nAndroid supports device audio effects; other platforms offer playback and UI preview.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Got it'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (app.signedIn)
                    ListTile(
                      leading: const Icon(Icons.logout_rounded),
                      title: const Text('Sign out'),
                      onTap: () {
                        app.signOut();
                        toast(context, 'Signed out on this device');
                      },
                    ),
                ],
              ),
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'E Q U A L I  /  FEEL EVERY FREQUENCY',
                style: TextStyle(fontSize: 9, letterSpacing: 1.5, color: EqualiColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum AuthStep { signIn, register, forgot, verify, reset }

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, this.initialStep = AuthStep.signIn});
  final AuthStep initialStep;
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  late AuthStep _step = widget.initialStep;
  final _email = TextEditingController(),
      _password = TextEditingController(),
      _confirm = TextEditingController(),
      _code = TextEditingController();
  var _form = GlobalKey<FormState>();
  bool _obscure = true, _remember = true, _terms = false, _recover = false;
  String? _error;
  @override
  void dispose() {
    for (final c in [_email, _password, _confirm, _code]) {
      c.dispose();
    }
    super.dispose();
  }

  void _go(AuthStep step) {
    setState(() {
      _step = step;
      _error = null;
      _form = GlobalKey<FormState>();
    });
  }

  String? _emailError(String? value) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value?.trim() ?? '')
      ? null
      : 'Enter a valid email address';
  String? _passwordError(String? value) =>
      (value?.length ?? 0) >= 6 ? null : 'Use at least 6 characters';
  void _submit() {
    if (!(_form.currentState?.validate() ?? false)) return;
    switch (_step) {
      case AuthStep.signIn:
        final app = AppScope.of(context);
        app.profile(app.name, _email.text, remember: _remember);
        Navigator.popUntil(context, (route) => route.isFirst);
        toast(context, 'Welcome to your local music profile');
      case AuthStep.register:
        if (!_terms) {
          setState(() => _error = 'Please accept the demo terms to continue.');
          return;
        }
        _recover = false;
        _go(AuthStep.verify);
      case AuthStep.forgot:
        _recover = true;
        _go(AuthStep.verify);
      case AuthStep.verify:
        if (_code.text != '1234') {
          setState(() => _error = 'Use the preview code 1234.');
          return;
        }
        if (_recover) {
          _password.clear();
          _confirm.clear();
          _go(AuthStep.reset);
        } else {
          openPage(context, CreateProfilePage(email: _email.text));
        }
      case AuthStep.reset:
        _password.clear();
        _confirm.clear();
        _go(AuthStep.signIn);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('All set'),
            content: const Text(
              'Password reset preview completed. This demo does not store passwords or send emails.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to sign in'),
              ),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEntry = _step == AuthStep.signIn || _step == AuthStep.register;
    final title = switch (_step) {
      AuthStep.signIn => 'Welcome back',
      AuthStep.register => 'Create an account',
      AuthStep.forgot => 'Forgot password',
      AuthStep.verify => 'Verification email',
      AuthStep.reset => 'Reset password',
    };
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (!isEntry)
              PageHeader(title, onBack: () => _go(AuthStep.signIn))
            else
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 10, top: 8),
                  child: NeuIcon(
                    Icons.arrow_back_rounded,
                    label: 'Back',
                    onTap: () => Navigator.pop(context),
                  ),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isEntry) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Image.asset(
                            'assets/images/logo.png',
                            height: 66,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ] else ...[
                        const SizedBox(height: 24),
                        Icon(
                          _step == AuthStep.verify
                              ? Icons.mark_email_read_outlined
                              : Icons.lock_reset_rounded,
                          size: 64,
                          color: EqualiColors.primary,
                        ),
                        const SizedBox(height: 24),
                      ],
                      if (!isEntry)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 28),
                          child: Text(
                            switch (_step) {
                              AuthStep.forgot => 'Enter your email to preview the recovery flow.',
                              AuthStep.verify => 'Enter the four-digit code for\n${_email.text}',
                              _ => 'Choose a new password for your profile.',
                            },
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: EqualiColors.muted, height: 1.7),
                          ),
                        ),
                      if (_step == AuthStep.signIn ||
                          _step == AuthStep.register ||
                          _step == AuthStep.forgot)
                        _field(
                          _email,
                          'Email address',
                          'email',
                          validator: _emailError,
                          keyboard: TextInputType.emailAddress,
                        ),
                      if (_step == AuthStep.signIn ||
                          _step == AuthStep.register ||
                          _step == AuthStep.reset) ...[
                        const SizedBox(height: 16),
                        _field(
                          _password,
                          _step == AuthStep.reset ? 'New password' : 'Password',
                          'password',
                          validator: _passwordError,
                          password: true,
                        ),
                      ],
                      if (_step == AuthStep.register || _step == AuthStep.reset) ...[
                        const SizedBox(height: 16),
                        _field(
                          _confirm,
                          'Confirm password',
                          'confirm-password',
                          password: true,
                          validator: (v) =>
                              v == _password.text && v!.isNotEmpty ? null : 'Passwords must match',
                        ),
                      ],
                      if (_step == AuthStep.verify) ...[
                        _field(
                          _code,
                          '4-digit code',
                          'verification-code',
                          keyboard: TextInputType.number,
                          validator: (value) =>
                              (value?.length ?? 0) == 4 ? null : 'Enter the 4-digit code',
                          maxLength: 4,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Preview code: 1234 · No email is sent',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: EqualiColors.primary),
                        ),
                      ],
                      if (_step == AuthStep.signIn)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 28,
                                child: Checkbox(
                                  value: _remember,
                                  onChanged: (v) => setState(() => _remember = v ?? false),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text('Remember me', style: TextStyle(fontSize: 12)),
                              const Spacer(),
                              TextButton(
                                key: const ValueKey('forgot-password'),
                                onPressed: () => _go(AuthStep.forgot),
                                child: const Text(
                                  'Forgot password?',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_step == AuthStep.register)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Checkbox(
                                key: const ValueKey('accept-terms'),
                                value: _terms,
                                onChanged: (v) => setState(() => _terms = v ?? false),
                              ),
                              const Expanded(
                                child: Text(
                                  'I agree to use this local demonstration.',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                          ),
                        ),
                      const SizedBox(height: 12),
                      PrimaryButton(
                        switch (_step) {
                          AuthStep.signIn => 'Sign in',
                          AuthStep.register => 'Sign up',
                          AuthStep.forgot => 'Send verification code',
                          AuthStep.verify => 'Verify',
                          AuthStep.reset => 'Reset password',
                        },
                        key: const ValueKey('auth-submit'),
                        onPressed: _submit,
                      ),
                      if (isEntry) ...[
                        const SizedBox(height: 24),
                        const Row(
                          children: [
                            Expanded(child: Divider(color: EqualiColors.icon)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('Or', style: TextStyle(fontSize: 18)),
                            ),
                            Expanded(child: Divider(color: EqualiColors.icon)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        for (final (icon, label) in [
                          (Icons.g_mobiledata_rounded, 'Google'),
                          (Icons.facebook_rounded, 'Facebook'),
                          (Icons.apple_rounded, 'Apple'),
                        ])
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: GestureDetector(
                              onTap: () => showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Continue with $label'),
                                  content: Text(
                                    '$label sign-in needs a connected authentication service. Use the local email preview to explore the app.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Got it'),
                                    ),
                                  ],
                                ),
                              ),
                              child: NeuBox(
                                radius: 30,
                                padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
                                child: Row(
                                  children: [
                                    Icon(
                                      icon,
                                      color: label == 'Apple'
                                          ? EqualiColors.text
                                          : EqualiColors.primary,
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Continue with $label',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                      const SizedBox(height: 16),
                      const Text(
                        'Local preview · No online account is created.\nAny valid email and a 6+ character password work.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10, color: EqualiColors.muted, height: 1.6),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (isEntry)
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _step == AuthStep.signIn
                          ? "Don't have an account? "
                          : 'Already have an account? ',
                      style: const TextStyle(color: EqualiColors.icon, fontSize: 13),
                    ),
                    GestureDetector(
                      key: const ValueKey('auth-switch'),
                      onTap: () =>
                          _go(_step == AuthStep.signIn ? AuthStep.register : AuthStep.signIn),
                      child: Text(
                        _step == AuthStep.signIn ? 'Sign up' : 'Sign in',
                        style: const TextStyle(
                          color: EqualiColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String hint,
    String key, {
    String? Function(String?)? validator,
    bool password = false,
    TextInputType? keyboard,
    int? maxLength,
  }) => NeuBox(
    radius: 26,
    pressed: true,
    child: TextFormField(
      key: ValueKey(key),
      controller: controller,
      validator: validator,
      keyboardType: keyboard,
      obscureText: password && _obscure,
      maxLength: maxLength,
      autocorrect: !password,
      textInputAction: TextInputAction.next,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: EqualiColors.muted),
        counterText: '',
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        suffixIcon: password
            ? IconButton(
                tooltip: _obscure ? 'Show password' : 'Hide password',
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: EqualiColors.muted,
                  size: 20,
                ),
              )
            : null,
      ),
    ),
  );
}

class CreateProfilePage extends StatefulWidget {
  const CreateProfilePage({super.key, this.email = '', this.editing = false});
  final String email;
  final bool editing;
  @override
  State<CreateProfilePage> createState() => _CreateProfilePageState();
}

class _CreateProfilePageState extends State<CreateProfilePage> {
  final _name = TextEditingController(), _email = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _initialized = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final app = AppScope.of(context);
      _name.text = widget.editing ? app.name : '';
      _email.text = widget.email.isNotEmpty ? widget.email : app.email;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          PageHeader(widget.editing ? 'Edit Profile' : 'Create Profile'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 28),
                    const Center(child: Artwork('avatar', size: 120, radius: 120)),
                    const SizedBox(height: 36),
                    Text(
                      widget.editing ? 'A little more you' : 'Let’s make it yours',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your profile lives on this device.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: EqualiColors.muted),
                    ),
                    const SizedBox(height: 32),
                    NeuBox(
                      radius: 26,
                      pressed: true,
                      child: TextFormField(
                        key: const ValueKey('profile-name'),
                        controller: _name,
                        maxLength: 40,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Please enter your name' : null,
                        decoration: const InputDecoration(
                          hintText: 'Your name',
                          counterText: '',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    NeuBox(
                      radius: 26,
                      pressed: true,
                      child: TextFormField(
                        key: const ValueKey('profile-email'),
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) =>
                            v != null &&
                                v.isNotEmpty &&
                                !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v)
                            ? 'Enter a valid email'
                            : null,
                        decoration: const InputDecoration(
                          hintText: 'Email (optional)',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    PrimaryButton(
                      widget.editing ? 'Save profile' : 'Let’s go',
                      key: const ValueKey('save-profile'),
                      onPressed: () {
                        if (!_form.currentState!.validate()) return;
                        AppScope.of(context).profile(_name.text, _email.text);
                        if (widget.editing) {
                          Navigator.pop(context);
                        } else {
                          Navigator.popUntil(context, (route) => route.isFirst);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
