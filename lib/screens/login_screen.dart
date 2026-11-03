part of '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Cambiamos email por numero de empleado
  final _empNoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController =
      TextEditingController(); // Optional email for password recovery
  bool _isSignUp = false;
  bool _obscurePassword = true;
  String? _loginError;
  bool _isLoading = false;

  @override
  void dispose() {
    _empNoController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _updateEmployeeDirectory(String empNumber, String email,
      [String? uid]) async {
    final cleanEmp = empNumber.trim();
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmp.isEmpty || cleanEmail.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('employee_directory')
          .doc(cleanEmp)
          .set({
        'email': cleanEmail,
        'legacy_email': "$cleanEmp@televisa.com",
        'employee_number': cleanEmp,
        if (uid != null) 'uid': uid,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error updating employee_directory: $e");
    }
  }

  Future<void> _submit() async {
    if (_empNoController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        (_isSignUp && _emailController.text.trim().isEmpty)) {
      setState(() {
        if (_empNoController.text.trim().isEmpty ||
            _passwordController.text.trim().isEmpty) {
          _loginError = "Por favor llena todos los campos";
        } else {
          _loginError = "Por favor ingresa tu número de empleado";
        }
      });
      return;
    }

    final String input = _empNoController.text.trim();
    final String password = _passwordController.text.trim();

    setState(() {
      _isLoading = true;
      _loginError = null;
    });

    bool userExistsInDb = false;
    bool isEmployeeResolved = false;

    try {
      if (_isSignUp) {
        if (!input.contains('@')) {
          setState(() {
            _loginError =
                "Para nuevos usuarios, usa tu correo electrónico real";
            _isLoading = false;
          });
          return;
        }

        final email = input.toLowerCase();
        final empNumber = _emailController.text.trim();

        // Create account with real email
        final userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Store employee number in Firestore (required for new users)
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'employee_number': empNumber,
          'user_emp': empNumber,
          'is_new_style_user': true,
          'recovery_email': email,
          'email': email,
        }, SetOptions(merge: true));

        // Sync employee_directory mapping
        await _updateEmployeeDirectory(
            empNumber, email, userCredential.user!.uid);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("¡Cuenta creada! Ahora configura tu información"),
          backgroundColor: Colors.green,
        ));

        // After brief delay, let AuthWrapper naturally redirect to TelevisaApp
        // where _checkAndShowOnboarding will trigger the onboarding dialog
        await Future.delayed(const Duration(milliseconds: 500));
      } else {
        // LOGIN:
        UserCredential? userCredential;
        FirebaseAuthException? lastAuthException;
        String? resolvedEmail;
        String? linkedEmpNumber;

        if (input.contains('@')) {
          // 1. Email Login with Legacy Link
          final email = input.toLowerCase();

          // Check 'employee_directory' to see if this email is linked to an employee number with a legacy account
          try {
            final snapDir = await FirebaseFirestore.instance
                .collection('employee_directory')
                .where('email', isEqualTo: email)
                .limit(1)
                .get();
            if (snapDir.docs.isNotEmpty) {
              userExistsInDb = true;
              final data = snapDir.docs.first.data();
              linkedEmpNumber = (data['employee_number'] ?? snapDir.docs.first.id)
                  ?.toString()
                  .trim();
            }
          } catch (e) {
            debugPrint("employee_directory lookup by email error: $e");
          }

          // Check local prefs as fallback for linked employee number
          if (linkedEmpNumber == null || linkedEmpNumber.isEmpty) {
            try {
              final prefs = await SharedPreferences.getInstance();
              final localEmp = prefs.getString('user_emp')?.trim();
              final localEmail =
                  prefs.getString('recovery_email')?.trim().toLowerCase();
              if (localEmail == email &&
                  localEmp != null &&
                  localEmp.isNotEmpty) {
                linkedEmpNumber = localEmp;
              }
            } catch (e) {
              debugPrint("Local prefs check error: $e");
            }
          }

          // Fallback check in users collection (recovery_email)
          if (linkedEmpNumber == null || linkedEmpNumber.isEmpty) {
            try {
              final snapRec = await FirebaseFirestore.instance
                  .collection('users')
                  .where('recovery_email', isEqualTo: email)
                  .limit(1)
                  .get();
              if (snapRec.docs.isNotEmpty) {
                userExistsInDb = true;
                final data = snapRec.docs.first.data();
                linkedEmpNumber =
                    (data['employee_number'] ?? data['user_emp'])?.toString().trim();
              }
            } catch (e) {
              debugPrint("users lookup by recovery_email error: $e");
            }
          }

          // Fallback check in users collection (email field) to ensure userExistsInDb
          if (!userExistsInDb) {
            try {
              final snapEmail = await FirebaseFirestore.instance
                  .collection('users')
                  .where('email', isEqualTo: email)
                  .limit(1)
                  .get();
              if (snapEmail.docs.isNotEmpty) {
                userExistsInDb = true;
                final data = snapEmail.docs.first.data();
                if (linkedEmpNumber == null || linkedEmpNumber.isEmpty) {
                  linkedEmpNumber =
                      (data['employee_number'] ?? data['user_emp'])?.toString().trim();
                }
              }
            } catch (e) {
              debugPrint("Firestore email check error: $e");
            }
          }

          if (linkedEmpNumber != null && linkedEmpNumber.isNotEmpty) {
            isEmployeeResolved = true;
            userExistsInDb = true;
          }

          final bool isRealEmail = !email.endsWith('@televisa.com');
          final String candidate1 = isRealEmail
              ? email
              : (linkedEmpNumber != null && linkedEmpNumber.isNotEmpty
                  ? "$linkedEmpNumber@televisa.com"
                  : email);
          final String? candidate2 = (isRealEmail &&
                  linkedEmpNumber != null &&
                  linkedEmpNumber.isNotEmpty)
              ? "$linkedEmpNumber@televisa.com"
              : null;

          // ATTEMPT 1: Authenticate directly with Candidate 1 (real email first)
          try {
            userCredential =
                await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: candidate1,
              password: password,
            );
          } on FirebaseAuthException catch (e) {
            lastAuthException = e;
          }

          // ATTEMPT 2: Fallback to Candidate 2 (legacy @televisa.com) if Candidate 1 failed
          if (userCredential == null && candidate2 != null) {
            try {
              userCredential =
                  await FirebaseAuth.instance.signInWithEmailAndPassword(
                email: candidate2,
                password: password,
              );
              lastAuthException = null; // Success with fallback!
            } on FirebaseAuthException catch (e) {
              if (lastAuthException == null ||
                  lastAuthException.code != 'wrong-password') {
                lastAuthException = e;
              }
            }
          }
        } else {
          // 2. Employee Number Login

          // Check 'employee_directory' doc(input)
          try {
            final dirDoc = await FirebaseFirestore.instance
                .collection('employee_directory')
                .doc(input)
                .get();
            if (dirDoc.exists) {
              userExistsInDb = true;
              final dirData = dirDoc.data();
              resolvedEmail =
                  (dirData?['email'] ?? dirData?['recovery_email'])?.toString().trim().toLowerCase();
            }
          } catch (e) {
            debugPrint("employee_directory lookup error: $e");
          }

          // Fallback check in users collection
          if (resolvedEmail == null || resolvedEmail.isEmpty) {
            try {
              final snapEmp = await FirebaseFirestore.instance
                  .collection('users')
                  .where('employee_number', isEqualTo: input)
                  .limit(1)
                  .get();
              if (snapEmp.docs.isNotEmpty) {
                userExistsInDb = true;
                final data = snapEmp.docs.first.data();
                resolvedEmail =
                    (data['recovery_email'] ?? data['email'])?.toString().trim().toLowerCase();
              }
              if (resolvedEmail == null || resolvedEmail.isEmpty) {
                final snapUserEmp = await FirebaseFirestore.instance
                    .collection('users')
                    .where('user_emp', isEqualTo: input)
                    .limit(1)
                    .get();
                if (snapUserEmp.docs.isNotEmpty) {
                  userExistsInDb = true;
                  final data = snapUserEmp.docs.first.data();
                  resolvedEmail =
                      (data['recovery_email'] ?? data['email'])?.toString().trim().toLowerCase();
                }
              }
            } catch (e) {
              debugPrint("Firestore employee lookup error: $e");
            }
          }

          if (resolvedEmail != null && resolvedEmail.isNotEmpty) {
            isEmployeeResolved = true;
            userExistsInDb = true;
          }

          final bool hasResolvedRealEmail = resolvedEmail != null &&
              resolvedEmail.isNotEmpty &&
              !resolvedEmail.endsWith('@televisa.com');

          final String candidate1 =
              hasResolvedRealEmail ? resolvedEmail : "$input@televisa.com";
          final String? candidate2 =
              hasResolvedRealEmail ? "$input@televisa.com" : null;

          // ATTEMPT 1: Try Candidate 1 (mapped directory email first)
          try {
            userCredential =
                await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: candidate1,
              password: password,
            );
          } on FirebaseAuthException catch (e) {
            lastAuthException = e;
          }

          // ATTEMPT 2: Try Candidate 2 (legacy @televisa.com) if Candidate 1 failed
          if (userCredential == null && candidate2 != null) {
            try {
              userCredential =
                  await FirebaseAuth.instance.signInWithEmailAndPassword(
                email: candidate2,
                password: password,
              );
              lastAuthException = null; // Success with legacy candidate!
            } on FirebaseAuthException catch (e) {
              if (lastAuthException == null ||
                  lastAuthException.code != 'wrong-password') {
                lastAuthException = e;
              }
            }
          }
        }

        if (userCredential != null) {
          // Successful login!
          final currentUser = userCredential.user!;
          String? empNumber = input.contains('@') ? linkedEmpNumber : input;

          if (empNumber == null || empNumber.isEmpty) {
            try {
              final uDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser.uid)
                  .get();
              if (uDoc.exists) {
                final uData = uDoc.data();
                empNumber = (uData?['employee_number'] ??
                        uData?['user_emp'])
                    ?.toString().trim();
              }
            } catch (e) {
              debugPrint("Error fetching employee number on login: $e");
            }
          }

          // Determine user's real contact email
          String? realEmail;
          if (input.contains('@') && !input.endsWith('@televisa.com')) {
            realEmail = input.toLowerCase();
          } else if (resolvedEmail != null && !resolvedEmail.endsWith('@televisa.com')) {
            realEmail = resolvedEmail.toLowerCase();
          }

          if (realEmail == null || realEmail.isEmpty) {
            try {
              final uDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser.uid)
                  .get();
              if (uDoc.exists) {
                final uData = uDoc.data();
                final rec = (uData?['recovery_email'] ?? uData?['email'])?.toString().trim().toLowerCase();
                if (rec != null && rec.isNotEmpty && !rec.endsWith('@televisa.com')) {
                  realEmail = rec;
                }
              }
            } catch (e) {
              debugPrint("Error fetching real email on login: $e");
            }
          }

          final effectiveEmail = (realEmail != null && realEmail.isNotEmpty)
              ? realEmail
              : (currentUser.email ?? "");

          if (empNumber != null &&
              empNumber.trim().isNotEmpty &&
              effectiveEmail.isNotEmpty) {
            await _updateEmployeeDirectory(
                empNumber, effectiveEmail, currentUser.uid);
          }
        } else if (lastAuthException != null) {
          throw lastAuthException;
        }
      }
    } on FirebaseAuthException catch (e) {
      debugPrint("FirebaseAuthException: ${e.code} - ${e.message}");
      if (!mounted) return;
      setState(() {
        if (e.code == 'user-not-found') {
          _loginError = "El número de empleado o correo no está registrado";
        } else if (e.code == 'wrong-password') {
          _loginError =
              "Tu correo o número de empleado es correcto, pero la contraseña no coincide. Por favor intenta de nuevo. Tu cuenta no se bloqueará por múltiples intentos.";
        } else if (e.code == 'invalid-credential') {
          if (!input.contains('@') && !isEmployeeResolved) {
            _loginError = "El número de empleado o correo no está registrado";
          } else if (input.contains('@') && !userExistsInDb) {
            _loginError = "El número de empleado o correo no está registrado";
          } else {
            _loginError =
                "Tu correo o número de empleado es correcto, pero la contraseña no coincide. Por favor intenta de nuevo. Tu cuenta no se bloqueará por múltiples intentos.";
          }
        } else if (e.code == 'invalid-email') {
          _loginError = "El número de empleado o correo no está registrado";
        } else if (e.code == 'too-many-requests') {
          _loginError =
              "Demasiados intentos fallidos. Por favor intenta más tarde";
        } else if (e.code == 'email-already-in-use') {
          _loginError = "Este correo ya está registrado. Por favor inicia sesión";
        } else if (e.code == 'weak-password') {
          _loginError = "La contraseña debe tener al menos 6 caracteres";
        } else {
          _loginError = e.message ?? "Error al autenticar. Verifica tus datos";
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loginError = "Error: ${e.toString()}";
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Welcoming Header
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.orange.withAlpha(25),
                      border: Border.all(
                        color: Colors.orange.withAlpha(80),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _isSignUp
                          ? Icons.person_add_alt_1_rounded
                          : Icons.lock_person_rounded,
                      size: 38,
                      color: Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _isSignUp
                      ? "Crea tu cuenta"
                      : "¡Bienvenido a Mi Nómina Pro!",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isSignUp
                      ? "Registra tu información para comenzar"
                      : "Tu herramienta para calcular, registrar y dar seguimiento a tu tiempo extra y percepciones de nómina.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 28),

                // Inline Persistent Error Banner
                if (_loginError != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(35),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.redAccent.withAlpha(180),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: Colors.redAccent, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _loginError!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => setState(() => _loginError = null),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.close_rounded,
                                color: Colors.white54, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // Field 1: Email or Employee Number
                TextField(
                  controller: _empNoController,
                  keyboardType: _isSignUp
                      ? TextInputType.emailAddress
                      : TextInputType.text,
                  style: const TextStyle(color: Colors.white, fontSize: 17),
                  onChanged: (_) {
                    if (_loginError != null) {
                      setState(() => _loginError = null);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: _isSignUp
                        ? "Correo Electrónico"
                        : "Número de empleado o correo",
                    hintText: _isSignUp
                        ? "tu-correo@gmail.com"
                        : "Ej: 12345 o tu-correo@gmail.com",
                    prefixIcon: Icon(
                      _isSignUp
                          ? Icons.alternate_email_rounded
                          : Icons.person_outline_rounded,
                      color: Colors.orange,
                    ),
                    filled: true,
                    fillColor: Colors.white.withAlpha(12),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Colors.orange, width: 2),
                    ),
                    hintStyle:
                        const TextStyle(color: Colors.white30, fontSize: 14),
                    labelStyle: const TextStyle(
                      color: Colors.orange,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Field 2: Password with visibility toggle
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white, fontSize: 17),
                  onChanged: (_) {
                    if (_loginError != null) {
                      setState(() => _loginError = null);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: "Contraseña",
                    hintText: "Tu contraseña",
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: Colors.orange,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.white70,
                      ),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                      tooltip: _obscurePassword
                          ? "Mostrar contraseña"
                          : "Ocultar contraseña",
                    ),
                    filled: true,
                    fillColor: Colors.white.withAlpha(12),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Colors.orange, width: 2),
                    ),
                    hintStyle:
                        const TextStyle(color: Colors.white30, fontSize: 14),
                    labelStyle: const TextStyle(
                      color: Colors.orange,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Show employee number field only during signup (for new users)
                if (_isSignUp) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.number,
                    style:
                        const TextStyle(color: Colors.white, fontSize: 17),
                    onChanged: (_) {
                      if (_loginError != null) {
                        setState(() => _loginError = null);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: "Número de empleado",
                      hintText: "Tu número de nómina",
                      prefixIcon: const Icon(
                        Icons.badge_outlined,
                        color: Colors.blueAccent,
                      ),
                      filled: true,
                      fillColor: Colors.white.withAlpha(12),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Colors.blueAccent, width: 2),
                      ),
                      hintStyle:
                          const TextStyle(color: Colors.white30, fontSize: 14),
                      labelStyle: const TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.withAlpha(60)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.green, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Nuevo: Usa tu correo real para crear cuenta. Podrás recuperar tu contraseña fácilmente.",
                            style: TextStyle(
                                color: Colors.greenAccent, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Primary Submit Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    disabledBackgroundColor: Colors.orange.withAlpha(100),
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : Text(
                          _isSignUp
                              ? "CREAR MI CUENTA"
                              : "INGRESAR A MI CUENTA",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),

                // Dificultad para ingresar button (only for login mode)
                if (!_isSignUp) ...[
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    icon: const Icon(
                      Icons.help_outline_rounded,
                      color: Colors.amberAccent,
                      size: 20,
                    ),
                    label: const Text(
                      "Click aquí si tienes dificultad para ingresar a tu cuenta",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.amberAccent,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A2A2A),
                      foregroundColor: Colors.amberAccent,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.amber.withAlpha(90),
                          width: 1.2,
                        ),
                      ),
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onPressed: () => _showLockedOutHelpDialog(context),
                  ),
                ],

                const SizedBox(height: 14),

                // Switch between Sign in and Sign up
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white38, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () {
                    setState(() {
                      _isSignUp = !_isSignUp;
                      _loginError = null;
                    });
                  },
                  child: Text(
                    _isSignUp ? "Ya tengo una cuenta" : "Crea tu cuenta aquí",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLockedOutHelpDialog(BuildContext context) {
    final recoveryInputController = TextEditingController();
    bool isSubmitting = false;
    String? errorMessage;
    String? successMessage;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> handlePasswordReset() async {
              final rawInput = recoveryInputController.text.trim();
              if (rawInput.isEmpty) {
                setDialogState(() {
                  errorMessage =
                      "Por favor ingresa tu número de empleado o correo";
                  successMessage = null;
                });
                return;
              }

              setDialogState(() {
                isSubmitting = true;
                errorMessage = null;
                successMessage = null;
              });

              String? targetEmail;

              try {
                if (rawInput.contains('@')) {
                  targetEmail = rawInput.toLowerCase();
                } else {
                  // Resolve email via 'employee_directory' doc(rawInput)
                  final dirDoc = await FirebaseFirestore.instance
                      .collection('employee_directory')
                      .doc(rawInput)
                      .get();
                  if (dirDoc.exists) {
                    final d = dirDoc.data();
                    targetEmail = (d?['email'] ?? d?['recovery_email'])
                        ?.toString()
                        .trim()
                        .toLowerCase();
                  }

                  // Fallback check in users collection
                  if (targetEmail == null || targetEmail.isEmpty) {
                    final snapEmp = await FirebaseFirestore.instance
                        .collection('users')
                        .where('employee_number', isEqualTo: rawInput)
                        .limit(1)
                        .get();
                    if (snapEmp.docs.isNotEmpty) {
                      final data = snapEmp.docs.first.data();
                      targetEmail = (data['recovery_email'] ?? data['email'])
                          ?.toString()
                          .trim()
                          .toLowerCase();
                    }
                    if (targetEmail == null || targetEmail.isEmpty) {
                      final snapUserEmp = await FirebaseFirestore.instance
                          .collection('users')
                          .where('user_emp', isEqualTo: rawInput)
                          .limit(1)
                          .get();
                      if (snapUserEmp.docs.isNotEmpty) {
                        final data = snapUserEmp.docs.first.data();
                        targetEmail = (data['recovery_email'] ?? data['email'])
                            ?.toString()
                            .trim()
                            .toLowerCase();
                      }
                    }
                  }
                }

                if (targetEmail == null ||
                    targetEmail.isEmpty ||
                    targetEmail.endsWith('@televisa.com')) {
                  setDialogState(() {
                    isSubmitting = false;
                    errorMessage = rawInput.contains('@')
                        ? "El correo no está registrado en el sistema"
                        : "El número de empleado no tiene un correo de recuperación registrado";
                  });
                  return;
                }

                await FirebaseAuth.instance
                    .sendPasswordResetEmail(email: targetEmail);

                setDialogState(() {
                  isSubmitting = false;
                  successMessage =
                      "Enlace enviado a $targetEmail. Revisa tu bandeja o carpeta de spam.";
                  errorMessage = null;
                });
              } on FirebaseAuthException catch (e) {
                setDialogState(() {
                  isSubmitting = false;
                  if (e.code == 'user-not-found') {
                    errorMessage =
                        "No se encontró ningún usuario con ese correo";
                  } else if (e.code == 'invalid-email') {
                    errorMessage = "El formato de correo no es válido";
                  } else {
                    errorMessage = e.message ??
                        "Error al enviar el enlace de recuperación";
                  }
                });
              } catch (e) {
                setDialogState(() {
                  isSubmitting = false;
                  errorMessage = "Error: ${e.toString()}";
                });
              }
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withAlpha(25)),
              ),
              title: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      color: Colors.orange,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Recuperar Contraseña",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Ingresa tu número de empleado o correo registrado. Te enviaremos un enlace oficial para restablecer tu contraseña.",
                      style: TextStyle(
                          color: Colors.white70, fontSize: 13.5, height: 1.35),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: recoveryInputController,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      enabled: !isSubmitting && successMessage == null,
                      onChanged: (_) {
                        if (errorMessage != null || successMessage != null) {
                          setDialogState(() {
                            errorMessage = null;
                            successMessage = null;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        labelText: "Número de empleado o correo registrado",
                        hintText: "Ej: 12345 o tu-correo@gmail.com",
                        prefixIcon: const Icon(Icons.person_search_rounded,
                            color: Colors.orange),
                        filled: true,
                        fillColor: Colors.white.withAlpha(12),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Colors.orange, width: 2),
                        ),
                        labelStyle: const TextStyle(
                            color: Colors.orange,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                        hintStyle: const TextStyle(
                            color: Colors.white30, fontSize: 13.5),
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: Colors.redAccent.withAlpha(120)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: Colors.redAccent, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (successMessage != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.greenAccent.withAlpha(120)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline_rounded,
                                color: Colors.greenAccent, size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                successMessage!,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.5,
                                    height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: Text(
                    successMessage != null ? "CERRAR" : "CANCELAR",
                    style: const TextStyle(
                        color: Colors.white60, fontWeight: FontWeight.bold),
                  ),
                ),
                if (successMessage == null)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    onPressed: isSubmitting ? null : handlePasswordReset,
                    child: isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          )
                        : const Text(
                            "ENVIAR ENLACE",
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                          ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  // REMOVED: _showPasswordResetSuccessDialog - now inline in Settings tab
  // The login screen no longer has password reset functionality
  // Users must use Settings tab when logged in, or contact admin if locked out
}

double getNumericParamForDate(
    DateTime date, List<dynamic> history, double fallback) {
  final targetDate = DateTime(date.year, date.month, date.day);
  if (history.isEmpty) return fallback;

  List<Map<String, dynamic>> matching = [];

  for (var raw in history) {
    if (raw is! Map) continue;
    final entry = Map<String, dynamic>.from(raw);

    DateTime? startDate;
    if (entry['start_date'] != null &&
        entry['start_date'].toString().isNotEmpty) {
      startDate = DateTime.tryParse(entry['start_date'].toString());
    } else if (entry['effective_date'] != null &&
        entry['effective_date'].toString().isNotEmpty) {
      startDate = DateTime.tryParse(entry['effective_date'].toString());
    }
    if (startDate == null) continue;
    final normalizedStart =
        DateTime(startDate.year, startDate.month, startDate.day);

    DateTime? endDate;
    if (entry['end_date'] != null && entry['end_date'].toString().isNotEmpty) {
      final parsedEnd = DateTime.tryParse(entry['end_date'].toString());
      if (parsedEnd != null) {
        endDate = DateTime(parsedEnd.year, parsedEnd.month, parsedEnd.day);
      }
    }

    // Check if targetDate is in [normalizedStart, endDate ?? Present]
    if (!targetDate.isBefore(normalizedStart)) {
      if (endDate == null || !targetDate.isAfter(endDate)) {
        matching.add({
          'entry': entry,
          'start': normalizedStart,
          'end': endDate,
        });
      }
    }
  }

  if (matching.isEmpty) {
    // Backwards compatibility for legacy salary_history with 'previous_salary'
    DateTime? earliestStart;
    dynamic earliestVal;
    for (var raw in history) {
      if (raw is! Map) continue;
      final entry = Map<String, dynamic>.from(raw);
      DateTime? s = DateTime.tryParse(
          (entry['start_date'] ?? entry['effective_date'] ?? '').toString());
      if (s != null) {
        if (earliestStart == null || s.isBefore(earliestStart)) {
          earliestStart = s;
          earliestVal = entry['previous_salary'] ?? entry['previous_value'];
        }
      }
    }
    if (earliestVal != null &&
        earliestStart != null &&
        targetDate.isBefore(earliestStart)) {
      if (earliestVal is num) return earliestVal.toDouble();
      return double.tryParse(earliestVal.toString()) ?? fallback;
    }
    return fallback;
  }

  // Sort matching entries: highest start_date first (most specific/latest period)
  matching.sort(
      (a, b) => (b['start'] as DateTime).compareTo(a['start'] as DateTime));
  final chosen = matching.first['entry'] as Map<String, dynamic>;
  final val = chosen['value'] ?? chosen['salary'];
  if (val is num) return val.toDouble();
  if (val != null) {
    return double.tryParse(val.toString()) ?? fallback;
  }
  return fallback;
}

List<int> getRestDaysForDate(
    DateTime date, List<dynamic> history, List<int> fallback) {
  final targetDate = DateTime(date.year, date.month, date.day);
  if (history.isEmpty) return fallback;

  List<Map<String, dynamic>> matching = [];

  for (var raw in history) {
    if (raw is! Map) continue;
    final entry = Map<String, dynamic>.from(raw);

    DateTime? startDate;
    if (entry['start_date'] != null &&
        entry['start_date'].toString().isNotEmpty) {
      startDate = DateTime.tryParse(entry['start_date'].toString());
    } else if (entry['effective_date'] != null &&
        entry['effective_date'].toString().isNotEmpty) {
      startDate = DateTime.tryParse(entry['effective_date'].toString());
    }
    if (startDate == null) continue;
    final normalizedStart =
        DateTime(startDate.year, startDate.month, startDate.day);

    DateTime? endDate;
    if (entry['end_date'] != null && entry['end_date'].toString().isNotEmpty) {
      final parsedEnd = DateTime.tryParse(entry['end_date'].toString());
      if (parsedEnd != null) {
        endDate = DateTime(parsedEnd.year, parsedEnd.month, parsedEnd.day);
      }
    }

    // Check if targetDate is in [normalizedStart, endDate ?? Present]
    if (!targetDate.isBefore(normalizedStart)) {
      if (endDate == null || !targetDate.isAfter(endDate)) {
        matching.add({
          'entry': entry,
          'start': normalizedStart,
          'end': endDate,
        });
      }
    }
  }

  if (matching.isEmpty) {
    return fallback;
  }

  // Sort matching entries: highest start_date first (most specific/latest period)
  matching.sort(
      (a, b) => (b['start'] as DateTime).compareTo(a['start'] as DateTime));
  final chosen = matching.first['entry'] as Map<String, dynamic>;
  final rawDays = chosen['rest_days'];
  if (rawDays is List) {
    final parsed = rawDays
        .map((e) => int.tryParse(e.toString()) ?? (e is int ? e : null))
        .whereType<int>()
        .where((d) => d >= 1 && d <= 7)
        .toList();
    if (parsed.isNotEmpty) {
      parsed.sort();
      return parsed;
    }
  }
  return fallback;
}

