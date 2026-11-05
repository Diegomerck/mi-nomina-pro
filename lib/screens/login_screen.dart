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
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _empNoController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _loginError = null;
    });

    try {
      final googleProvider = GoogleAuthProvider();
      googleProvider.setCustomParameters({'prompt': 'select_account'});

      if (kIsWeb) {
        await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        await FirebaseAuth.instance.signInWithProvider(googleProvider);
      }
      // Once authenticated, AuthWrapper automatically transitions to TelevisaApp,
      // which handles the employee number prompt and Smart Account Merge if needed.
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      // Ignore user-initiated popup closure / cancellation
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'canceled' ||
          e.code == 'cancelled-popup-request' ||
          e.code == 'user-cancelled') {
        setState(() {
          _isGoogleLoading = false;
        });
        return;
      }
      String msg = "No se pudo iniciar sesión con Google.";
      if (e.code == 'operation-not-allowed') {
        msg =
            "El inicio de sesión con Google aún no está habilitado en Firebase Console.";
      } else if (e.code == 'popup-blocked') {
        msg =
            "El navegador bloqueó la ventana emergente de Google. Permite las ventanas emergentes e intenta de nuevo.";
      } else if (e.code == 'network-request-failed') {
        msg = "Error de red. Verifica tu conexión a internet.";
      } else if (e.message != null && e.message!.isNotEmpty) {
        msg = "Error de Google Sign-In: ${e.message}";
      }
      setState(() {
        _isGoogleLoading = false;
        _loginError = msg;
      });
    } catch (e) {
      if (!mounted) return;
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('popup_closed') ||
          errStr.contains('popup-closed-by-user') ||
          errStr.contains('cancel')) {
        setState(() {
          _isGoogleLoading = false;
        });
        return;
      }
      setState(() {
        _isGoogleLoading = false;
        _loginError = "Error al conectar con Google: $e";
      });
    }
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
                  onPressed: (_isLoading || _isGoogleLoading) ? null : _submit,
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

                const SizedBox(height: 16),

                // Divider "O continúa con"
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.white.withAlpha(35),
                        thickness: 1,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        "O continúa con",
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.white.withAlpha(35),
                        thickness: 1,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Google Sign-In Button
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1F2937),
                    disabledBackgroundColor: Colors.white.withAlpha(180),
                    minimumSize: const Size(double.infinity, 52),
                    side: const BorderSide(color: Colors.white, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  onPressed: (_isLoading || _isGoogleLoading)
                      ? null
                      : _signInWithGoogle,
                  child: _isGoogleLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF1F2937)),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFF3F4F6),
                                border: Border.all(
                                  color: const Color(0xFFD1D5DB),
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                "G",
                                style: TextStyle(
                                  color: Color(0xFF4285F4),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _isSignUp
                                  ? "Registrarse con Google"
                                  : "Continuar con Google",
                              style: const TextStyle(
                                color: Color(0xFF1F2937),
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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

class _GoogleDonorAccountInfo {
  final String uid;
  final String empNumber;
  final String firstName;
  final String lastName;
  final String email;
  final String recoveryEmail;
  final String directoryEmail;
  final double salary;
  final String salaryRaw;
  final int shiftCount;
  final Map<String, dynamic> rawData;

  const _GoogleDonorAccountInfo({
    required this.uid,
    required this.empNumber,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.recoveryEmail,
    required this.directoryEmail,
    required this.salary,
    required this.salaryRaw,
    required this.shiftCount,
    required this.rawData,
  });

  String get fullName {
    final full = "$firstName $lastName".trim();
    return full.isNotEmpty ? full : "Empleado #$empNumber";
  }
}

extension _GoogleSetupAndMergeExt on _TelevisaAppState {
  Future<void> _checkAndHandleGoogleEmployeeSetup() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || isAppAdminUser(user)) return;

    final bool isGoogleUser =
        user.providerData.any((p) => p.providerId == 'google.com');
    if (!isGoogleUser) return;

    final String currentEmp = _userEmpNoController.text.trim();
    if (currentEmp.isNotEmpty) return;

    // Double-check cloud document in case employee_number was just saved
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final d = doc.data();
        final cloudEmp =
            (d?['user_emp'] ?? d?['employee_number'] ?? '').toString().trim();
        if (cloudEmp.isNotEmpty) {
          _rebuild(() {
            _userEmpNoController.text = cloudEmp;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("Error checking Google user doc: $e");
    }

    if (!mounted) return;
    await _showGoogleEmployeeSetupDialog(user);
  }

  Future<_GoogleDonorAccountInfo?> _findDonorAccountForEmployeeNumber(
      String empNo, String currentUid) async {
    final cleanEmp = empNo.trim();
    if (cleanEmp.isEmpty) return null;

    String? donorUid;
    Map<String, dynamic>? donorData;
    String directoryEmail = '';

    // 1. Check employee_directory/{cleanEmp}
    try {
      final dirDoc = await FirebaseFirestore.instance
          .collection('employee_directory')
          .doc(cleanEmp)
          .get();
      if (dirDoc.exists) {
        final d = dirDoc.data();
        directoryEmail = (d?['email'] ?? d?['recovery_email'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
        final uidFromDir = (d?['uid'] ?? '').toString().trim();
        if (uidFromDir.isNotEmpty && uidFromDir != currentUid) {
          final uDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uidFromDir)
              .get();
          if (uDoc.exists && uDoc.data()?['is_merged'] != true) {
            donorUid = uDoc.id;
            donorData = uDoc.data();
          }
        }
      }
    } catch (e) {
      debugPrint("Directory lookup during Google setup: $e");
    }

    // 2. Fallback query in users by user_emp
    if (donorUid == null) {
      try {
        final q1 = await FirebaseFirestore.instance
            .collection('users')
            .where('user_emp', isEqualTo: cleanEmp)
            .limit(5)
            .get();
        for (final doc in q1.docs) {
          if (doc.id != currentUid && doc.data()['is_merged'] != true) {
            donorUid = doc.id;
            donorData = doc.data();
            break;
          }
        }
      } catch (e) {
        debugPrint("user_emp query during Google setup: $e");
      }
    }

    // 3. Fallback query in users by employee_number
    if (donorUid == null) {
      try {
        final q2 = await FirebaseFirestore.instance
            .collection('users')
            .where('employee_number', isEqualTo: cleanEmp)
            .limit(5)
            .get();
        for (final doc in q2.docs) {
          if (doc.id != currentUid && doc.data()['is_merged'] != true) {
            donorUid = doc.id;
            donorData = doc.data();
            break;
          }
        }
      } catch (e) {
        debugPrint("employee_number query during Google setup: $e");
      }
    }

    // 4. Fallback query in users by legacy email (<empNo>@televisa.com)
    if (donorUid == null) {
      try {
        final legacyEmail = "$cleanEmp@televisa.com".toLowerCase();
        final q3 = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: legacyEmail)
            .limit(5)
            .get();
        for (final doc in q3.docs) {
          if (doc.id != currentUid && doc.data()['is_merged'] != true) {
            donorUid = doc.id;
            donorData = doc.data();
            break;
          }
        }
      } catch (e) {
        debugPrint("legacy email query during Google setup: $e");
      }
    }

    if (donorUid == null || donorData == null) return null;

    int shiftCount = 0;
    try {
      final countSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(donorUid)
          .collection('history')
          .count()
          .get();
      shiftCount = countSnap.count ?? 0;
    } catch (_) {
      try {
        final histSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(donorUid)
            .collection('history')
            .get();
        shiftCount = histSnap.docs.length;
      } catch (_) {
        shiftCount = 0;
      }
    }

    final salaryStr = (donorData['salary'] ?? '0').toString().trim();
    final salaryVal = double.tryParse(salaryStr) ?? 0.0;

    return _GoogleDonorAccountInfo(
      uid: donorUid,
      empNumber: cleanEmp,
      firstName: (donorData['first_name'] ?? '').toString().trim(),
      lastName: (donorData['last_name'] ?? '').toString().trim(),
      email: (donorData['email'] ?? '').toString().trim().toLowerCase(),
      recoveryEmail:
          (donorData['recovery_email'] ?? '').toString().trim().toLowerCase(),
      directoryEmail: directoryEmail,
      salary: salaryVal,
      salaryRaw: salaryStr,
      shiftCount: shiftCount,
      rawData: donorData,
    );
  }

  Future<bool> _verifyDonorPasswordIsolated({
    required _GoogleDonorAccountInfo donor,
    required String password,
  }) async {
    final candidates = <String>{
      if (donor.email.isNotEmpty) donor.email,
      if (donor.recoveryEmail.isNotEmpty) donor.recoveryEmail,
      if (donor.directoryEmail.isNotEmpty) donor.directoryEmail,
      "${donor.empNumber}@televisa.com".toLowerCase(),
    }.toList();

    FirebaseApp? tempApp;
    try {
      final appName =
          'googleMergeVerify_${DateTime.now().millisecondsSinceEpoch}';
      tempApp = await Firebase.initializeApp(
        name: appName,
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);

      for (final candidateEmail in candidates) {
        try {
          final cred = await tempAuth.signInWithEmailAndPassword(
            email: candidateEmail,
            password: password,
          );
          if (cred.user != null) {
            await tempAuth.signOut();
            return true;
          }
        } on FirebaseAuthException catch (_) {
          // Try next candidate
        }
      }
      return false;
    } catch (e) {
      debugPrint("Isolated password verification error: $e");
      return false;
    } finally {
      if (tempApp != null) {
        try {
          await tempApp.delete();
        } catch (_) {}
      }
    }
  }

  Future<void> _saveFreshGoogleEmployeeProfile({
    required User user,
    required String empNo,
    required String firstName,
    required String lastName,
  }) async {
    final cleanEmp = empNo.trim();
    final googleEmail = (user.email ?? '').trim().toLowerCase();

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'employee_number': cleanEmp,
      'user_emp': cleanEmp,
      if (firstName.isNotEmpty) 'first_name': firstName,
      if (lastName.isNotEmpty) 'last_name': lastName,
      'email': googleEmail,
      'recovery_email': googleEmail,
      'is_new_style_user': true,
      'auth_provider': 'google.com',
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (cleanEmp.isNotEmpty && googleEmail.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('employee_directory')
          .doc(cleanEmp)
          .set({
        'uid': user.uid,
        'email': googleEmail,
        'legacy_email': "$cleanEmp@televisa.com",
        'employee_number': cleanEmp,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_emp', cleanEmp);
    if (firstName.isNotEmpty) await prefs.setString('first_name', firstName);
    if (lastName.isNotEmpty) await prefs.setString('last_name', lastName);
    if (googleEmail.isNotEmpty) {
      await prefs.setString('recovery_email', googleEmail);
    }

    if (mounted) {
      _rebuild(() {
        _userEmpNoController.text = cleanEmp;
        if (firstName.isNotEmpty) _firstNameController.text = firstName;
        if (lastName.isNotEmpty) _lastNameController.text = lastName;
        if (googleEmail.isNotEmpty) {
          _recoveryEmailController.text = googleEmail;
        }
      });
    }
  }

  Future<int> _executeSelfServiceGoogleMerge({
    required User googleUser,
    required _GoogleDonorAccountInfo donor,
    required String fallbackFirstName,
    required String fallbackLastName,
    required void Function(String status, double progress) onProgress,
  }) async {
    final targetUid = googleUser.uid;
    final sourceUid = donor.uid;
    final googleEmail = (googleUser.email ?? '').trim().toLowerCase();
    final srcData = donor.rawData;

    onProgress("Descargando historial de turnos de tu cuenta anterior...", 0.15);

    // 1. Copy all shift history documents from sourceUid to targetUid
    final sourceHistorySnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(sourceUid)
        .collection('history')
        .get();

    int copiedCount = 0;
    final totalDocs = sourceHistorySnap.docs.length;
    if (totalDocs > 0) {
      for (int i = 0; i < totalDocs; i += 400) {
        final end = math.min(i + 400, totalDocs);
        final chunk = sourceHistorySnap.docs.sublist(i, end);
        final batch = FirebaseFirestore.instance.batch();
        for (final doc in chunk) {
          final targetDocRef = FirebaseFirestore.instance
              .collection('users')
              .doc(targetUid)
              .collection('history')
              .doc(doc.id);
          batch.set(
              targetDocRef, Map<String, dynamic>.from(doc.data()), SetOptions(merge: true));
          copiedCount++;
        }
        onProgress(
          "Transfiriendo turnos ($copiedCount de $totalDocs)...",
          0.20 + (0.45 * (copiedCount / totalDocs)),
        );
        await batch.commit();
      }
    }

    // 2. Copy settings/unit_share if present
    onProgress("Copiando preferencias de uso compartido...", 0.70);
    try {
      final unitShareDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(sourceUid)
          .collection('settings')
          .doc('unit_share')
          .get();
      if (unitShareDoc.exists && unitShareDoc.data() != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(targetUid)
            .collection('settings')
            .doc('unit_share')
            .set(Map<String, dynamic>.from(unitShareDoc.data()!),
                SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("Notice copying unit_share during Google merge: $e");
    }

    // 3. Copy profile & payroll settings to users/{targetUid}
    onProgress("Sincronizando sueldo, jornada y configuración...", 0.80);
    final mergedFirstName = donor.firstName.isNotEmpty
        ? donor.firstName
        : fallbackFirstName;
    final mergedLastName = donor.lastName.isNotEmpty
        ? donor.lastName
        : fallbackLastName;

    final Map<String, dynamic> targetProfileUpdates = {
      'user_emp': donor.empNumber,
      'employee_number': donor.empNumber,
      'first_name': mergedFirstName,
      'last_name': mergedLastName,
      'email': googleEmail,
      'recovery_email': googleEmail,
      'is_new_style_user': true,
      'auth_provider': 'google.com',
      'merged_from': sourceUid,
      'last_merged_at': FieldValue.serverTimestamp(),
    };

    for (final key in [
      'salary',
      'base_hours',
      'rest_days',
      'retention',
      'fomento',
      'cuota',
      'salary_history',
      'jornada_history',
      'retention_history',
      'fomento_history',
      'cuota_history',
      'rest_days_history',
      'is_unit_manager',
      'role',
    ]) {
      if (srcData[key] != null) {
        targetProfileUpdates[key] = srcData[key];
      }
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(targetUid)
        .set(targetProfileUpdates, SetOptions(merge: true));

    // 4. Update employee_directory/{empNumber} -> targetUid & googleEmail
    onProgress("Actualizando directorio de empleado...", 0.88);
    await FirebaseFirestore.instance
        .collection('employee_directory')
        .doc(donor.empNumber)
        .set({
      'uid': targetUid,
      'email': googleEmail,
      'employee_number': donor.empNumber,
      'legacy_email': "${donor.empNumber}@televisa.com",
      'last_merged_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 5. Clean up donor account documents so no duplicate ghost account remains
    onProgress("Limpiando registros duplicados de la cuenta anterior...", 0.94);
    try {
      if (sourceHistorySnap.docs.isNotEmpty) {
        for (int i = 0; i < sourceHistorySnap.docs.length; i += 400) {
          final end = math.min(i + 400, sourceHistorySnap.docs.length);
          final chunk = sourceHistorySnap.docs.sublist(i, end);
          final batch = FirebaseFirestore.instance.batch();
          for (final doc in chunk) {
            batch.delete(doc.reference);
          }
          await batch.commit();
        }
      }
      final sourceSettingsSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(sourceUid)
          .collection('settings')
          .get();
      for (final doc in sourceSettingsSnap.docs) {
        await doc.reference.delete();
      }
      await FirebaseFirestore.instance
          .collection('users')
          .doc(sourceUid)
          .delete();
    } catch (e) {
      debugPrint("Notice cleaning up donor account after merge: $e");
    }

    // 6. Reload app data from cloud so UI reflects merged shifts & salary immediately
    onProgress("Cargando tu información...", 0.98);
    await _loadData();

    return copiedCount;
  }

  Future<void> _showGoogleEmployeeSetupDialog(User user) async {
    String initialFirst = _firstNameController.text.trim();
    String initialLast = _lastNameController.text.trim();
    if (initialFirst.isEmpty &&
        user.displayName != null &&
        user.displayName!.trim().isNotEmpty) {
      final parts = user.displayName!.trim().split(RegExp(r'\s+'));
      initialFirst = parts.first;
      if (parts.length > 1) {
        initialLast = parts.sublist(1).join(' ');
      }
    }

    final empInputController = TextEditingController();
    final firstNameInputController = TextEditingController(text: initialFirst);
    final lastNameInputController = TextEditingController(text: initialLast);
    final salaryVerifyController = TextEditingController();
    final passwordVerifyController = TextEditingController();

    _GoogleDonorAccountInfo? foundDonor;
    bool isSearching = false;
    bool isMerging = false;
    String mergeStatus = "";
    double mergeProgress = 0.0;
    String? errorMsg;
    String verifyMethod = 'salary'; // 'salary' or 'password'
    bool obscureVerifyPassword = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: false,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              final googleEmail = (user.email ?? '').trim().toLowerCase();
              final bool isEmailAutoVerified = foundDonor != null &&
                  ((googleEmail.isNotEmpty &&
                          (googleEmail == foundDonor!.email ||
                              googleEmail == foundDonor!.recoveryEmail ||
                              googleEmail == foundDonor!.directoryEmail)) ||
                      foundDonor!.salary <= 0);

              Future<void> handleLookupEmployee() async {
                final empNo = empInputController.text.trim();
                final fName = firstNameInputController.text.trim();
                final lName = lastNameInputController.text.trim();

                if (empNo.isEmpty) {
                  setDialogState(() {
                    errorMsg = "Por favor ingresa tu número de empleado";
                  });
                  return;
                }

                setDialogState(() {
                  isSearching = true;
                  errorMsg = null;
                });

                try {
                  final donor = await _findDonorAccountForEmployeeNumber(
                      empNo, user.uid);
                  if (donor == null) {
                    // Brand new employee! Save and close dialog so normal onboarding runs
                    await _saveFreshGoogleEmployeeProfile(
                      user: user,
                      empNo: empNo,
                      firstName: fName,
                      lastName: lName,
                    );
                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop();
                    return;
                  } else {
                    setDialogState(() {
                      isSearching = false;
                      foundDonor = donor;
                      errorMsg = null;
                    });
                  }
                } catch (e) {
                  setDialogState(() {
                    isSearching = false;
                    errorMsg = "Error al verificar el número de empleado: $e";
                  });
                }
              }

              Future<void> handleVerifyAndMerge() async {
                final donor = foundDonor;
                if (donor == null) return;

                if (!isEmailAutoVerified) {
                  if (verifyMethod == 'salary') {
                    final rawSal = salaryVerifyController.text
                        .trim()
                        .replaceAll(',', '')
                        .replaceAll('\$', '');
                    final enteredSalary = double.tryParse(rawSal);
                    if (enteredSalary == null || enteredSalary <= 0) {
                      setDialogState(() {
                        errorMsg =
                            "Ingresa el sueldo diario registrado en tu cuenta anterior";
                      });
                      return;
                    }
                    if ((enteredSalary - donor.salary).abs() > 1.0) {
                      setDialogState(() {
                        errorMsg =
                            "El sueldo ingresado no coincide con el registrado en la cuenta #${donor.empNumber}. Intenta de nuevo o verifica con tu contraseña anterior.";
                      });
                      return;
                    }
                  } else {
                    final pwd = passwordVerifyController.text.trim();
                    if (pwd.isEmpty) {
                      setDialogState(() {
                        errorMsg =
                            "Ingresa la contraseña de tu cuenta anterior";
                      });
                      return;
                    }
                    setDialogState(() {
                      isMerging = true;
                      mergeStatus = "Verificando contraseña de cuenta anterior...";
                      mergeProgress = 0.08;
                      errorMsg = null;
                    });
                    final validPwd = await _verifyDonorPasswordIsolated(
                      donor: donor,
                      password: pwd,
                    );
                    if (!validPwd) {
                      setDialogState(() {
                        isMerging = false;
                        errorMsg =
                            "Contraseña incorrecta. También puedes verificar usando tu Sueldo Diario.";
                      });
                      return;
                    }
                  }
                }

                setDialogState(() {
                  isMerging = true;
                  mergeStatus = "Iniciando fusión de cuenta...";
                  mergeProgress = 0.10;
                  errorMsg = null;
                });

                try {
                  final copiedShifts = await _executeSelfServiceGoogleMerge(
                    googleUser: user,
                    donor: donor,
                    fallbackFirstName: firstNameInputController.text.trim(),
                    fallbackLastName: lastNameInputController.text.trim(),
                    onProgress: (status, progress) {
                      setDialogState(() {
                        mergeStatus = status;
                        mergeProgress = progress;
                      });
                    },
                  );

                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop();

                  if (!mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "¡Cuenta vinculada con éxito! Se transfirieron $copiedShifts turnos a tu acceso con Google.",
                      ),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                } catch (e) {
                  setDialogState(() {
                    isMerging = false;
                    errorMsg = "Error durante la fusión: $e";
                  });
                }
              }

              return AlertDialog(
                scrollable: true,
                backgroundColor: const Color(0xFF1E1E1E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: Colors.orange.withAlpha(80)),
                ),
                title: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        foundDonor == null
                            ? Icons.badge_outlined
                            : Icons.merge_type_rounded,
                        color: Colors.orange,
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      foundDonor == null
                          ? "Vincula tu Número de Empleado"
                          : "¡Cuenta Existente Encontrada!",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                content: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (foundDonor == null) ...[
                        Text(
                          "Has iniciado sesión con Google ($googleEmail).\nIngresa tu número de empleado para continuar o vincular tu historial existente:",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13.5,
                            height: 1.35,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: empInputController,
                          keyboardType: TextInputType.number,
                          enabled: !isSearching,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          onChanged: (_) {
                            if (errorMsg != null) {
                              setDialogState(() => errorMsg = null);
                            }
                          },
                          decoration: InputDecoration(
                            labelText: "Número de Empleado *",
                            hintText: "Ej: 409644",
                            prefixIcon: const Icon(Icons.pin_outlined,
                                color: Colors.orange),
                            filled: true,
                            fillColor: Colors.white.withAlpha(12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Colors.white24),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Colors.orange, width: 2),
                            ),
                            labelStyle: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                            hintStyle: const TextStyle(color: Colors.white30),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: firstNameInputController,
                                enabled: !isSearching,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14),
                                decoration: InputDecoration(
                                  labelText: "Nombre",
                                  filled: true,
                                  fillColor: Colors.white.withAlpha(10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                        color: Colors.white24),
                                  ),
                                  labelStyle: const TextStyle(
                                      color: Colors.white70, fontSize: 13),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: lastNameInputController,
                                enabled: !isSearching,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14),
                                decoration: InputDecoration(
                                  labelText: "Apellido",
                                  filled: true,
                                  fillColor: Colors.white.withAlpha(10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                        color: Colors.white24),
                                  ),
                                  labelStyle: const TextStyle(
                                      color: Colors.white70, fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // STEP 2: Existing account found -> Ask to merge + Smart Verification
                        const Text(
                          "Ya tenemos una cuenta registrada con este número de empleado. ¿Deseas fusionarla con tu cuenta de Google para conservar todos tus turnos y configuración?",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13.5,
                            height: 1.35,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(10),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.orange.withAlpha(80)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person_pin_rounded,
                                      color: Colors.orange, size: 22),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      foundDonor!.fullName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "• No. de Empleado: #${foundDonor!.empNumber}",
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "• Historial guardado: ${foundDonor!.shiftCount} turnos registrados",
                                style: const TextStyle(
                                  color: Colors.amberAccent,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (isEmailAutoVerified) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withAlpha(30),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.greenAccent.withAlpha(100)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.verified_user_rounded,
                                    color: Colors.greenAccent, size: 20),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "Verificación automática exitosa: Tu correo de Google coincide con el registrado en tu cuenta.",
                                    style: TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withAlpha(20),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.blueAccent.withAlpha(80)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.shield_outlined,
                                        color: Colors.lightBlueAccent,
                                        size: 18),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        "Verificación rápida de seguridad",
                                        style: TextStyle(
                                          color: Colors.lightBlueAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  "Confirma que eres el titular de la cuenta ingresando tu sueldo diario actual o tu contraseña anterior:",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ChoiceChip(
                                        label: const Text("Sueldo Diario"),
                                        selected: verifyMethod == 'salary',
                                        selectedColor: Colors.orange,
                                        backgroundColor:
                                            const Color(0xFF2C2C2C),
                                        labelStyle: TextStyle(
                                          color: verifyMethod == 'salary'
                                              ? Colors.black
                                              : Colors.white70,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                        onSelected: isMerging
                                            ? null
                                            : (_) {
                                                setDialogState(() {
                                                  verifyMethod = 'salary';
                                                  errorMsg = null;
                                                });
                                              },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ChoiceChip(
                                        label: const Text("Contraseña"),
                                        selected: verifyMethod == 'password',
                                        selectedColor: Colors.orange,
                                        backgroundColor:
                                            const Color(0xFF2C2C2C),
                                        labelStyle: TextStyle(
                                          color: verifyMethod == 'password'
                                              ? Colors.black
                                              : Colors.white70,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                        onSelected: isMerging
                                            ? null
                                            : (_) {
                                                setDialogState(() {
                                                  verifyMethod = 'password';
                                                  errorMsg = null;
                                                });
                                              },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                if (verifyMethod == 'salary')
                                  TextField(
                                    controller: salaryVerifyController,
                                    enabled: !isMerging,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    onChanged: (_) {
                                      if (errorMsg != null) {
                                        setDialogState(() => errorMsg = null);
                                      }
                                    },
                                    decoration: InputDecoration(
                                      labelText: "Tu sueldo diario registrado",
                                      hintText: "Ej: 876.47",
                                      prefixText: "\$ ",
                                      prefixStyle: const TextStyle(
                                          color: Colors.orange, fontSize: 16),
                                      filled: true,
                                      fillColor: Colors.black26,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      labelStyle: const TextStyle(
                                          color: Colors.orange, fontSize: 13),
                                    ),
                                  )
                                else
                                  TextField(
                                    controller: passwordVerifyController,
                                    enabled: !isMerging,
                                    obscureText: obscureVerifyPassword,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 16),
                                    onChanged: (_) {
                                      if (errorMsg != null) {
                                        setDialogState(() => errorMsg = null);
                                      }
                                    },
                                    decoration: InputDecoration(
                                      labelText: "Contraseña de tu cuenta anterior",
                                      prefixIcon: const Icon(
                                          Icons.lock_outline_rounded,
                                          color: Colors.orange,
                                          size: 20),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          obscureVerifyPassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: Colors.white60,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          setDialogState(() {
                                            obscureVerifyPassword =
                                                !obscureVerifyPassword;
                                          });
                                        },
                                      ),
                                      filled: true,
                                      fillColor: Colors.black26,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      labelStyle: const TextStyle(
                                          color: Colors.orange, fontSize: 13),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                      if (isMerging) ...[
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: mergeProgress > 0 ? mergeProgress : null,
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.orange),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          mergeStatus,
                          style: const TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      if (errorMsg != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withAlpha(35),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.redAccent.withAlpha(140)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: Colors.redAccent, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  errorMsg!,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12.5),
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
                  if (foundDonor == null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isSearching ? null : handleLookupEmployee,
                        child: isSearching
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.black),
                                ),
                              )
                            : const Text(
                                "CONTINUAR",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                    Center(
                      child: TextButton(
                        onPressed: isSearching
                            ? null
                            : () async {
                                Navigator.of(dialogContext).pop();
                                await FirebaseAuth.instance.signOut();
                              },
                        child: const Text(
                          "Cancelar y cerrar sesión",
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isMerging ? null : handleVerifyAndMerge,
                        icon: const Icon(Icons.merge_type_rounded,
                            color: Colors.black),
                        label: const Text(
                          "SÍ, FUSIONAR MI CUENTA",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: isMerging
                              ? null
                              : () {
                                  setDialogState(() {
                                    foundDonor = null;
                                    errorMsg = null;
                                  });
                                },
                          child: const Text(
                            "Cambiar número",
                            style:
                                TextStyle(color: Colors.white60, fontSize: 12.5),
                          ),
                        ),
                        TextButton(
                          onPressed: isMerging
                              ? null
                              : () async {
                                  await _saveFreshGoogleEmployeeProfile(
                                    user: user,
                                    empNo: foundDonor!.empNumber,
                                    firstName:
                                        firstNameInputController.text.trim(),
                                    lastName:
                                        lastNameInputController.text.trim(),
                                  );
                                  if (!dialogContext.mounted) return;
                                  Navigator.of(dialogContext).pop();
                                },
                          child: const Text(
                            "No fusionar (empezar de cero)",
                            style: TextStyle(
                                color: Colors.orangeAccent, fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }
}

