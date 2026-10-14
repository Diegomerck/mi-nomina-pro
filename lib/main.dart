import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'web_reload_stub.dart' if (dart.library.html) 'web_reload.dart';

final Map<String, String> _changelogTitles = {
  "23.11.1": "✨ Versión 23.11.1 (13/10/26) — Modo Luz & Alta Visibilidad",
};

final Map<String, List<String>> _changelogByVersion = {
  "23.11.1": [
    "☀️ Modo Día / Modo Luz: Nuevo botón de alternancia rápida en la barra superior (AppBar) con persistencia automática de tu preferencia.",
    "👁️ Accesibilidad Visual en \"HOY\": Reloj digital más grande y legible, botones de acción aumentados de tamaño con superficie táctil sólida y mayor contraste bajo luz solar directa.",
    "⚡ Registro Manual Directo: Marcaje de entrada y salida manual en 1 solo paso con hora prellenada.",
    "📝 Notas en Turno Activo: Ahora puedes agregar o editar notas de turno directamente sin necesidad de finalizar la jornada primero.",
    "🎨 Contraste Mejorado: Tipografía en negro absoluto y bordes reforzados en todas las pestañas para máxima visibilidad en exteriores.",
    "💰 Cálculo de Nómina / Días No Laborados: Corrección en deducciones por faltas para evitar doble descuento y reflejar \$0.00 en periodos completos sin asistencia.",
  ],
  "23.9.2": [
    "Pestaña Año: Desplazamiento automático enfocado en la semana actual al entrar o seleccionar la pestaña.",
    "Pestaña Ajustes: Edición y guardado individual de campos con confirmación previa y bloqueo de seguridad por defecto.",
    "Pestaña Ajustes: Se eliminaron los botones redundantes 'Guardar Ajustes' y 'Refrescar datos' para un flujo más limpio.",
  ],
  "23.9.1": [
    "Mejora de adaptabilidad: se corrigieron los formularios y pantallas emergentes para que el teclado no bloquee la vista en teléfonos pequeños.",
    "Pestaña Quincena: diseño más compacto con cabecera fija y resumen de semanas en una sola línea.",
    "Iconos para compartir los resúmenes semanales siempre accesibles en la pestaña Quincena.",
    "Pestaña Nómina: desplazamiento automático enfocado en los periodos de pago activos.",
    "Por ahora no es posible acceder a la aplicacion en las redes de Televisa, ya estamos trabajando con Televisa directamente para solucionarlo.",
  ],
  "23.8.1": [
    "Se agregó la opción 'Festivo' para registrar y gestionar días feriados.",
    "Mejora en la pestaña 'Hoy': diseño más compacto de botones y nuevo botón para 'Reiniciar hoy'.",
    "Se agregó un botón de recarga (flecha circular) junto a la campana para actualizar la app a la última versión en cualquier momento.",
  ],
  "23.7.11": [
    "Se agregó una campana de notificaciones para que te informes de las actualizaciones a la app.",
    "Se agregó confirmación para cerrar sesión (para evitar salidas accidentales).",
  ],
  "23.7.10": [
    "Se agregó la opción 'Vacaciones' para marcar días sin afectar tu pago.",
    "Se agregaron notas a los registros en la vista de Quincena.",
    "Se corrigió un error visual en el calendario.",
    "Se ajustó el cálculo de horas extra para mayor precisión, la App aun no toma en cuenta las ayudas de transporte y comida",
  ],
};

int _compareVersions(String v1, String v2) {
  final parts1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  final parts2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  final maxLength =
      parts1.length > parts2.length ? parts1.length : parts2.length;
  for (int i = 0; i < maxLength; i++) {
    final p1 = i < parts1.length ? parts1[i] : 0;
    final p2 = i < parts2.length ? parts2[i] : 0;
    if (p1 != p2) return p1.compareTo(p2);
  }
  return 0;
}

String _getLatestVersion() {
  if (_changelogByVersion.isEmpty) return "0.0.0";
  final sortedVersions = _changelogByVersion.keys.toList()
    ..sort((a, b) => _compareVersions(b, a));
  return sortedVersions.first;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting for Spanish locale (required for web)
  await initializeDateFormatting('es_ES', null);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: AuthWrapper(),
    localizationsDelegates: [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: [
      Locale('es', 'ES'),
      Locale('en', 'US'),
    ],
    locale: Locale('es', 'ES'),
  ));
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return const TelevisaApp();
        }
        return const LoginScreen();
      },
    );
  }
}

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

  Future<void> _submit() async {
    if (_empNoController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Por favor llena todos los campos")));
      return;
    }

    final String input = _empNoController.text.trim();
    final String password = _passwordController.text.trim();

    try {
      String email;
      bool isNewStyleUser = false;

      // DETECT: Is input an email or employee number?
      if (input.contains('@')) {
        // NEW STYLE: Real email address
        email = input.toLowerCase();
        isNewStyleUser = true;
      } else {
        // OLD STYLE: Employee number -> convert to fake email
        email = "$input@televisa.com";
        isNewStyleUser = false;
      }

      if (_isSignUp) {
        // NEW USERS ONLY: Must use real email
        if (!isNewStyleUser) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text("Para nuevos usuarios, usa tu correo electrónico real"),
            backgroundColor: Colors.orange,
          ));
          return;
        }

        // Create account with real email
        final userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Store employee number in Firestore (required for new users)
        final empNumber = _emailController.text.trim();
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'employee_number': empNumber,
          'user_emp': empNumber,
          'is_new_style_user': true,
          'recovery_email': email.toLowerCase(),
          'email': email.toLowerCase(),
        }, SetOptions(merge: true));

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("¡Cuenta creada! Ahora configura tu información"),
          backgroundColor: Colors.green,
        ));

        // After brief delay, let AuthWrapper naturally redirect to TelevisaApp
        // where _checkAndShowOnboarding will trigger the onboarding dialog
        await Future.delayed(const Duration(milliseconds: 500));
      } else {
        // LOGIN: Works for both old and new style
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg = "Error al iniciar sesión";
      if (e.code == 'user-not-found') {
        errorMsg =
            "Usuario no encontrado. ¿Usaste tu correo o número de empleado correcto?";
      } else if (e.code == 'wrong-password') {
        errorMsg = "Contraseña incorrecta";
      } else if (e.code == 'invalid-email') {
        errorMsg = "Correo inválido";
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_person, size: 100, color: Colors.orange),
            const SizedBox(height: 20),
            Text(_isSignUp ? "REGISTRO" : "ACCESO NÓMINA",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            TextField(
              controller: _empNoController,
              keyboardType:
                  _isSignUp ? TextInputType.emailAddress : TextInputType.text,
              style: const TextStyle(color: Colors.white, fontSize: 20),
              decoration: InputDecoration(
                  labelText: _isSignUp
                      ? "Correo Electrónico"
                      : "No. Empleado o Correo",
                  hintText: _isSignUp
                      ? "tu-correo@gmail.com"
                      : "Ej: 12345 o tu-correo@gmail.com",
                  hintStyle:
                      const TextStyle(color: Colors.white30, fontSize: 16),
                  labelStyle: const TextStyle(
                      color: Colors.orange,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white, fontSize: 20),
              decoration: const InputDecoration(
                  labelText: "Contraseña",
                  labelStyle: TextStyle(
                      color: Colors.orange,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ),
            // Show employee number field only during signup (for new users)
            if (_isSignUp) ...[
              const SizedBox(height: 15),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 20),
                decoration: const InputDecoration(
                    labelText: "No. de Empleado",
                    hintText: "Tu número de nómina",
                    hintStyle: TextStyle(color: Colors.white30, fontSize: 14),
                    labelStyle: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withAlpha(60)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.green, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Nuevo: Usa tu correo real para crear cuenta. Podrás recuperar tu contraseña fácilmente.",
                        style:
                            TextStyle(color: Colors.greenAccent, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 30),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    minimumSize: const Size(double.infinity, 60)),
                onPressed: _submit,
                child: Text(_isSignUp ? "CREAR CUENTA" : "ENTRAR",
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold))),
            if (!_isSignUp) ...[
              const SizedBox(height: 10),
              // Password reset disabled on login screen - must be done from Settings when logged in
              // or contact admin if locked out
              TextButton(
                onPressed: () => _showLockedOutHelpDialog(context),
                child: const Text(
                  "¿No puedes entrar?",
                  style: TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
            TextButton(
                onPressed: () => setState(() => _isSignUp = !_isSignUp),
                child: Text(_isSignUp ? "Ya tengo cuenta" : "Registrarse",
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 16)))
          ],
        ),
      ),
    );
  }

  void _showLockedOutHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
      scrollable: true,
          backgroundColor: Colors.grey[900],
          title: const Column(
            children: [
              Icon(
                Icons.help_outline,
                color: Colors.orange,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                "¿No puedes entrar?",
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Para recuperar tu contraseña, debes haber registrado un correo electrónico de recuperación en tu cuenta.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  "Opciones disponibles:",
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  "1. Si tienes sesión iniciada en otro dispositivo:\n   Ve a Ajustes → Cambiar Contraseña → \"¿Olvidaste tu contraseña actual?\"",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  "2. Si no tienes acceso a ningún dispositivo:\n   Contacta al administrador con tu número de empleado para ayuda con tu cuenta.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  "Nota: La recuperación de contraseña solo funciona si previamente registraste un correo electrónico en la sección de Ajustes.",
                  style: TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                "ENTENDIDO",
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  // REMOVED: _showPasswordResetSuccessDialog - now inline in Settings tab
  // The login screen no longer has password reset functionality
  // Users must use Settings tab when logged in, or contact admin if locked out
}

class WorkDay {
  DateTime entrada;
  DateTime salida;
  DateTime? entradaReal; // Actual clock-in time (when button was pressed)
  double sueldoBase;
  double baseHours;
  String id;
  bool isInProgress;
  bool esFalta;
  bool esMantenimiento;
  bool esVacaciones;
  bool esFestivo;
  bool festivoTrabajado;
  String notas;

  WorkDay(
      {required this.entrada,
      required this.salida,
      this.entradaReal,
      required this.sueldoBase,
      this.baseHours = 9.5,
      this.isInProgress = false,
      this.esFalta = false,
      this.esMantenimiento = false,
      this.esVacaciones = false,
      this.esFestivo = false,
      this.festivoTrabajado = false,
      this.notas = "",
      String? id})
      : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  DateTime get effectiveStart {
    if (entradaReal != null && entradaReal!.isAfter(entrada)) {
      return entradaReal!;
    }
    return entrada;
  }

  int get requiredShiftMinutes => (baseHours * 60).round();

  DateTime get requiredCompletionTime =>
      effectiveStart.add(Duration(minutes: requiredShiftMinutes));

  int get actualWorkedMinutes {
    if (isInProgress) return 0;
    return salida.isAfter(effectiveStart)
        ? salida.difference(effectiveStart).inMinutes
        : 0;
  }

  double get totalHours {
    if (isInProgress) return 0.0;
    return (esFalta || esVacaciones || (esFestivo && !festivoTrabajado))
        ? 0.0
        : actualWorkedMinutes / 60.0;
  }

  bool get isOvernight => salida.day != entrada.day;

  double get hourlyRate => baseHours > 0 ? sueldoBase / baseHours : 0.0;

  double get payDeduction {
    if (isInProgress ||
        esFalta ||
        esMantenimiento ||
        esVacaciones ||
        esFestivo) {
      return 0.0;
    }
    if (actualWorkedMinutes < requiredShiftMinutes) {
      int shortfallMinutes = requiredShiftMinutes - actualWorkedMinutes;
      int deficitBlocks = (shortfallMinutes / 30.0).ceil();
      return deficitBlocks * 0.5 * hourlyRate;
    }
    return 0.0;
  }

  double get dailyPay {
    if (isInProgress || esFalta) return 0.0;
    bool isWeekend = entrada.weekday == DateTime.saturday ||
        entrada.weekday == DateTime.sunday;
    double baseDailyPay = isWeekend ? sueldoBase * 2 : sueldoBase;
    if (esMantenimiento || esVacaciones || (esFestivo && !festivoTrabajado)) {
      return baseDailyPay;
    }
    if (esFestivo && festivoTrabajado) return baseDailyPay * 2;

    double pay = baseDailyPay - payDeduction;
    return pay < 0 ? 0.0 : pay;
  }

  double get creditedExtraHours {
    if (isInProgress ||
        esFalta ||
        esMantenimiento ||
        esVacaciones ||
        (esFestivo && !festivoTrabajado)) {
      return 0.0;
    }
    if (actualWorkedMinutes <= requiredShiftMinutes) return 0.0;

    int extraMinutes = actualWorkedMinutes - requiredShiftMinutes;
    int hourBlock = extraMinutes ~/ 60;
    int remainder = extraMinutes % 60;

    double bonus = remainder <= 20 ? 0.0 : (remainder <= 50 ? 0.5 : 1.0);
    return hourBlock + bonus;
  }

  double get extraHoursCount => creditedExtraHours;

  double get extrasMoney {
    if (isInProgress ||
        esFalta ||
        esMantenimiento ||
        esVacaciones ||
        (esFestivo && !festivoTrabajado)) {
      return 0.0;
    }
    if (creditedExtraHours <= 0) return 0.0;
    if (esFestivo && festivoTrabajado) {
      return creditedExtraHours * (hourlyRate * 3);
    }
    return creditedExtraHours * (hourlyRate * 2);
  }

  double get holidayExtraHours =>
      (isInProgress || !(esFestivo && festivoTrabajado))
          ? 0.0
          : creditedExtraHours;

  double get holidayExtrasPay =>
      (isInProgress ||
              !(esFestivo && festivoTrabajado && creditedExtraHours > 0))
          ? 0.0
          : creditedExtraHours * (hourlyRate * 3);

  double get totalPay => (isInProgress) ? 0.0 : (dailyPay + extrasMoney);

  Map<String, dynamic> toJson() => {
        'entrada': entrada.toIso8601String(),
        'salida': salida.toIso8601String(),
        'entradaReal': entradaReal?.toIso8601String(),
        'sueldoBase': sueldoBase,
        'baseHours': baseHours,
        'id': id,
        'isInProgress': isInProgress,
        'esFalta': esFalta,
        'esMantenimiento': esMantenimiento,
        'esVacaciones': esVacaciones,
        'esFestivo': esFestivo,
        'festivoTrabajado': festivoTrabajado,
        'notas': notas,
      };
  factory WorkDay.fromJson(Map<String, dynamic> json) => WorkDay(
        entrada: DateTime.parse(json['entrada']),
        salida: DateTime.parse(json['salida']),
        entradaReal: json['entradaReal'] != null
            ? DateTime.parse(json['entradaReal'])
            : null,
        sueldoBase: (json['sueldoBase'] ?? 0).toDouble(),
        baseHours: (json['baseHours'] ?? 9.5).toDouble(),
        id: json['id'],
        isInProgress: json['isInProgress'] ?? false,
        esFalta: json['esFalta'] ?? false,
        esMantenimiento: json['esMantenimiento'] ?? false,
        esVacaciones:
            json['esVacaciones'] ?? json['esVacacionesFestivo'] ?? false,
        esFestivo: json['esFestivo'] ?? false,
        festivoTrabajado: json['festivoTrabajado'] ?? false,
        notas: json['notas'] ?? "",
      );
}

class OvertimeBreakdown {
  double hours2x;
  double pay2x;
  double hours3x;
  double pay3x;
  OvertimeBreakdown({
    this.hours2x = 0,
    this.pay2x = 0,
    this.hours3x = 0,
    this.pay3x = 0,
  });
  double get totalPay => pay2x + pay3x;
}

class TelevisaApp extends StatefulWidget {
  const TelevisaApp({super.key});
  @override
  State<TelevisaApp> createState() => _TelevisaAppState();
}

class _TelevisaAppState extends State<TelevisaApp> {
  List<WorkDay> _weeklyHistory = [];
  bool _isClockedIn = false;
  bool _completedToday = false;
  DateTime? _entradaDateTime;
  DateTime? _salidaDateTime;
  String? _currentShiftId;
  DateTime _selectedCalendarDay = DateTime.now();
  bool _isProcessing = false;
  bool _isLoading = true; // Loading screen state
  String? _lastSeenVersion;

  int get _unreadChangelogCount {
    final lastSeen = _lastSeenVersion ?? "0.0.0";
    int count = 0;
    _changelogByVersion.forEach((version, _) {
      if (_compareVersions(version, lastSeen) > 0) {
        count++;
      }
    });
    return count;
  }

  // Salary history to track changes with effective dates
  List<Map<String, dynamic>> _salaryHistory = [];

  // Theme preference (Dark OLED vs Soft Light)
  bool _isDarkMode = true;

  String _entradaDisplay = "--/-- --:--";
  String _salidaDisplay = "--/-- --:--";
  final TextEditingController _salaryController =
      TextEditingController(text: "");
  final TextEditingController _baseHoursController =
      TextEditingController(text: "9.5");
  final TextEditingController _retentionController =
      TextEditingController(text: "15.22");
  final TextEditingController _fomentoController =
      TextEditingController(text: "2.0");
  final TextEditingController _cuotaController =
      TextEditingController(text: "2.0");
  final TextEditingController _firstNameController =
      TextEditingController(text: "");
  final TextEditingController _lastNameController =
      TextEditingController(text: "");
  final TextEditingController _userEmpNoController =
      TextEditingController(text: "");
  final TextEditingController _recoveryEmailController =
      TextEditingController(text: ""); // For password recovery

  final ScrollController _nominaScrollController = ScrollController();
  final ScrollController _anoScrollController = ScrollController();

  final Map<String, String> _originalFieldValues = {};
  final Set<String> _editingFieldLabels = {};

  late Timer _timer;
  Timer? _countdownTimer;
  String _timeString = "";
  String _dateString = "";
  String _timeRemainingMessage = "";

  final Map<String, Map<String, dynamic>> _payCalendar2026 = {
    "2026001": {
      "weeks": [48, 49, 50],
      "payout": "15/01/26",
      "label": "Ene - 1ra"
    },
    "2026002": {
      "weeks": [51, 52],
      "payout": "30/01/26",
      "label": "Ene - 2da"
    },
    "2026003": {
      "weeks": [1, 2, 3],
      "payout": "13/02/26",
      "label": "Feb - 1ra"
    },
    "2026004": {
      "weeks": [4],
      "payout": "27/02/26",
      "label": "Feb - 2da"
    },
    "2026005": {
      "weeks": [5, 6, 7],
      "payout": "13/03/26",
      "label": "Mar - 1ra"
    },
    "2026006": {
      "weeks": [8],
      "payout": "30/03/26",
      "label": "Mar - 2da"
    },
    "2026007": {
      "weeks": [9, 10, 11],
      "payout": "15/04/26",
      "label": "Abr - 1ra"
    },
    "2026008": {
      "weeks": [12],
      "payout": "30/04/26",
      "label": "Abr - 2da"
    },
    "2026009": {
      "weeks": [13, 14, 15],
      "payout": "15/05/26",
      "label": "May - 1ra"
    },
    "2026010": {
      "weeks": [16, 17],
      "payout": "29/05/26",
      "label": "May - 2da"
    },
    "2026011": {
      "weeks": [18, 19, 20],
      "payout": "15/06/26",
      "label": "Jun - 1ra"
    },
    "2026012": {
      "weeks": [21, 22],
      "payout": "30/06/26",
      "label": "Jun - 2da"
    },
    "2026013": {
      "weeks": [23, 24, 25],
      "payout": "15/07/26",
      "label": "Jul - 1ra"
    },
    "2026014": {
      "weeks": [26],
      "payout": "30/07/26",
      "label": "Jul - 2da"
    },
    "2026015": {
      "weeks": [27, 28, 29],
      "payout": "14/08/26",
      "label": "Ago - 1ra"
    },
    "2026016": {
      "weeks": [30],
      "payout": "28/08/26",
      "label": "Ago - 2da"
    },
    "2026017": {
      "weeks": [31, 32, 33],
      "payout": "15/09/26",
      "label": "Sep - 1ra"
    },
    "2026018": {
      "weeks": [34],
      "payout": "30/09/26",
      "label": "Sep - 2da"
    },
    "2026019": {
      "weeks": [35, 36, 37],
      "payout": "15/10/26",
      "label": "Oct - 1ra"
    },
    "2026020": {
      "weeks": [38, 39],
      "payout": "30/10/26",
      "label": "Oct - 2da"
    },
    "2026021": {
      "weeks": [40, 41, 42],
      "payout": "13/11/26",
      "label": "Nov - 1ra"
    },
    "2026022": {
      "weeks": [43],
      "payout": "30/11/26",
      "label": "Nov - 2da"
    },
    "2026023": {
      "weeks": [44, 45, 46],
      "payout": "15/12/26",
      "label": "Dic - 1ra"
    },
    "2026024": {
      "weeks": [47, 48],
      "payout": "30/12/26",
      "label": "Dic - 2da"
    },
  };

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Start loading
    setState(() => _isLoading = true);

    // Simulate minimum loading time for UX (1.5 seconds)
    await Future.delayed(const Duration(milliseconds: 1500));

    // Load data
    await _loadData();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) => _updateTime());

    // End loading
    if (mounted) {
      setState(() => _isLoading = false);
    }

    // Check if user needs onboarding (missing salary or base hours)
    _checkAndShowOnboarding();
  }

  void _checkAndShowOnboarding() {
    // Check if salary or base hours are empty/default
    bool needsOnboarding = _salaryController.text.isEmpty ||
        double.tryParse(_salaryController.text) == 0.0;

    if (needsOnboarding && mounted) {
      // Small delay to ensure UI is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        _showOnboardingDialog();
      });
    }
  }

  void _showOnboardingDialog() {
    final TextEditingController salaryInputController = TextEditingController();
    final TextEditingController jornadaInputController =
        TextEditingController(text: "9.5");

    showDialog(
      context: context,
      barrierDismissible: false, // User CANNOT dismiss by tapping outside
      builder: (BuildContext context) {
        return PopScope(
          // Prevent back button from closing - user MUST complete setup
          canPop: false,
          child: AlertDialog(
      scrollable: true,
            backgroundColor: Colors.grey[900],
            title: const Column(
              children: [
                Icon(
                  Icons.person_add,
                  color: Colors.orange,
                  size: 48,
                ),
                SizedBox(height: 16),
                Text(
                  "¡Bienvenido a Mi Nómina Pro!",
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Para poder calcular correctamente tus pagos y horas extras, necesitamos que nos proporciones la siguiente información:",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "SUELDO DIARIO BASE",
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: salaryInputController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      hintText: "Ej: 876.47",
                      hintStyle: TextStyle(color: Colors.white30),
                      prefixText: "\$ ",
                      prefixStyle:
                          TextStyle(color: Colors.orange, fontSize: 20),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.orange),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.orange, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "HORAS BASE DIARIAS (JORNADA)",
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: jornadaInputController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      hintText: "Ej: 9.5",
                      hintStyle: TextStyle(color: Colors.white30),
                      suffixText: " hrs",
                      suffixStyle:
                          TextStyle(color: Colors.white70, fontSize: 16),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.orange),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.orange, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withAlpha(60)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.orange, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Esta información es necesaria para calcular tus horas extras y pagos correctamente.",
                            style: TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    // Validate inputs
                    double? salary =
                        double.tryParse(salaryInputController.text);
                    double? jornada =
                        double.tryParse(jornadaInputController.text);

                    if (salary == null || salary <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Por favor ingresa un sueldo válido"),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (jornada == null || jornada <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Por favor ingresa una jornada válida"),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Update controllers
                    setState(() {
                      _salaryController.text = salary.toString();
                      _baseHoursController.text = jornada.toString();
                    });

                    // Save to cloud
                    await _saveData();

                    if (!context.mounted) return;
                    Navigator.pop(context);

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("¡Información guardada exitosamente!"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text(
                    "GUARDAR Y CONTINUAR",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<DateTime?> _showSalaryChangeDialog(
      String oldSalary, String newSalary) async {
    DateTime selectedDate = DateTime.now();
    final DateTime firstDate = DateTime(2025);
    final DateTime lastDate = DateTime(2027);

    // Ensure we're not in the middle of a build
    await Future.delayed(Duration.zero);

    if (!mounted) return null;

    return await showDialog<DateTime>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
      scrollable: true,
              backgroundColor: Colors.grey[900],
              title: const Column(
                children: [
                  Icon(
                    Icons.trending_up,
                    color: Colors.greenAccent,
                    size: 48,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "¡Cambio de Sueldo Detectado!",
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withAlpha(50)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Sueldo Anterior:",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                "\$${double.tryParse(oldSalary)?.toStringAsFixed(2) ?? oldSalary}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Nuevo Sueldo:",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                "\$${double.tryParse(newSalary)?.toStringAsFixed(2) ?? newSalary}",
                                style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "¿A PARTIR DE QUÉ FECHA APLICA ESTE CAMBIO?",
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withAlpha(60)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            DateFormat('EEEE, d \'de\' MMMM \'de\' yyyy', 'es')
                                .format(selectedDate),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: firstDate,
                                lastDate: lastDate,
                                locale: const Locale('es', 'ES'),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.dark(
                                        primary: Colors.orange,
                                        onPrimary: Colors.black,
                                        surface: Color(0xFF1E1E1E),
                                        onSurface: Colors.white,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setDialogState(() {
                                  selectedDate = picked;
                                });
                              }
                            },
                            icon: const Icon(Icons.calendar_today,
                                color: Colors.orange),
                            label: const Text(
                              "SELECCIONAR FECHA",
                              style: TextStyle(color: Colors.orange),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: Colors.blueAccent.withAlpha(60)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.blueAccent, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Los registros anteriores a esta fecha mantendrán el sueldo anterior. Los nuevos registros usarán el nuevo sueldo.",
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text(
                    "CANCELAR",
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context, selectedDate),
                  child: const Text(
                    "CONFIRMAR CAMBIO",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Helper to get applicable salary for a specific date
  double _getSalaryForDate(DateTime date) {
    // Normalize date to midnight for comparison
    final normalizedDate = DateTime(date.year, date.month, date.day);

    if (_salaryHistory.isEmpty) {
      // No history at all - use current salary for everything
      return double.tryParse(_salaryController.text) ?? 0.0;
    }

    // Sort history by effective date (oldest first)
    final sortedHistory = [..._salaryHistory]..sort((a, b) {
        final dateA = DateTime.parse(a['effective_date'] as String);
        final dateB = DateTime.parse(b['effective_date'] as String);
        return dateA.compareTo(dateB);
      });

    // Initialize with the salary BEFORE the first change
    // This is the 'previous_salary' of the earliest history entry
    double applicableSalary =
        (sortedHistory.first['previous_salary'] as num?)?.toDouble() ??
            (sortedHistory.first['salary'] as num).toDouble();

    // Apply changes that occurred on or before the target date
    for (var entry in sortedHistory) {
      DateTime effectiveDate =
          DateTime.parse(entry['effective_date'] as String);

      // Compare as dates, not strings
      if (normalizedDate.isAtSameMomentAs(effectiveDate) ||
          normalizedDate.isAfter(effectiveDate)) {
        // This change has taken effect by the target date
        applicableSalary = (entry['salary'] as num).toDouble();
      }
    }

    return applicableSalary;
  }

  CollectionReference get _userHistory => FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser?.uid)
      .collection('history');
  Future<void> _saveData({bool checkSalaryChange = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    // Check for salary change FIRST, before showing loading screen
    if (checkSalaryChange && user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        String? oldSalary = data['salary'] as String?;
        String? newSalary = _salaryController.text;

        if (oldSalary != null &&
            oldSalary.isNotEmpty &&
            newSalary.isNotEmpty &&
            oldSalary != newSalary) {
          // Salary has changed - prompt for effective date
          // Check mounted before showing dialog
          if (!mounted) return;

          // Show dialog WITHOUT loading screen blocking it
          final effectiveDate =
              await _showSalaryChangeDialog(oldSalary, newSalary);
          if (effectiveDate != null) {
            // Add to salary history
            _salaryHistory.add({
              'salary': double.tryParse(newSalary) ?? 0.0,
              'effective_date': DateFormat('yyyy-MM-dd').format(effectiveDate),
              'previous_salary': double.tryParse(oldSalary) ?? 0.0,
            });
            // Save salary history locally
            await prefs.setString('salary_history', jsonEncode(_salaryHistory));
          }
        }
      }
    }

    // NOW start the loading screen for the actual save operation
    if (!mounted) return;
    setState(() => _isProcessing = true);
    try {
      // 1. Save locally
      String jsonHistory =
          jsonEncode(_weeklyHistory.map((e) => e.toJson()).toList());
      await prefs.setString('history_v2', jsonHistory);
      await prefs.setString('salary', _salaryController.text);
      await prefs.setString('salary_history', jsonEncode(_salaryHistory));
      await prefs.setString('base_hours', _baseHoursController.text);
      await prefs.setString('retention', _retentionController.text);
      await prefs.setString('fomento', _fomentoController.text);
      await prefs.setString('cuota', _cuotaController.text);
      await prefs.setString('first_name', _firstNameController.text);
      await prefs.setString('last_name', _lastNameController.text);
      await prefs.setString('user_emp', _userEmpNoController.text);
      await prefs.setString('recovery_email', _recoveryEmailController.text);

      if (_entradaDateTime != null) {
        await prefs.setString(
            'pending_entrada', _entradaDateTime!.toIso8601String());
        if (_entradaRealDateTime != null) {
          await prefs.setString(
              'pending_entrada_real', _entradaRealDateTime!.toIso8601String());
        }
        await prefs.setBool('pending_clocked_in', _isClockedIn);
      } else {
        await prefs.remove('pending_entrada');
        await prefs.remove('pending_entrada_real');
        await prefs.setBool('pending_clocked_in', false);
      }

      // 2. Save to Firebase
      if (user != null) {
        final batch = FirebaseFirestore.instance.batch();

        // Update profile in 'users' collection
        batch.set(
            FirebaseFirestore.instance.collection('users').doc(user.uid),
            {
              'salary': _salaryController.text,
              'salary_history': _salaryHistory,
              'base_hours': _baseHoursController.text,
              'retention': _retentionController.text,
              'fomento': _fomentoController.text,
              'cuota': _cuotaController.text,
              'first_name': _firstNameController.text,
              'last_name': _lastNameController.text,
              'user_emp': _userEmpNoController.text,
              'recovery_email':
                  _recoveryEmailController.text.trim().toLowerCase(),
            },
            SetOptions(merge: true));

        // Update history
        for (var day in _weeklyHistory) {
          batch.set(_userHistory.doc(day.id), day.toJson());
        }

        await batch.commit();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Ajustes guardados con éxito"),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Error: Verifique su conexión a internet"),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _toggleTheme() async {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_is_dark_mode', _isDarkMode);
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    final String? savedVersion = prefs.getString('last_seen_version');
    if (savedVersion == null) {
      await prefs.setString('last_seen_version', "0.0.0");
      _lastSeenVersion = "0.0.0";
    } else {
      _lastSeenVersion = savedVersion;
    }

    setState(() {
      _isDarkMode = prefs.getBool('app_is_dark_mode') ?? true;
      _salaryController.text = prefs.getString('salary') ?? "";

      // Load salary history
      String? salaryHistoryJson = prefs.getString('salary_history');
      if (salaryHistoryJson != null && salaryHistoryJson.isNotEmpty) {
        try {
          _salaryHistory =
              List<Map<String, dynamic>>.from(jsonDecode(salaryHistoryJson));
        } catch (e) {
          _salaryHistory = [];
        }
      }

      _baseHoursController.text = prefs.getString('base_hours') ?? "9.5";
      _retentionController.text = prefs.getString('retention') ?? "15.22";
      _fomentoController.text = prefs.getString('fomento') ?? "2.0";
      _cuotaController.text = prefs.getString('cuota') ?? "2.0";
      _firstNameController.text = prefs.getString('first_name') ?? "";
      _lastNameController.text = prefs.getString('last_name') ?? "";
      _recoveryEmailController.text =
          prefs.getString('recovery_email')?.toLowerCase() ?? "";

      // Load saved employee number or extract from current login email
      String savedEmp = prefs.getString('user_emp') ?? "";
      if (savedEmp.isEmpty && user != null && user.email != null) {
        if (user.email!.contains("@televisa.com")) {
          // Extract the number before the @televisa.com domain
          savedEmp = user.email!.split("@")[0];
        } else if (user.email!.contains("@")) {
          // For new users with real emails, leave empty for now
          // (will be populated from Firestore in _loadData)
          savedEmp = "";
        }
      }
      _userEmpNoController.text = savedEmp;

      // Restore pending session
      String? pendingIn = prefs.getString('pending_entrada');
      String? pendingReal = prefs.getString('pending_entrada_real');
      if (pendingIn != null) {
        _entradaDateTime = DateTime.parse(pendingIn);
        _entradaRealDateTime =
            pendingReal != null ? DateTime.parse(pendingReal) : null;
        _isClockedIn = prefs.getBool('pending_clocked_in') ?? false;
        _entradaDisplay =
            DateFormat('dd/MM - hh:mm a').format(_entradaDateTime!);
        // Restart countdown if still clocked in
        if (_isClockedIn) {
          _startCountdownTimer();
          _updateTimeRemainingMessage();
        }
      }

      String? jsonHistory = prefs.getString('history_v2');
      if (jsonHistory != null) {
        Iterable l = jsonDecode(jsonHistory);
        _weeklyHistory =
            List<WorkDay>.from(l.map((model) => WorkDay.fromJson(model)));
        _weeklyHistory.sort((a, b) => b.entrada.compareTo(a.entrada));
      }
    });

    if (user != null) {
      // 1. Load Settings from Cloud
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _salaryController.text = data['salary'] ?? _salaryController.text;

          // Load salary history from cloud
          if (data['salary_history'] != null) {
            _salaryHistory =
                List<Map<String, dynamic>>.from(data['salary_history']);
            // Also save locally
            prefs.setString('salary_history', jsonEncode(_salaryHistory));
          }

          _baseHoursController.text = data['base_hours'] ?? "9.5";
          _retentionController.text = data['retention'] ?? "15.22";
          _fomentoController.text = data['fomento'] ?? "2.0";
          _cuotaController.text = data['cuota'] ?? "2.0";
          _firstNameController.text = data['first_name'] ?? "";
          _lastNameController.text = data['last_name'] ?? "";
          // Check both field names for backward compatibility
          _userEmpNoController.text =
              data['user_emp'] ?? data['employee_number'] ?? "";
          _recoveryEmailController.text =
              (data['recovery_email'] as String?)?.toLowerCase() ?? "";
        });
      }

      // 2. Load History from Cloud
      final snapshot = await _userHistory.get();
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _weeklyHistory = snapshot.docs
              .map(
                  (doc) => WorkDay.fromJson(doc.data() as Map<String, dynamic>))
              .toList();
          _weeklyHistory.sort((a, b) => b.entrada.compareTo(a.entrada));
          _syncTodayStateFromHistory();
        });
      }
    }
  }

  void _syncTodayStateFromHistory() {
    // 1. Look for an active in-progress shift
    WorkDay? inProgressShift = _weeklyHistory.cast<WorkDay?>().firstWhere(
          (d) => d?.isInProgress == true,
          orElse: () => null,
        );

    if (inProgressShift != null) {
      _currentShiftId = inProgressShift.id;
      _isClockedIn = true;
      _completedToday = false;
      _entradaDateTime = inProgressShift.entrada;
      _entradaRealDateTime = inProgressShift.entradaReal;
      _salidaDateTime = null;
      _entradaDisplay =
          DateFormat('dd/MM - hh:mm a').format(inProgressShift.entrada);
      _salidaDisplay = "--/-- --:--";
      _startCountdownTimer();
      _updateTimeRemainingMessage();
      return;
    }

    // 2. Look for today's completed shift (same calendar day)
    final now = DateTime.now();
    WorkDay? todayCompleted = _weeklyHistory.cast<WorkDay?>().firstWhere(
          (d) =>
              d != null &&
              !d.isInProgress &&
              !d.esFalta &&
              !d.esVacaciones &&
              !(d.esFestivo && !d.festivoTrabajado) &&
              d.entrada.year == now.year &&
              d.entrada.month == now.month &&
              d.entrada.day == now.day,
          orElse: () => null,
        );

    if (todayCompleted != null) {
      _currentShiftId = todayCompleted.id;
      _isClockedIn = false;
      _completedToday = true;
      _entradaDateTime = todayCompleted.entrada;
      _entradaRealDateTime = todayCompleted.entradaReal;
      _salidaDateTime = todayCompleted.salida;
      _entradaDisplay =
          DateFormat('dd/MM - hh:mm a').format(todayCompleted.entrada);
      _salidaDisplay =
          DateFormat('dd/MM - hh:mm a').format(todayCompleted.salida);
      _calculateEarnings(todayCompleted.salida, dayOverride: todayCompleted);
    } else {
      _currentShiftId = null;
      _isClockedIn = false;
      _completedToday = false;
      _entradaDateTime = null;
      _entradaRealDateTime = null;
      _salidaDateTime = null;
      _entradaDisplay = "--/-- --:--";
      _salidaDisplay = "--/-- --:--";
      _countdownTimer?.cancel();
      _timeRemainingMessage = "";
    }
  }



  @override
  void dispose() {
    _timer.cancel();
    _countdownTimer?.cancel();
    _salaryController.dispose();
    _baseHoursController.dispose();
    _retentionController.dispose();
    _fomentoController.dispose();
    _cuotaController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _userEmpNoController.dispose();
    super.dispose();
  }

  int _getWeekNumber(DateTime date) {
    int dayOfYear = int.parse(DateFormat("D").format(date));
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  Map<WorkDay, OvertimeBreakdown> calculateWeeklyOvertimeBreakdown(
      List<WorkDay> weekDays) {
    final sortedDays = [...weekDays]
      ..sort((a, b) => a.entrada.compareTo(a.entrada));

    double accumulatedCreditedOT = 0.0;
    final Map<WorkDay, OvertimeBreakdown> result = {};

    for (final day in sortedDays) {
      final breakdown = OvertimeBreakdown();
      if (!day.isInProgress &&
          !day.esFalta &&
          !day.esMantenimiento &&
          !day.esFestivo &&
          day.creditedExtraHours > 0) {
        double remainingOT = day.creditedExtraHours;
        double hourlyRate = day.hourlyRate; // sueldoBase / baseHours

        while (remainingOT > 0.001) {
          double remaining2xQuota =
              (9.0 - accumulatedCreditedOT).clamp(0.0, double.infinity);
          if (remaining2xQuota > 0) {
            double h2x = remainingOT.clamp(0.0, remaining2xQuota);
            breakdown.hours2x += h2x;
            breakdown.pay2x += h2x * hourlyRate * 2;
            accumulatedCreditedOT += h2x;
            remainingOT -= h2x;
          } else {
            double h3x = remainingOT;
            breakdown.hours3x += h3x;
            breakdown.pay3x += h3x * hourlyRate * 3;
            accumulatedCreditedOT += h3x;
            remainingOT = 0;
          }
        }
      }
      result[day] = breakdown;
    }

    return result;
  }

  void _updateTime() {
    final DateTime now = DateTime.now();
    final List<String> days = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo'
    ];
    final List<String> months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    if (mounted) {
      setState(() {
        _timeString = DateFormat('hh:mm:ss a').format(now);
        // Manual Spanish formatting
        String dayName = days[now.weekday - 1];
        String monthName = months[now.month - 1];
        _dateString = "$dayName, ${now.day} de $monthName ${now.year}";

        // Midnight rollover check: automatically clear yesterday's completed summary
        if (_completedToday && _salidaDateTime != null) {
          if (_salidaDateTime!.year != now.year ||
              _salidaDateTime!.month != now.month ||
              _salidaDateTime!.day != now.day) {
            _completedToday = false;
            _currentShiftId = null;
            _entradaDateTime = null;
            _salidaDateTime = null;
            _entradaDisplay = "--/-- --:--";
            _salidaDisplay = "--/-- --:--";
          }
        }
      });
    }
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTimeRemainingMessage();
    });
  }

  void _updateTimeRemainingMessage() {
    if (!_isClockedIn || _entradaDateTime == null || _completedToday) {
      setState(() => _timeRemainingMessage = "");
      return;
    }

    final now = DateTime.now();
    final double baseHours = double.tryParse(_baseHoursController.text) ?? 9.5;

    // Effective shift start (scheduled vs actual clock-in)
    final DateTime effectiveStart = (_entradaRealDateTime != null &&
            _entradaRealDateTime!.isAfter(_entradaDateTime!))
        ? _entradaRealDateTime!
        : _entradaDateTime!;

    final int requiredShiftMinutes = (baseHours * 60).round();
    final shiftEndTime =
        effectiveStart.add(Duration(minutes: requiredShiftMinutes));

    if (now.isBefore(shiftEndTime)) {
      final reqStr = DateFormat('hh:mm a').format(shiftEndTime);
      setState(() {
        _timeRemainingMessage =
            "Debes marcar tu salida no antes de las $reqStr para completar tu turno";
      });
    } else {
      final int extraMinutes = now.difference(shiftEndTime).inMinutes;
      final int hourBlock = extraMinutes ~/ 60;
      final int remainder = extraMinutes % 60;

      double bonus = remainder <= 20 ? 0.0 : (remainder <= 50 ? 0.5 : 1.0);
      double currentCreditedExtraHours = hourBlock + bonus;

      DateTime nextMilestoneTime;
      String message;

      String hoursStr = currentCreditedExtraHours == 1.0
          ? "1"
          : (currentCreditedExtraHours % 1 == 0
              ? currentCreditedExtraHours.toInt().toString()
              : currentCreditedExtraHours.toString());

      if (hourBlock == 0 && remainder <= 20) {
        nextMilestoneTime = shiftEndTime.add(const Duration(minutes: 21));
        String milestoneStr = DateFormat('hh:mm a').format(nextMilestoneTime);
        message =
            "Aún no tienes horas extra registradas hoy. ¿Deseas esperar hasta las $milestoneStr para generar tu primera media hora extra?";
      } else if (remainder >= 21 && remainder <= 50) {
        nextMilestoneTime =
            shiftEndTime.add(Duration(minutes: hourBlock * 60 + 51));
        String milestoneStr = DateFormat('hh:mm a').format(nextMilestoneTime);
        message =
            "Ya tienes $hoursStr horas extra hoy. ¿Deseas esperar hasta las $milestoneStr para completar la hora completa?";
      } else {
        // remainder >= 51 or (remainder <= 20 and hourBlock > 0)
        int milestoneMins =
            remainder >= 51 ? (hourBlock + 1) * 60 + 21 : hourBlock * 60 + 21;
        nextMilestoneTime = shiftEndTime.add(Duration(minutes: milestoneMins));
        String milestoneStr = DateFormat('hh:mm a').format(nextMilestoneTime);
        message =
            "Ya tienes $hoursStr horas extra hoy. ¿Deseas esperar hasta las $milestoneStr para generar tu próxima media hora extra?";
      }

      setState(() {
        _timeRemainingMessage = message;
      });
    }
  }

  Future<void> _launchURL() async {
    final Uri url = Uri.parse('https://www.merckdesigns.com');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  void _shareSingleWeekSummary(
      List<WorkDay> weekDays, int weekNumber, String weekLabel) {
    if (weekDays.isEmpty) return;

    // Calculate overtime hours only (no pay details)
    final breakdownMap = calculateWeeklyOvertimeBreakdown(weekDays);
    double totalHours = 0.0;
    for (var b in breakdownMap.values) {
      totalHours += b.hours2x + b.hours3x;
    }

    String summary = " RESUMEN SEMANA $weekNumber - $weekLabel\n";
    summary +=
        " Empleado: ${_firstNameController.text} ${_lastNameController.text} (${_userEmpNoController.text})\n--------------------------------\n";

    final List<String> daysES = [
      'Lun',
      'Mar',
      'Mié',
      'Jue',
      'Vie',
      'Sáb',
      'Dom'
    ];
    final List<String> monthsES = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic'
    ];

    // Sort days by date
    final sortedDays = [...weekDays]
      ..sort((a, b) => a.entrada.compareTo(b.entrada));

    for (var day in sortedDays) {
      String date =
          "${daysES[day.entrada.weekday - 1]}, ${day.entrada.day} ${monthsES[day.entrada.month - 1]}";
      String entradaStr = DateFormat('hh:mm a').format(day.entrada);
      String salidaStr = DateFormat('hh:mm a').format(day.salida);

      if (day.esFalta) {
        summary += " $date: FALTA / NO LABORADO\n\n";
      } else if (day.esMantenimiento) {
        summary +=
            " $date (MANTENIMIENTO):\n   Entrada: $entradaStr\n   Salida: $salidaStr\n   Hrs: ${day.totalHours.toStringAsFixed(2)}\n\n";
      } else if (day.esFestivo && !day.festivoTrabajado) {
        summary += " $date: DÍA FESTIVO (NO LABORADO)\n\n";
      } else if (day.esFestivo && day.festivoTrabajado) {
        summary +=
            " $date (DÍA FESTIVO):\n   Entrada: $entradaStr\n   Salida: $salidaStr\n   Hrs: ${day.totalHours}\n   Pago Base: \$${day.sueldoBase.toStringAsFixed(2)} × 2\n   Extras Festivo 3×: \$${day.holidayExtrasPay.toStringAsFixed(2)}\n\n";
      } else {
        final breakdown = breakdownMap[day] ?? OvertimeBreakdown();
        summary +=
            " $date:\n   Entrada: $entradaStr\n   Salida: $salidaStr\n   Hrs: ${day.totalHours.toStringAsFixed(2)} (Base: ${day.baseHours}h + Extra: ${day.extraHoursCount.toStringAsFixed(2)}h)\n   Extras: ${breakdown.hours2x.toStringAsFixed(2)}h (2x) + ${breakdown.hours3x.toStringAsFixed(2)}h (3x)\n\n";
      }
    }

    summary += "--------------------------------\n";
    summary += " TOTAL HORAS EXTRA: ${totalHours.toStringAsFixed(1)} hrs";

    Share.share(summary, subject: 'Resumen Semana $weekNumber - Televisa');
  }

  Future<void> _addAndSortHistory(WorkDay day) async {
    setState(() => _isProcessing = true);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(" Subiendo datos a la nube..."),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.blueAccent));
    setState(() {
      _weeklyHistory.removeWhere((item) =>
          item.entrada.year == day.entrada.year &&
          item.entrada.month == day.entrada.month &&
          item.entrada.day == day.entrada.day);
      _weeklyHistory.add(day);
      _weeklyHistory.sort((a, b) => b.entrada.compareTo(a.entrada));
    });
    await _saveData();

    if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      // Remove "Uploading"
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              " Jornada guardada: ${DateFormat('dd/MM').format(day.entrada)}"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _processRecord(String type, DateTime time) async {
    if (type == "ENTRADA") {
      // Calculate the two nearest 30-minute intervals
      DateTime t1 = DateTime(time.year, time.month, time.day, time.hour,
          (time.minute >= 30) ? 30 : 0);
      DateTime t2 = t1.add(const Duration(minutes: 30));
      String formatTime(DateTime dt) => DateFormat.Hm().format(dt);

      // Show confirmation dialog before proceeding
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
      scrollable: true,
            backgroundColor: Colors.grey[900],
            title: const Text(
              "¿A que hora inicia tu llamado hoy, o a que hora te asignaron que es tu entrada para hoy?",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildButton(formatTime(t1), Colors.orange, () {
                  _executeEntrada(t1, actualTime: time);
                  Navigator.pop(context);
                }),
                const SizedBox(height: 12),
                _buildButton(formatTime(t2), Colors.orange, () {
                  _executeEntrada(t2, actualTime: time);
                  Navigator.pop(context);
                }),
                const SizedBox(height: 20),
                const Text(
                  "Si no fue ninguna de estas 2 opciones, entonces:",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white.withAlpha(12),
                    side: const BorderSide(color: Colors.orange, width: 1.5),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final TimeOfDay? picked = await _showScrollTimePicker(
                      context,
                      initialTime: TimeOfDay.fromDateTime(time),
                      title: "HORA ENTRADA",
                    );
                    if (picked != null) {
                      final DateTime manualTime = DateTime(time.year,
                          time.month, time.day, picked.hour, picked.minute);
                      _executeEntrada(manualTime, actualTime: time);
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.edit, color: Colors.orange, size: 20),
                  label: const Text(
                    "INGRESAR MANUALMENTE",
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  "(Utilizamos esta hora para calcular desde a que hora se cuentan tus horas extras, independientemente de a que hora realmente llegaste a Televisa)",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 17,
                      height: 1.35),
                ),
              ],
            ),
          );
        },
      );
    } else {
      _executeSalida(time);
    }
  }

  DateTime? _entradaRealDateTime; // Store actual clock-in time

  Future<void> _executeEntrada(DateTime assignedTime,
      {DateTime? actualTime}) async {
    setState(() => _isProcessing = true);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(" Guardando entrada en la nube..."),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.blueAccent));

    final double salaryForDate = _getSalaryForDate(assignedTime);
    final double bHrs = double.tryParse(_baseHoursController.text) ?? 9.5;

    final inProgressDay = WorkDay(
      entrada: assignedTime,
      salida: assignedTime,
      entradaReal: actualTime ?? assignedTime,
      sueldoBase: salaryForDate,
      baseHours: bHrs,
      isInProgress: true,
      esMantenimiento: false,
      esFestivo: false,
      festivoTrabajado: false,
    );

    setState(() {
      _currentShiftId = inProgressDay.id;
      _entradaDateTime = assignedTime;
      _entradaRealDateTime = actualTime ?? assignedTime;
      _salidaDateTime = null;
      _isClockedIn = true;
      _completedToday = false;
      _entradaDisplay = DateFormat('dd/MM - hh:mm a').format(assignedTime);
      _salidaDisplay = "--/-- --:--";

      // Remove any prior in-progress shift before adding this active one
      _weeklyHistory.removeWhere((d) => d.isInProgress);
      _weeklyHistory.insert(0, inProgressDay);
      _weeklyHistory.sort((a, b) => b.entrada.compareTo(a.entrada));
    });

    await _saveData();

    // Start countdown timer for time remaining message
    _startCountdownTimer();
    _updateTimeRemainingMessage();

    if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(" Entrada registrada exitosamente"),
          backgroundColor: Colors.green));
    }
  }

  Future<void> _executeSalida(DateTime time) async {
    setState(() => _isProcessing = true);
    DateTime salidaTime = time;
    if (_entradaDateTime != null && salidaTime.isBefore(_entradaDateTime!)) {
      salidaTime = salidaTime.add(const Duration(days: 1));
    }

    _countdownTimer?.cancel();

    WorkDay? shift = _weeklyHistory.cast<WorkDay?>().firstWhere(
          (d) => d?.id == _currentShiftId || (d != null && d.isInProgress),
          orElse: () => null,
        );

    if (shift != null) {
      shift.salida = salidaTime;
      shift.isInProgress = false;
    } else {
      final double salaryForDate =
          _getSalaryForDate(_entradaDateTime ?? salidaTime);
      final double bHrs = double.tryParse(_baseHoursController.text) ?? 9.5;
      shift = WorkDay(
        entrada: _entradaDateTime ?? salidaTime,
        salida: salidaTime,
        entradaReal: _entradaRealDateTime,
        sueldoBase: salaryForDate,
        baseHours: bHrs,
        isInProgress: false,
      );
      _weeklyHistory.insert(0, shift);
      _weeklyHistory.sort((a, b) => b.entrada.compareTo(a.entrada));
    }

    setState(() {
      _currentShiftId = shift?.id;
      _isClockedIn = false;
      _completedToday = true;
      _salidaDateTime = salidaTime;
      _salidaDisplay = DateFormat('dd/MM - hh:mm a').format(salidaTime);
      _timeRemainingMessage = "";
    });

    _calculateEarnings(salidaTime, dayOverride: shift);

    // Clear pending session from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pending_entrada');
    await prefs.remove('pending_entrada_real');
    await prefs.setBool('pending_clocked_in', false);

    await _saveData();

    if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(" Salida registrada exitosamente"),
        backgroundColor: Colors.green,
      ));
    }
  }

  Future<void> _editEntradaTime() async {
    if (_entradaDateTime == null) return;
    final TimeOfDay? picked = await _showScrollTimePicker(
      context,
      initialTime: TimeOfDay.fromDateTime(_entradaDateTime!),
      title: "EDITAR HORA ENTRADA",
    );
    if (!mounted || picked == null) return;

    final DateTime oldEntrada = _entradaDateTime!;
    final DateTime newEntrada = DateTime(
      oldEntrada.year,
      oldEntrada.month,
      oldEntrada.day,
      picked.hour,
      picked.minute,
    );

    setState(() {
      WorkDay? shift = _weeklyHistory.cast<WorkDay?>().firstWhere(
            (d) =>
                d?.id == _currentShiftId ||
                (d != null && d.isInProgress) ||
                (d != null && d.entrada == oldEntrada) ||
                (_salidaDateTime != null &&
                    d != null &&
                    d.salida == _salidaDateTime),
            orElse: () => null,
          );
      _entradaDateTime = newEntrada;
      _entradaRealDateTime = newEntrada;
      _entradaDisplay = DateFormat('dd/MM - hh:mm a').format(newEntrada);
      if (shift != null) {
        shift.entrada = newEntrada;
        shift.entradaReal = newEntrada;
      }
      if (_completedToday && _salidaDateTime != null) {
        _calculateEarnings(_salidaDateTime!, dayOverride: shift);
      }
    });

    _updateTimeRemainingMessage();
    await _saveData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Hora de entrada actualizada"),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ));
    }
  }

  Future<void> _editSalidaTime() async {
    if (_salidaDateTime == null && _entradaDateTime == null) return;
    DateTime baseSalida = _salidaDateTime ?? DateTime.now();
    final TimeOfDay? picked = await _showScrollTimePicker(
      context,
      initialTime: TimeOfDay.fromDateTime(baseSalida),
      title: "EDITAR HORA SALIDA",
    );
    if (!mounted || picked == null) return;

    DateTime newSalida = DateTime(
      baseSalida.year,
      baseSalida.month,
      baseSalida.day,
      picked.hour,
      picked.minute,
    );

    if (_entradaDateTime != null && newSalida.isBefore(_entradaDateTime!)) {
      newSalida = newSalida.add(const Duration(days: 1));
    }

    setState(() {
      _salidaDateTime = newSalida;
      _salidaDisplay = DateFormat('dd/MM - hh:mm a').format(newSalida);
      WorkDay? shift = _weeklyHistory.cast<WorkDay?>().firstWhere(
            (d) =>
                d?.id == _currentShiftId ||
                (d != null && d.entrada == _entradaDateTime),
            orElse: () => null,
          );
      if (shift != null) {
        shift.salida = newSalida;
        shift.isInProgress = false;
        _calculateEarnings(newSalida, dayOverride: shift);
      }
    });

    await _saveData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Hora de salida actualizada"),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ));
    }
  }

  bool _isShiftFromPreviousDay() {
    if (!_isClockedIn || _entradaDateTime == null) return false;
    final now = DateTime.now();
    return _entradaDateTime!.year != now.year ||
        _entradaDateTime!.month != now.month ||
        _entradaDateTime!.day != now.day;
  }

  Future<void> _showForgottenClockOutDialog() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          "¿Registrar día nuevo?",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Se eliminará el turno sin salida iniciado el ${DateFormat('dd/MM hh:mm a').format(_entradaDateTime!)} de la nube y podrás registrar tu entrada de hoy.",
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text("CANCELAR", style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("ELIMINAR Y EMPEZAR HOY",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    _countdownTimer?.cancel();

    WorkDay? inProgressShift = _weeklyHistory.cast<WorkDay?>().firstWhere(
          (d) => d?.isInProgress == true || d?.id == _currentShiftId,
          orElse: () => null,
        );

    if (inProgressShift != null) {
      await _userHistory.doc(inProgressShift.id).delete();
      _weeklyHistory.removeWhere((d) => d.id == inProgressShift.id);
    }

    setState(() {
      _currentShiftId = null;
      _isClockedIn = false;
      _completedToday = false;
      _entradaDateTime = null;
      _entradaRealDateTime = null;
      _salidaDateTime = null;
      _entradaDisplay = "--/-- --:--";
      _salidaDisplay = "--/-- --:--";
      _timeRemainingMessage = "";
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pending_entrada');
    await prefs.remove('pending_entrada_real');
    await prefs.setBool('pending_clocked_in', false);

    await _saveData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text("Turno anterior eliminado. Listo para registrar hoy."),
        backgroundColor: Colors.green,
      ));
    }
  }

  Future<void> _deleteTodayShift() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.redAccent),
            SizedBox(width: 8),
            Text(
              "Eliminar Registro",
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          "¿Eliminar el registro de hoy? Se borrará de la nube y podrás registrar el día nuevamente.",
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("CANCELAR",
                style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("ELIMINAR",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    _countdownTimer?.cancel();

    WorkDay? shift = _weeklyHistory.cast<WorkDay?>().firstWhere(
          (d) =>
              d?.id == _currentShiftId ||
              (_entradaDateTime != null &&
                  d != null &&
                  d.entrada == _entradaDateTime) ||
              (_salidaDateTime != null &&
                  d != null &&
                  d.salida == _salidaDateTime) ||
              (d != null &&
                  d.entrada.year == DateTime.now().year &&
                  d.entrada.month == DateTime.now().month &&
                  d.entrada.day == DateTime.now().day),
          orElse: () => null,
        );

    if (shift != null) {
      await _userHistory.doc(shift.id).delete();
      _weeklyHistory.removeWhere((d) => d.id == shift.id);
    }

    setState(() {
      _currentShiftId = null;
      _isClockedIn = false;
      _completedToday = false;
      _entradaDateTime = null;
      _entradaRealDateTime = null;
      _salidaDateTime = null;
      _entradaDisplay = "--/-- --:--";
      _salidaDisplay = "--/-- --:--";
      _timeRemainingMessage = "";
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pending_entrada');
    await prefs.remove('pending_entrada_real');
    await prefs.setBool('pending_clocked_in', false);

    await _saveData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Registro de hoy eliminado"),
        backgroundColor: Colors.green,
      ));
    }
  }

  void _calculateEarnings(DateTime salida, {WorkDay? dayOverride}) {
    setState(() {});
  }

  Widget _buildShiftRatingSelector(WorkDay? shift) {
    if (shift == null) return const SizedBox.shrink();

    int selectedIndex = 0;
    if (shift.esMantenimiento) {
      selectedIndex = 1;
    } else if (shift.esFestivo && shift.festivoTrabajado) {
      selectedIndex = 2;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.white.withAlpha(16) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isDarkMode ? Colors.white12 : const Color(0xFFCBD5E1),
          width: _isDarkMode ? 1.0 : 1.5,
        ),
        boxShadow: _isDarkMode
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              "TIPO DE JORNADA:",
              style: TextStyle(
                color: _isDarkMode ? Colors.white60 : const Color(0xFF334155),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Row(
            children: [
              _buildRatingOption(
                label: "JORNADA REGULAR",
                isSelected: selectedIndex == 0,
                activeColor: _isDarkMode ? Colors.orange : const Color(0xFFC2410C),
                onTap: () async {
                  if (selectedIndex == 0) return;
                  setState(() {
                    shift.esMantenimiento = false;
                    shift.esFestivo = false;
                    shift.festivoTrabajado = false;
                    if (_completedToday && _salidaDateTime != null) {
                      _calculateEarnings(_salidaDateTime!, dayOverride: shift);
                    }
                  });
                  await _saveData();
                },
              ),
              const SizedBox(width: 8),
              _buildRatingOption(
                label: "MANTENIMIENTO",
                isSelected: selectedIndex == 1,
                activeColor: _isDarkMode ? Colors.blueAccent : const Color(0xFF1D4ED8),
                onTap: () async {
                  if (selectedIndex == 1) return;
                  setState(() {
                    shift.esMantenimiento = true;
                    shift.esFestivo = false;
                    shift.festivoTrabajado = false;
                    if (_completedToday && _salidaDateTime != null) {
                      _calculateEarnings(_salidaDateTime!, dayOverride: shift);
                    }
                  });
                  await _saveData();
                },
              ),
              const SizedBox(width: 8),
              _buildRatingOption(
                label: "FESTIVO LABORADO",
                isSelected: selectedIndex == 2,
                activeColor: _isDarkMode ? Colors.purpleAccent : const Color(0xFF7E22CE),
                onTap: () async {
                  if (selectedIndex == 2) return;
                  setState(() {
                    shift.esMantenimiento = false;
                    shift.esFestivo = true;
                    shift.festivoTrabajado = true;
                    if (_completedToday && _salidaDateTime != null) {
                      _calculateEarnings(_salidaDateTime!, dayOverride: shift);
                    }
                  });
                  await _saveData();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingOption({
    required String label,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    Color bg = isSelected
        ? (_isDarkMode ? activeColor.withAlpha(50) : activeColor.withAlpha(30))
        : (_isDarkMode ? Colors.black26 : const Color(0xFFF3F4F6));
    Color borderC = isSelected
        ? activeColor
        : (_isDarkMode ? Colors.white10 : const Color(0xFF94A3B8));
    double borderWidth = isSelected ? (_isDarkMode ? 1.5 : 1.8) : (_isDarkMode ? 1.0 : 1.2);
    Color textC = isSelected
        ? (_isDarkMode ? Colors.white : activeColor)
        : (_isDarkMode ? Colors.white54 : const Color(0xFF334155));
    Color iconC = isSelected
        ? activeColor
        : (_isDarkMode ? Colors.white38 : const Color(0xFF64748B));

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: borderC,
              width: borderWidth,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: 15,
                color: iconC,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: textC,
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while initializing
    if (_isLoading) {
      return Scaffold(
        backgroundColor:
            _isDarkMode ? const Color(0xFF121212) : const Color(0xFFDDE3EA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Mi Nómina Pro",
                style: TextStyle(
                  color: _isDarkMode ? Colors.orange : const Color(0xFFD9531E),
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "v.23.11.1 13/10/26",
                style: TextStyle(
                  color: _isDarkMode ? Colors.orangeAccent : const Color(0xFFD9531E),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),
              CircularProgressIndicator(
                color: _isDarkMode ? Colors.orange : const Color(0xFFD9531E),
                strokeWidth: 4,
              ),
              const SizedBox(height: 20),
              Text(
                "Cargando...",
                style: TextStyle(
                  color: _isDarkMode ? Colors.white.withAlpha(128) : const Color(0xFF475569),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        backgroundColor:
            _isDarkMode ? const Color(0xFF121212) : const Color(0xFFDDE3EA),
        appBar: AppBar(
          backgroundColor: _isDarkMode ? Colors.black : Colors.white,
          elevation: _isDarkMode ? 0 : 1,
          title: Text("Mi Nómina Pro",
              style: TextStyle(
                  color: _isDarkMode ? Colors.orange : const Color(0xFFD9531E),
                  fontWeight: FontWeight.bold,
                  fontSize: 24)),
          actions: [
            IconButton(
              icon: Icon(
                _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: _isDarkMode ? Colors.white70 : const Color(0xFF475569),
              ),
              tooltip:
                  _isDarkMode ? "Cambiar a modo día" : "Cambiar a modo noche",
              onPressed: _toggleTheme,
            ),
            Badge(
              label: Text('$_unreadChangelogCount',
                  style: const TextStyle(fontSize: 10, color: Colors.white)),
              backgroundColor:
                  _unreadChangelogCount > 0 ? Colors.red : Colors.grey[700],
              child: IconButton(
                icon: Icon(Icons.notifications_outlined,
                    color: _isDarkMode ? Colors.white54 : const Color(0xFF475569)),
                onPressed: _showChangelogDialog,
              ),
            ),
            IconButton(
              icon: Icon(Icons.refresh,
                  color: _isDarkMode ? Colors.white54 : const Color(0xFF475569)),
              tooltip: 'Actualizar / Recargar app',
              onPressed: () async {
                if (kIsWeb) {
                  await reloadApp();
                } else {
                  // Fallback for non-web
                  setState(() {});
                }
              },
            ),
            IconButton(
              icon: Icon(Icons.logout,
                  color: _isDarkMode ? Colors.white54 : const Color(0xFF475569)),
              onPressed: () => _confirmSignOut(context),
            ),
          ],
          bottom: TabBar(
            onTap: (index) {
              if (index == 2) {
                _scrollToCurrentWeek();
              }
              if (index == 3) {
                _scrollToActiveNomina();
              }
            },
            indicatorColor:
                _isDarkMode ? Colors.orange : const Color(0xFFD9531E),
            labelColor:
                _isDarkMode ? Colors.orange : const Color(0xFFD9531E),
            unselectedLabelColor:
                _isDarkMode ? Colors.white70 : const Color(0xFF475569),
            labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            isScrollable: true,
            tabs: const [
              Tab(text: "HOY", icon: Icon(Icons.access_time, size: 28)),
              Tab(text: "QUINCENA", icon: Icon(Icons.calendar_month, size: 28)),
              Tab(text: "AÑO", icon: Icon(Icons.calendar_today, size: 28)),
              Tab(text: "NÓMINA", icon: Icon(Icons.payments, size: 28)),
              Tab(text: "EXTRAS", icon: Icon(Icons.star, size: 28)),
              Tab(text: "AJUSTES", icon: Icon(Icons.settings, size: 28)),
            ],
          ),
        ),
        persistentFooterButtons: [
          GestureDetector(
            onTap: _launchURL,
            child: const Padding(
              padding: EdgeInsets.only(right: 10),
              child: Text("MD",
                  style: TextStyle(
                      color: Colors.white12,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2)),
            ),
          )
        ],
        persistentFooterAlignment: AlignmentDirectional.centerEnd,
        body: TabBarView(children: [
          _buildHoyTab(),
          _buildQuincenaTab(),
          _buildAnoTab(),
          _buildNominaTab(),
          _buildExtrasTab(),
          _buildSettingsTab()
        ]),
      ),
    );
  }

  Widget _buildTodaySummaryCard(WorkDay day) {
    final List<String> fullMonthsES = [
      "Enero",
      "Febrero",
      "Marzo",
      "Abril",
      "Mayo",
      "Junio",
      "Julio",
      "Agosto",
      "Septiembre",
      "Octubre",
      "Noviembre",
      "Diciembre"
    ];
    final List<String> daysES = [
      "Lunes",
      "Martes",
      "Miércoles",
      "Jueves",
      "Viernes",
      "Sábado",
      "Domingo"
    ];
    final String dateHeader =
        "${daysES[day.entrada.weekday - 1]}, ${day.entrada.day} ${fullMonthsES[day.entrada.month - 1]}";

    final int existingIndex = _weeklyHistory.indexOf(day);

    if (day.esFalta) {
      return Card(
        color: _isDarkMode ? Colors.red.withAlpha(40) : Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
              color: _isDarkMode
                  ? Colors.redAccent.withAlpha(120)
                  : const Color(0xFFEF9A9A),
              width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dateHeader,
                          style: TextStyle(
                              color: _isDarkMode
                                  ? Colors.redAccent
                                  : const Color(0xFFC62828),
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: _isDarkMode
                                ? Colors.red.withAlpha(60)
                                : const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(4)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cancel,
                                color: _isDarkMode
                                    ? Colors.redAccent
                                    : const Color(0xFFC62828),
                                size: 14),
                            const SizedBox(width: 4),
                            Text("FALTA / NO LABORADO",
                                style: TextStyle(
                                    color: _isDarkMode
                                        ? Colors.redAccent
                                        : const Color(0xFFC62828),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit,
                            color: _isDarkMode
                                ? Colors.orange
                                : const Color(0xFFD9531E),
                            size: 22),
                        tooltip: "Editar notas",
                        onPressed: existingIndex >= 0
                            ? () => _editExistingWorkDay(existingIndex)
                            : null,
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline,
                            color: _isDarkMode
                                ? Colors.white54
                                : const Color(0xFF6B7280),
                            size: 24),
                        tooltip: "Eliminar registro",
                        onPressed: _deleteTodayShift,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isDarkMode
                      ? Colors.red.withAlpha(20)
                      : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: _isDarkMode
                          ? Colors.redAccent.withAlpha(100)
                          : const Color(0xFFEF9A9A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("FALTA - DÍA NO LABORADO",
                        style: TextStyle(
                            color: _isDarkMode
                                ? Colors.redAccent
                                : const Color(0xFFC62828),
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("Pago: \$0.00 | Día descontado / sin salario",
                        style: TextStyle(
                            color: _isDarkMode
                                ? Colors.white70
                                : const Color(0xFF4B5563),
                            fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Divider(
                  color: _isDarkMode
                      ? Colors.white24
                      : const Color(0xFFE5E7EB)),
              _buildNotesSection(day),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _isDarkMode
                      ? Colors.redAccent
                      : const Color(0xFFC62828),
                  side: BorderSide(
                      color: _isDarkMode
                          ? Colors.redAccent
                          : const Color(0xFFC62828),
                      width: 1.5),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _deleteTodayShift,
                icon: Icon(Icons.delete_outline,
                    size: 18,
                    color: _isDarkMode
                        ? Colors.redAccent
                        : const Color(0xFFC62828)),
                label: Text(
                  "ELIMINAR REGISTRO DE HOY",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.5,
                    color: _isDarkMode
                        ? Colors.redAccent
                        : const Color(0xFFC62828),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (day.esVacaciones) {
      return Card(
        color: _isDarkMode ? Colors.lightGreen.withAlpha(30) : Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
              color: _isDarkMode
                  ? Colors.lightGreenAccent.withAlpha(120)
                  : const Color(0xFFA5D6A7),
              width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dateHeader,
                          style: TextStyle(
                              color: _isDarkMode
                                  ? Colors.lightGreenAccent
                                  : const Color(0xFF2E7D32),
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: _isDarkMode
                                ? Colors.lightGreen.withAlpha(60)
                                : const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(4)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star,
                                color: _isDarkMode
                                    ? Colors.lightGreenAccent
                                    : const Color(0xFF2E7D32),
                                size: 14),
                            const SizedBox(width: 4),
                            Text("VACACIONES",
                                style: TextStyle(
                                    color: _isDarkMode
                                        ? Colors.lightGreenAccent
                                        : const Color(0xFF2E7D32),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit,
                            color: _isDarkMode
                                ? Colors.orange
                                : const Color(0xFFD9531E),
                            size: 22),
                        tooltip: "Editar notas",
                        onPressed: existingIndex >= 0
                            ? () => _editExistingWorkDay(existingIndex)
                            : null,
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline,
                            color: _isDarkMode
                                ? Colors.white54
                                : const Color(0xFF6B7280),
                            size: 24),
                        tooltip: "Eliminar registro",
                        onPressed: _deleteTodayShift,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isDarkMode
                      ? Colors.lightGreen.withAlpha(20)
                      : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: _isDarkMode
                          ? Colors.lightGreenAccent.withAlpha(100)
                          : const Color(0xFFA5D6A7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("VACACIONES - PAGO BASE COMPLETO",
                        style: TextStyle(
                            color: _isDarkMode
                                ? Colors.lightGreenAccent
                                : const Color(0xFF2E7D32),
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                        "Pago base: \$${day.dailyPay.toStringAsFixed(2)} | Sin descuento ni horas extra",
                        style: TextStyle(
                            color: _isDarkMode
                                ? Colors.white70
                                : const Color(0xFF4B5563),
                            fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Divider(
                  color: _isDarkMode
                      ? Colors.white24
                      : const Color(0xFFE5E7EB)),
              _buildNotesSection(day),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _isDarkMode
                      ? Colors.redAccent
                      : const Color(0xFFC62828),
                  side: BorderSide(
                      color: _isDarkMode
                          ? Colors.redAccent
                          : const Color(0xFFC62828),
                      width: 1.5),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _deleteTodayShift,
                icon: Icon(Icons.delete_outline,
                    size: 18,
                    color: _isDarkMode
                        ? Colors.redAccent
                        : const Color(0xFFC62828)),
                label: Text(
                  "ELIMINAR REGISTRO DE HOY",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.5,
                    color: _isDarkMode
                        ? Colors.redAccent
                        : const Color(0xFFC62828),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (day.esFestivo && !day.festivoTrabajado) {
      return Card(
        color: _isDarkMode ? Colors.purple.withAlpha(30) : Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
              color: _isDarkMode
                  ? Colors.purpleAccent.withAlpha(120)
                  : const Color(0xFFCE93D8),
              width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dateHeader,
                          style: TextStyle(
                              color: _isDarkMode
                                  ? Colors.purpleAccent
                                  : const Color(0xFF7E22CE),
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: _isDarkMode
                                ? Colors.purple.withAlpha(60)
                                : const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(4)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star,
                                color: _isDarkMode
                                    ? Colors.purpleAccent
                                    : const Color(0xFF7E22CE),
                                size: 14),
                            const SizedBox(width: 4),
                            Text("DÍA FESTIVO (NO LABORADO)",
                                style: TextStyle(
                                    color: _isDarkMode
                                        ? Colors.purpleAccent
                                        : const Color(0xFF7E22CE),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit,
                            color: _isDarkMode
                                ? Colors.orange
                                : const Color(0xFFD9531E),
                            size: 22),
                        tooltip: "Editar notas",
                        onPressed: existingIndex >= 0
                            ? () => _editExistingWorkDay(existingIndex)
                            : null,
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline,
                            color: _isDarkMode
                                ? Colors.white54
                                : const Color(0xFF6B7280),
                            size: 24),
                        tooltip: "Eliminar registro",
                        onPressed: _deleteTodayShift,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isDarkMode
                      ? Colors.purple.withAlpha(20)
                      : const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: _isDarkMode
                          ? Colors.purpleAccent.withAlpha(100)
                          : const Color(0xFFCE93D8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("DÍA FESTIVO - PAGO BASE COMPLETO",
                        style: TextStyle(
                            color: _isDarkMode
                                ? Colors.purpleAccent
                                : const Color(0xFF7E22CE),
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                        "Pago base: \$${day.dailyPay.toStringAsFixed(2)} | Sin descuento ni horas extra",
                        style: TextStyle(
                            color: _isDarkMode
                                ? Colors.white70
                                : const Color(0xFF4B5563),
                            fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Divider(
                  color: _isDarkMode
                      ? Colors.white24
                      : const Color(0xFFE5E7EB)),
              _buildNotesSection(day),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _isDarkMode
                      ? Colors.redAccent
                      : const Color(0xFFC62828),
                  side: BorderSide(
                      color: _isDarkMode
                          ? Colors.redAccent
                          : const Color(0xFFC62828),
                      width: 1.5),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _deleteTodayShift,
                icon: Icon(Icons.delete_outline,
                    size: 18,
                    color: _isDarkMode
                        ? Colors.redAccent
                        : const Color(0xFFC62828)),
                label: Text(
                  "ELIMINAR REGISTRO DE HOY",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.5,
                    color: _isDarkMode
                        ? Colors.redAccent
                        : const Color(0xFFC62828),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final int week = _getWeekNumber(day.entrada);
    final List<WorkDay> weekDays = _weeklyHistory
        .where((d) => _getWeekNumber(d.entrada) == week)
        .toList();
    final weeklyOTMap = calculateWeeklyOvertimeBreakdown(weekDays);
    final breakdown = weeklyOTMap[day] ?? OvertimeBreakdown();
    final double realExtrasPay = breakdown.totalPay;
    final double normalHrs =
        day.totalHours > day.baseHours ? day.baseHours : day.totalHours;

    bool startedOnWeekend =
        day.entrada.weekday == DateTime.saturday ||
        day.entrada.weekday == DateTime.sunday;

    Color cardColor;
    Color headerColor;
    Color borderColor;
    if (day.esMantenimiento) {
      cardColor = _isDarkMode ? Colors.blue.withAlpha(25) : Colors.white;
      headerColor = _isDarkMode ? Colors.blueAccent : const Color(0xFF1D4ED8);
      borderColor = _isDarkMode ? Colors.blueAccent : const Color(0xFF93C5FD);
    } else if (day.esFestivo && day.festivoTrabajado) {
      cardColor = _isDarkMode ? Colors.purple.withAlpha(25) : Colors.white;
      headerColor = _isDarkMode ? Colors.purpleAccent : const Color(0xFF7E22CE);
      borderColor = _isDarkMode ? Colors.purpleAccent : const Color(0xFFCE93D8);
    } else if (startedOnWeekend) {
      cardColor = _isDarkMode ? Colors.white.withAlpha(20) : Colors.white;
      headerColor = _isDarkMode ? Colors.yellowAccent : const Color(0xFFC2410C);
      borderColor = _isDarkMode ? Colors.orange : const Color(0xFFCBD5E1);
    } else {
      cardColor = _isDarkMode ? Colors.white.withAlpha(20) : Colors.white;
      headerColor = _isDarkMode ? Colors.orange : const Color(0xFFC2410C);
      borderColor = _isDarkMode ? Colors.orange : const Color(0xFFCBD5E1);
    }

    return Column(
      children: [
        Card(
          color: cardColor,
          elevation: _isDarkMode ? 0 : 2,
          shadowColor: _isDarkMode ? Colors.transparent : Colors.black.withAlpha(20),
          margin: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
                color: _isDarkMode
                    ? borderColor.withAlpha(120)
                    : borderColor,
                width: (day.esMantenimiento || (day.esFestivo && day.festivoTrabajado)) ? 2 : (_isDarkMode ? 1 : 1.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dateHeader,
                            style: TextStyle(
                                color: headerColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                        if (day.esMantenimiento)
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: _isDarkMode
                                    ? Colors.blueAccent.withAlpha(60)
                                    : const Color(0xFFDBEAFE),
                                borderRadius: BorderRadius.circular(4)),
                            child: Text("DÍA DE MANTENIMIENTO",
                                style: TextStyle(
                                    color: _isDarkMode
                                        ? Colors.blueAccent
                                        : const Color(0xFF1D4ED8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                        if (day.esFestivo && day.festivoTrabajado)
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: _isDarkMode
                                    ? Colors.purpleAccent.withAlpha(60)
                                    : const Color(0xFFF3E8FF),
                                borderRadius: BorderRadius.circular(4)),
                            child: Text("DÍA FESTIVO TRABAJADO",
                                style: TextStyle(
                                    color: _isDarkMode
                                        ? Colors.purpleAccent
                                        : const Color(0xFF7E22CE),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                        if (day.isOvernight && !day.esMantenimiento)
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: _isDarkMode
                                    ? Colors.redAccent.withAlpha(60)
                                    : const Color(0xFFFFE4E6),
                                borderRadius: BorderRadius.circular(4)),
                            child: Text("SALIDA DÍA SIGUIENTE",
                                style: TextStyle(
                                    color: _isDarkMode
                                        ? Colors.redAccent
                                        : const Color(0xFFBE123C),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit,
                              color: _isDarkMode
                                  ? Colors.orange
                                  : const Color(0xFFD9531E),
                              size: 22),
                          tooltip: "Editar turno",
                          onPressed: existingIndex >= 0
                              ? () => _editExistingWorkDay(existingIndex)
                              : null,
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline,
                              color: _isDarkMode
                                  ? Colors.white54
                                  : const Color(0xFF6B7280),
                              size: 24),
                          tooltip: "Eliminar registro",
                          onPressed: _deleteTodayShift,
                        ),
                      ],
                    ),
                  ],
                ),
                Divider(
                    color: _isDarkMode
                        ? Colors.white24
                        : const Color(0xFFE5E7EB)),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Entrada Asignada: ${DateFormat('hh:mm a').format(day.entrada)}",
                            style: TextStyle(
                                color: day.esMantenimiento
                                    ? (_isDarkMode
                                        ? Colors.blueAccent
                                        : const Color(0xFF1D4ED8))
                                    : (_isDarkMode
                                        ? Colors.orangeAccent
                                        : const Color(0xFFD9531E)),
                                fontSize: 14,
                                fontWeight: FontWeight.w500),
                          ),
                          Text(
                            "Salida: ${DateFormat('hh:mm a').format(day.salida)}",
                            style: TextStyle(
                                color: _isDarkMode
                                    ? Colors.redAccent
                                    : const Color(0xFFC62828),
                                fontSize: 14,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      if (day.entradaReal != null &&
                          day.entradaReal != day.entrada)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            "Registro Real: ${DateFormat('hh:mm a').format(day.entradaReal!)} ${day.entradaReal!.isBefore(day.entrada) ? '(Temprano)' : '(Tarde)'}",
                            style: TextStyle(
                                color: day.entradaReal!.isBefore(day.entrada)
                                    ? (_isDarkMode
                                        ? Colors.greenAccent
                                        : const Color(0xFF2E7D32))
                                    : (_isDarkMode
                                        ? Colors.yellowAccent
                                        : const Color(0xFFB45309)),
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                    ],
                  ),
                ),
                if (day.esFestivo && day.festivoTrabajado)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _statDetail(
                          "DESGLOSE DE HORAS",
                          "${normalHrs.toStringAsFixed(1)}h (Base) + ${day.holidayExtraHours.toStringAsFixed(2)}h (Extra)",
                          "${day.totalHours.toStringAsFixed(2)} hrs totales"),
                      _statDetail(
                          "DESGLOSE DE PAGO",
                          "Pago Base: \$${day.sueldoBase.toStringAsFixed(2)} × 2 = \$${(day.sueldoBase * 2).toStringAsFixed(2)}\n"
                          "EXTRAS FESTIVO 3×: ${day.holidayExtraHours.toStringAsFixed(1)} hrs = \$${day.holidayExtrasPay.toStringAsFixed(2)}",
                          "\$${day.totalPay.toStringAsFixed(2)}",
                          isMoney: true),
                    ],
                  )
                else if (!day.esMantenimiento)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _statDetail(
                          "DESGLOSE DE HORAS",
                          "${normalHrs.toStringAsFixed(1)}h (Base) + ${day.extraHoursCount.toStringAsFixed(2)}h (Extra)",
                          "${day.totalHours.toStringAsFixed(2)} hrs totales"),
                      _statDetail(
                          "DESGLOSE DE PAGO",
                          "\$${day.dailyPay.toStringAsFixed(2)} Base\n"
                          "2× ${breakdown.hours2x.toStringAsFixed(2)}h  \$${breakdown.pay2x.toStringAsFixed(2)}\n"
                          "3× ${breakdown.hours3x.toStringAsFixed(2)}h  \$${breakdown.pay3x.toStringAsFixed(2)}",
                          "\$${(day.dailyPay + realExtrasPay).toStringAsFixed(2)}",
                          isMoney: true),
                    ],
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isDarkMode
                          ? Colors.blue.withAlpha(30)
                          : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: _isDarkMode
                              ? Colors.blueAccent.withAlpha(100)
                              : const Color(0xFFBFDBFE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            "MANTENIMIENTO - SIN HORAS EXTRA",
                            style: TextStyle(
                                color: _isDarkMode
                                    ? Colors.blueAccent
                                    : const Color(0xFF1D4ED8),
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                            "Jornada: ${day.totalHours.toStringAsFixed(2)} hrs | Pago base: \$${day.dailyPay.toStringAsFixed(2)}",
                            style: TextStyle(
                                color: _isDarkMode
                                    ? Colors.white70
                                    : const Color(0xFF4B5563),
                                fontSize: 13)),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Divider(
                    color: _isDarkMode
                        ? Colors.white24
                        : const Color(0xFFE5E7EB)),
                _buildNotesSection(day),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _isDarkMode
                        ? Colors.redAccent
                        : const Color(0xFFC62828),
                    side: BorderSide(
                        color: _isDarkMode
                            ? Colors.redAccent
                            : const Color(0xFFC62828),
                        width: 1.5),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _deleteTodayShift,
                  icon: Icon(Icons.delete_outline,
                      size: 18,
                      color: _isDarkMode
                          ? Colors.redAccent
                          : const Color(0xFFC62828)),
                  label: Text(
                    "ELIMINAR REGISTRO DE HOY",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.5,
                      color: _isDarkMode
                          ? Colors.redAccent
                          : const Color(0xFFC62828),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildShiftRatingSelector(day),
      ],
    );
  }

  Widget _buildHoyTab() {
    final now = DateTime.now();
    final WorkDay? todayRecord = _weeklyHistory.cast<WorkDay?>().firstWhere(
          (d) =>
              d != null &&
              d.entrada.year == now.year &&
              d.entrada.month == now.month &&
              d.entrada.day == now.day &&
              !d.isInProgress,
          orElse: () => null,
        );

    if (todayRecord != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 30),
            Text(_dateString,
                style: TextStyle(
                    color:
                        _isDarkMode ? Colors.white70 : Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w600)),
            Text(_timeString,
                style: TextStyle(
                    color:
                        _isDarkMode ? Colors.orange : const Color(0xFFC2410C),
                    fontSize: 32,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildTodaySummaryCard(todayRecord),
            const SizedBox(height: 30),
          ],
        ),
      );
    }
    bool hasTodayFalta = _weeklyHistory.any((d) =>
        d.entrada.year == now.year &&
        d.entrada.month == now.month &&
        d.entrada.day == now.day &&
        d.esFalta);
    bool hasTodayVacaciones = _weeklyHistory.any((d) =>
        d.entrada.year == now.year &&
        d.entrada.month == now.month &&
        d.entrada.day == now.day &&
        d.esVacaciones);
    bool hasTodayFestivo = _weeklyHistory.any((d) =>
        d.entrada.year == now.year &&
        d.entrada.month == now.month &&
        d.entrada.day == now.day &&
        d.esFestivo &&
        !d.festivoTrabajado);

    WorkDay? currentShift = _weeklyHistory.cast<WorkDay?>().firstWhere(
          (d) =>
              d?.id == _currentShiftId ||
              (d != null && d.isInProgress) ||
              (_entradaDateTime != null &&
                  d != null &&
                  d.entrada == _entradaDateTime),
          orElse: () => null,
        );

    DateTime? effectiveEntrada = _entradaDateTime ?? currentShift?.entrada;
    DateTime? effectiveEntradaReal =
        _entradaRealDateTime ?? currentShift?.entradaReal;

    bool hasRegisteredEntrada =
        _isClockedIn || _completedToday || _entradaDateTime != null;
    bool hasRegisteredSalida = _completedToday && _salidaDateTime != null;

    String entradaTimeString = _entradaDateTime != null
        ? DateFormat('hh:mm a').format(_entradaDateTime!)
        : (_entradaDisplay.contains(" - ")
            ? _entradaDisplay.split(" - ").last
            : (_entradaDisplay != "--/-- --:--" ? _entradaDisplay : "--:--"));
    String salidaTimeString = _salidaDateTime != null
        ? DateFormat('hh:mm a').format(_salidaDateTime!)
        : (_salidaDisplay.contains(" - ")
            ? _salidaDisplay.split(" - ").last
            : (_salidaDisplay != "--/-- --:--" ? _salidaDisplay : "--:--"));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 30),
          Text(_dateString,
              style: TextStyle(
                  color:
                      _isDarkMode ? Colors.white70 : Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w600)),
          Text(_timeString,
              style: TextStyle(
                  color:
                      _isDarkMode ? Colors.orange : const Color(0xFFC2410C),
                  fontSize: 32,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          // Consolidated side-by-side ENTRADA and SALIDA container
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.white.withAlpha(20) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _isDarkMode ? Colors.white12 : const Color(0xFFCBD5E1),
                width: _isDarkMode ? 1.0 : 1.5,
              ),
              boxShadow: _isDarkMode
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withAlpha(12),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- ENTRADA BOX ---
                  Expanded(
                    child: hasRegisteredEntrada
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 16),
                            decoration: BoxDecoration(
                              color: _isDarkMode
                                  ? Colors.green.withAlpha(25)
                                  : const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: _isDarkMode
                                      ? Colors.greenAccent.withAlpha(80)
                                      : const Color(0xFFA5D6A7)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.login,
                                            color: _isDarkMode
                                                ? Colors.greenAccent
                                                : const Color(0xFF2E7D32),
                                            size: 19),
                                        const SizedBox(width: 6),
                                        Text(
                                          "ENTRADA",
                                          style: TextStyle(
                                            color: _isDarkMode
                                                ? Colors.greenAccent
                                                : const Color(0xFF2E7D32),
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: Icon(Icons.edit,
                                          color: _isDarkMode
                                              ? Colors.greenAccent
                                              : const Color(0xFF2E7D32),
                                          size: 19),
                                      tooltip: "Editar hora entrada",
                                      onPressed: _isProcessing
                                          ? null
                                          : _editEntradaTime,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    entradaTimeString,
                                    style: TextStyle(
                                      color: _isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (effectiveEntradaReal != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    (effectiveEntrada != null &&
                                            effectiveEntradaReal
                                                .isAfter(effectiveEntrada))
                                        ? "Llegada: ${DateFormat('hh:mm a').format(effectiveEntradaReal)} (Tarde)"
                                        : "Llegada: ${DateFormat('hh:mm a').format(effectiveEntradaReal)}",
                                    style: TextStyle(
                                      color: (effectiveEntrada != null &&
                                              effectiveEntradaReal
                                                  .isAfter(effectiveEntrada))
                                          ? (_isDarkMode
                                              ? Colors.orangeAccent
                                              : const Color(0xFFB43403))
                                          : (_isDarkMode
                                              ? Colors.white54
                                              : Colors.black87),
                                      fontSize: 13,
                                      fontWeight: (effectiveEntrada != null &&
                                              effectiveEntradaReal
                                                  .isAfter(effectiveEntrada))
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ] else if (_entradaDateTime != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    DateFormat('dd/MM')
                                        .format(_entradaDateTime!),
                                    style: TextStyle(
                                      color: _isDarkMode
                                          ? Colors.white38
                                          : Colors.black87,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isDarkMode
                                      ? Colors.green.shade700
                                      : const Color(0xFF2E7D32),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 58),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14, horizontal: 8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  elevation: 2,
                                ),
                                onPressed: (_isProcessing ||
                                        hasTodayFalta ||
                                        hasTodayVacaciones ||
                                        hasTodayFestivo)
                                    ? null
                                    : () => _processRecord(
                                        "ENTRADA", DateTime.now()),
                                icon: const Icon(Icons.login, size: 22),
                                label: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "ENTRADA AHORA",
                                    style: TextStyle(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _isDarkMode
                                      ? Colors.greenAccent
                                      : const Color(0xFF2E7D32),
                                  minimumSize: const Size(double.infinity, 58),
                                  side: BorderSide(
                                    color: (_isProcessing ||
                                            hasTodayFalta ||
                                            hasTodayVacaciones ||
                                            hasTodayFestivo)
                                        ? (_isDarkMode
                                            ? Colors.white12
                                            : const Color(0xFFE5E7EB))
                                        : (_isDarkMode
                                            ? Colors.greenAccent.withAlpha(140)
                                            : const Color(0xFF2E7D32)),
                                    width: 1.2,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14, horizontal: 8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: (_isProcessing ||
                                        hasTodayFalta ||
                                        hasTodayVacaciones ||
                                        hasTodayFestivo)
                                    ? null
                                    : () async {
                                        DateTime now = DateTime.now();
                                        final TimeOfDay? picked =
                                            await _showScrollTimePicker(
                                          context,
                                          initialTime: TimeOfDay.now(),
                                          title: "¿A QUÉ HORA ENTRASTE HOY?",
                                        );
                                        if (picked != null && mounted) {
                                          DateTime manualTime = DateTime(
                                            now.year,
                                            now.month,
                                            now.day,
                                            picked.hour,
                                            picked.minute,
                                          );
                                          await _executeEntrada(manualTime,
                                              actualTime: manualTime);
                                        }
                                      },
                                icon: Icon(Icons.edit,
                                    size: 22,
                                    color: _isDarkMode
                                        ? Colors.greenAccent
                                        : const Color(0xFF2E7D32)),
                                label: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "ENTRADA MANUAL",
                                    style: TextStyle(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(width: 14),

                  // --- SALIDA BOX ---
                  Expanded(
                    child: hasRegisteredSalida
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 16),
                            decoration: BoxDecoration(
                              color: _isDarkMode
                                  ? Colors.red.withAlpha(25)
                                  : const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: _isDarkMode
                                      ? Colors.redAccent.withAlpha(80)
                                      : const Color(0xFFEF9A9A)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.logout,
                                            color: _isDarkMode
                                                ? Colors.redAccent
                                                : const Color(0xFFC62828),
                                            size: 19),
                                        const SizedBox(width: 6),
                                        Text(
                                          "SALIDA",
                                          style: TextStyle(
                                            color: _isDarkMode
                                                ? Colors.redAccent
                                                : const Color(0xFFC62828),
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: Icon(Icons.edit,
                                          color: _isDarkMode
                                              ? Colors.redAccent
                                              : const Color(0xFFC62828),
                                          size: 19),
                                      tooltip: "Editar hora salida",
                                      onPressed: _isProcessing
                                          ? null
                                          : _editSalidaTime,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    salidaTimeString,
                                    style: TextStyle(
                                      color: _isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (_salidaDateTime != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    DateFormat('dd/MM')
                                        .format(_salidaDateTime!),
                                    style: TextStyle(
                                      color: _isDarkMode
                                          ? Colors.white38
                                          : Colors.black87,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : (_isClockedIn && !_completedToday)
                            ? Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isDarkMode
                                          ? Colors.redAccent.shade700
                                          : const Color(0xFFC62828),
                                      foregroundColor: Colors.white,
                                      minimumSize:
                                          const Size(double.infinity, 58),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14, horizontal: 8),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      elevation: 2,
                                    ),
                                    onPressed: _isProcessing
                                        ? null
                                        : () =>
                                            _executeSalida(DateTime.now()),
                                    icon: const Icon(Icons.logout, size: 22),
                                    label: const FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        "SALIDA AHORA",
                                        style: TextStyle(
                                          fontSize: 16.5,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _isDarkMode
                                          ? Colors.redAccent
                                          : const Color(0xFFB91C1C),
                                      minimumSize:
                                          const Size(double.infinity, 58),
                                      side: BorderSide(
                                        color: _isProcessing
                                            ? (_isDarkMode
                                                ? Colors.white12
                                                : const Color(0xFFE5E7EB))
                                            : (_isDarkMode
                                                ? Colors.redAccent
                                                    .withAlpha(140)
                                                : const Color(0xFFB91C1C)),
                                        width: _isDarkMode ? 1.2 : 1.8,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14, horizontal: 8),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                    onPressed: _isProcessing
                                        ? null
                                        : () async {
                                            DateTime now = DateTime.now();
                                            final TimeOfDay? picked =
                                                await _showScrollTimePicker(
                                              context,
                                              initialTime: TimeOfDay.now(),
                                              title:
                                                  "¿A QUÉ HORA SALISTE HOY?",
                                            );
                                            if (picked != null && mounted) {
                                              DateTime manualTime = DateTime(
                                                now.year,
                                                now.month,
                                                now.day,
                                                picked.hour,
                                                picked.minute,
                                              );
                                              await _executeSalida(manualTime);
                                            }
                                          },
                                    icon: Icon(Icons.edit,
                                        size: 22,
                                        color: _isDarkMode
                                            ? Colors.redAccent
                                            : const Color(0xFFB91C1C)),
                                    label: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        "SALIDA MANUAL",
                                        style: TextStyle(
                                          fontSize: 16.5,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                          color: _isDarkMode
                                              ? Colors.redAccent
                                              : const Color(0xFFB91C1C),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 16),
                                decoration: BoxDecoration(
                                  color: _isDarkMode
                                      ? Colors.white.withAlpha(8)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: _isDarkMode
                                          ? Colors.white10
                                          : const Color(0xFFCBD5E1),
                                      width: _isDarkMode ? 1.0 : 1.2),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.logout,
                                            color: _isDarkMode
                                                ? Colors.white24
                                                : const Color(0xFF64748B),
                                            size: 19),
                                        const SizedBox(width: 6),
                                        Text(
                                          "SALIDA",
                                          style: TextStyle(
                                            color: _isDarkMode
                                                ? Colors.white38
                                                : const Color(0xFF475569),
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        "--:--",
                                        style: TextStyle(
                                          color: _isDarkMode
                                              ? Colors.white24
                                              : const Color(0xFF64748B),
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "Pendiente",
                                      style: TextStyle(
                                        color: _isDarkMode
                                            ? Colors.white24
                                            : const Color(0xFF64748B),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                  ),
                ],
              ),
            ),
          ),
          // Midnight & Recovery prompt if shift's entrada was from previous day
          if (_isShiftFromPreviousDay()) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _isDarkMode
                    ? Colors.amber.withAlpha(25)
                    : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _isDarkMode
                        ? Colors.amberAccent.withAlpha(120)
                        : const Color(0xFFFDE68A),
                    width: 1.5),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.nightlight_round,
                          color: _isDarkMode
                              ? Colors.amberAccent
                              : const Color(0xFFD97706),
                          size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Turno iniciado el ${DateFormat('dd/MM').format(_entradaDateTime!)}. Si olvidaste checar salida ayer:",
                          style: TextStyle(
                            color: _isDarkMode
                                ? Colors.white70
                                : Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isDarkMode
                          ? Colors.amber.shade800
                          : const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _showForgottenClockOutDialog,
                    icon: const Icon(Icons.restart_alt, size: 20),
                    label: const Text(
                      "REGISTRAR DÍA NUEVO",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 3-way shift rating selector (active when clocked in or completed today)
          if ((_isClockedIn || _completedToday) && currentShift != null) ...[
            const SizedBox(height: 16),
            _buildShiftRatingSelector(currentShift),
          ],

          // Time remaining or overtime message
          if (_timeRemainingMessage.isNotEmpty) ...[
            Builder(builder: (context) {
              Color boxBg;
              Color boxBorder;
              Color boxAccent;
              Color textC;

              if (_timeRemainingMessage.contains("acompleta otra media hora")) {
                boxBg = _isDarkMode
                    ? Colors.yellow.withAlpha(40)
                    : const Color(0xFFFEF9C3);
                boxBorder = _isDarkMode
                    ? Colors.yellowAccent.withAlpha(100)
                    : const Color(0xFFFDE047);
                boxAccent = _isDarkMode
                    ? Colors.yellowAccent
                    : const Color(0xFFCA8A04);
                textC = _isDarkMode
                    ? Colors.yellowAccent
                    : const Color(0xFF854D0E);
              } else if (_timeRemainingMessage.contains("tiempo extra")) {
                boxBg = _isDarkMode
                    ? Colors.orange.withAlpha(40)
                    : const Color(0xFFFFEDD5);
                boxBorder = _isDarkMode
                    ? Colors.orangeAccent.withAlpha(100)
                    : const Color(0xFFFDBA74);
                boxAccent = _isDarkMode
                    ? Colors.orangeAccent
                    : const Color(0xFFEA580C);
                textC = _isDarkMode
                    ? Colors.orangeAccent
                    : const Color(0xFF9A3412);
              } else {
                boxBg = _isDarkMode
                    ? Colors.blue.withAlpha(40)
                    : const Color(0xFFEFF6FF);
                boxBorder = _isDarkMode
                    ? Colors.blueAccent.withAlpha(100)
                    : const Color(0xFF93C5FD);
                boxAccent = _isDarkMode
                    ? Colors.blueAccent
                    : const Color(0xFF1E3A8A);
                textC = _isDarkMode
                    ? Colors.blueAccent
                    : const Color(0xFF1E3A8A);
              }

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: boxBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: boxBorder,
                    width: _isDarkMode ? 1.0 : 1.4,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _timeRemainingMessage
                              .contains("acompleta otra media hora")
                          ? Icons.access_time_filled
                          : (_timeRemainingMessage.contains("tiempo extra")
                              ? Icons.timer_outlined
                              : Icons.access_time),
                      color: boxAccent,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _timeRemainingMessage,
                        style: TextStyle(
                          color: textC,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          // Notes section for the active shift
          if ((_isClockedIn || _completedToday) && currentShift != null) ...[
            const SizedBox(height: 16),
            _buildNotesSection(currentShift),
          ],

          // Discard in-progress shift button (positioned at bottom of active shift)
          if (_isClockedIn) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isDarkMode
                    ? Colors.red.withAlpha(25)
                    : const Color(0xFFFEE2E2),
                foregroundColor: _isDarkMode
                    ? Colors.redAccent
                    : const Color(0xFF991B1B),
                elevation: _isDarkMode ? 0 : 1,
                side: BorderSide(
                  color: _isDarkMode
                      ? Colors.redAccent.withAlpha(140)
                      : const Color(0xFFDC2626),
                  width: _isDarkMode ? 1.4 : 1.6,
                ),
                minimumSize: const Size(double.infinity, 48),
                padding:
                    const EdgeInsets.symmetric(vertical: 13, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isProcessing ? null : _deleteTodayShift,
              icon: Icon(
                Icons.delete_outline,
                size: 21,
                color: _isDarkMode
                    ? Colors.redAccent
                    : const Color(0xFF991B1B),
              ),
              label: Text(
                "DESCARTAR TURNO EN PROGRESO",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                  letterSpacing: 0.8,
                  color: _isDarkMode
                      ? Colors.redAccent
                      : const Color(0xFF991B1B),
                ),
              ),
            ),
          ],
          // Bottom quick actions (only when not clocked in and not completed today)
          if (!_isClockedIn && !_completedToday) ...[
            const SizedBox(height: 24),
            Divider(
                color: _isDarkMode
                    ? Colors.white12
                    : const Color(0xFFD1D5DB)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildButton(
                      hasTodayVacaciones
                          ? "VACACIONES REGISTRADAS"
                          : "VACACIONES",
                      hasTodayVacaciones
                          ? Colors.grey
                          : Colors.lightGreen.shade700,
                      (hasTodayFalta ||
                              hasTodayVacaciones ||
                              hasTodayFestivo)
                          ? null
                          : () {
                              DateTime now = DateTime.now();
                              DateTime noon =
                                  DateTime(now.year, now.month, now.day, 12, 0);
                              final double salaryForDate =
                                  _getSalaryForDate(noon);

                              _addAndSortHistory(WorkDay(
                                  entrada: noon,
                                  salida: noon,
                                  sueldoBase: salaryForDate,
                                  baseHours: double.tryParse(
                                          _baseHoursController.text) ??
                                      9.5,
                                  esVacaciones: true));
                            },
                      isCompact: true),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildButton(
                      hasTodayFalta
                          ? "FALTA REGISTRADA"
                          : "NO LABORÉ HOY",
                      hasTodayFalta ? Colors.grey : Colors.red.shade900,
                      (hasTodayFalta ||
                              hasTodayVacaciones ||
                              hasTodayFestivo)
                          ? null
                          : () {
                              DateTime now = DateTime.now();
                              DateTime noon =
                                  DateTime(now.year, now.month, now.day, 12, 0);
                              final double salaryForDate =
                                  _getSalaryForDate(noon);

                              _addAndSortHistory(WorkDay(
                                  entrada: noon,
                                  salida: noon,
                                  sueldoBase: salaryForDate,
                                  baseHours: double.tryParse(
                                          _baseHoursController.text) ??
                                      9.5,
                                  esFalta: true));
                            },
                      isCompact: true),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildButton(
                hasTodayFestivo
                    ? "DÍA FESTIVO REGISTRADO"
                    : "DÍA FESTIVO (NO LABORADO)",
                hasTodayFestivo ? Colors.grey : Colors.purple.shade700,
                (hasTodayFalta ||
                        hasTodayVacaciones ||
                        hasTodayFestivo)
                    ? null
                    : () {
                        DateTime now = DateTime.now();
                        DateTime noon =
                            DateTime(now.year, now.month, now.day, 12, 0);
                        final double salaryForDate =
                            _getSalaryForDate(noon);

                        _addAndSortHistory(WorkDay(
                            entrada: noon,
                            salida: noon,
                            sueldoBase: salaryForDate,
                            baseHours: double.tryParse(
                                    _baseHoursController.text) ??
                                9.5,
                            esFestivo: true,
                            festivoTrabajado: false));
                      },
                isCompact: true),
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildQuincenaTab() {
    DateTime now = DateTime.now();
    DateTime mondayThisWeek = now.subtract(Duration(days: now.weekday - 1));
    DateTime mondayLastWeek = mondayThisWeek.subtract(const Duration(days: 7));
    DateTime sundayThisWeek = mondayThisWeek.add(const Duration(days: 6));
    DateTime startOfRange =
        DateTime(mondayLastWeek.year, mondayLastWeek.month, mondayLastWeek.day);
    DateTime endOfRange = DateTime(sundayThisWeek.year, sundayThisWeek.month,
        sundayThisWeek.day, 23, 59, 59);
    List<WorkDay> filteredHistory = _weeklyHistory.where((day) {
      return day.entrada
              .isAfter(startOfRange.subtract(const Duration(seconds: 1))) &&
          day.entrada.isBefore(endOfRange.add(const Duration(seconds: 1)));
    }).toList();
    // 1. Group days by Week Number
    final Map<int, List<WorkDay>> weeks = {};
    for (final d in filteredHistory) {
      final int week = _getWeekNumber(d.entrada);
      weeks.putIfAbsent(week, () => []);
      weeks[week]!.add(d);
    }

    // 2. Identify Week Numbers for "Last" and "Current"
    int weekNumLast = _getWeekNumber(mondayLastWeek);
    int weekNumCurrent = _getWeekNumber(mondayThisWeek);

    // 3. Calculate Totals and Hours Separately
    double totalLastWeek = 0.0;
    double hoursLastWeek = 0.0;
    if (weeks.containsKey(weekNumLast)) {
      final map = calculateWeeklyOvertimeBreakdown(weeks[weekNumLast]!);
      totalLastWeek = map.values.fold(0.0, (acc, b) => acc + b.totalPay);
      hoursLastWeek =
          map.values.fold(0.0, (acc, b) => acc + (b.hours2x + b.hours3x));
    }

    double totalThisWeek = 0.0;
    double hoursThisWeek = 0.0;
    if (weeks.containsKey(weekNumCurrent)) {
      final map = calculateWeeklyOvertimeBreakdown(weeks[weekNumCurrent]!);
      totalThisWeek = map.values.fold(0.0, (acc, b) => acc + b.totalPay);
      hoursThisWeek =
          map.values.fold(0.0, (acc, b) => acc + (b.hours2x + b.hours3x));
    }

    // Individual week sharing is now used instead of combined sharing
    // Manual Spanish lists for the list items
    final List<String> daysES = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo'
    ];
    final List<String> monthsES = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    return Column(children: [
      Container(
          padding: const EdgeInsets.all(12),
          width: double.infinity,
          decoration: BoxDecoration(
            color: _isDarkMode
                ? Colors.orange.withAlpha(25)
                : const Color(0xFFFFF7ED),
            border: _isDarkMode
                ? null
                : const Border(
                    bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- LAST WEEK ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text("SEM. PASADA",
                                style: TextStyle(
                                    color: _isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                    fontSize: 16,
                                    letterSpacing: 1.0,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                        IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(Icons.share,
                                color: _isDarkMode
                                    ? Colors.white70
                                    : const Color(0xFF475569),
                                size: 16),
                            onPressed: () => _shareSingleWeekSummary(
                                weeks[weekNumLast] ?? [],
                                weekNumLast,
                                "SEMANA PASADA")),
                      ],
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "\$${totalLastWeek.toStringAsFixed(2)} - (${hoursLastWeek.toStringAsFixed(1)} hrs)",
                        style: TextStyle(
                          color: _isDarkMode
                              ? Colors.white
                              : Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // --- THIS WEEK ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text("SEM. ACTUAL",
                                style: TextStyle(
                                    color: _isDarkMode
                                        ? Colors.orange
                                        : const Color(0xFFC2410C),
                                    fontSize: 16,
                                    letterSpacing: 1.0,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                        IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(Icons.share,
                                color: _isDarkMode
                                    ? Colors.orange
                                    : const Color(0xFFC2410C),
                                size: 18),
                            onPressed: () => _shareSingleWeekSummary(
                                weeks[weekNumCurrent] ?? [],
                                weekNumCurrent,
                                "SEMANA ACTUAL")),
                      ],
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "\$${totalThisWeek.toStringAsFixed(2)} - (${hoursThisWeek.toStringAsFixed(1)} hrs)",
                        style: TextStyle(
                          color: _isDarkMode
                              ? Colors.orange
                              : const Color(0xFFC2410C),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        color: _isDarkMode ? Colors.black26 : const Color(0xFFF1F5F9),
        child: Column(children: [
          _buildWeekRow(mondayLastWeek, "SEM PASADA", false),
          const SizedBox(height: 8),
          _buildWeekRow(mondayThisWeek, "SEM ACTUAL", true),
        ]),
      ),
      Expanded(
        child: filteredHistory.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                    child: Text("No hay registros en estas dos semanas",
                        style: TextStyle(
                            color: _isDarkMode
                                ? Colors.white24
                                : const Color(0xFF64748B)))))
            : ListView.builder(
                itemCount: filteredHistory.length,
                itemBuilder: (context, index) {
                  final day = filteredHistory[index];
                  bool isSelected =
                      day.entrada.day == _selectedCalendarDay.day &&
                          day.entrada.month == _selectedCalendarDay.month;

                  final int week = _getWeekNumber(day.entrada);
                  final List<WorkDay> weekDays = filteredHistory
                      .where((d) => _getWeekNumber(d.entrada) == week)
                      .toList();
                  final weeklyOTMap =
                      calculateWeeklyOvertimeBreakdown(weekDays);
                  final breakdown = weeklyOTMap[day] ?? OvertimeBreakdown();
                  final double realExtrasPay = breakdown.totalPay;

                  // Construct Spanish date string
                  String dateStringES =
                      "${daysES[day.entrada.weekday - 1]}, ${day.entrada.day} ${monthsES[day.entrada.month - 1]}";

                  if (day.isInProgress) {
                    return Card(
                      color: _isDarkMode
                          ? Colors.orange.withAlpha(35)
                          : const Color(0xFFFFF7ED),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                            color: _isDarkMode
                                ? Colors.orangeAccent.withAlpha(120)
                                : const Color(0xFFF97316),
                            width: 1.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dateStringES,
                                    style: TextStyle(
                                        color: _isDarkMode
                                            ? Colors.white70
                                            : const Color(0xFF1E293B),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.timelapse,
                                          color: _isDarkMode
                                              ? Colors.orangeAccent
                                              : const Color(0xFFC2410C),
                                          size: 16),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          "TURNO EN PROGRESO (Entrada: ${DateFormat('hh:mm a').format(day.entrada)})",
                                          style: TextStyle(
                                              color: _isDarkMode
                                                  ? Colors.orangeAccent
                                                  : const Color(0xFFC2410C),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit,
                                      color: _isDarkMode
                                          ? Colors.orange
                                          : const Color(0xFFC2410C),
                                      size: 20),
                                  tooltip: "Editar turno",
                                  onPressed: () => _editExistingWorkDay(
                                      _weeklyHistory.indexOf(day)),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline,
                                      color: _isDarkMode
                                          ? Colors.white54
                                          : const Color(0xFF64748B),
                                      size: 24),
                                  tooltip: "Descartar turno en progreso",
                                  onPressed: () => _showDeleteDialog(
                                      _weeklyHistory.indexOf(day)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (day.esFalta) {
                    return Card(
                      color: _isDarkMode
                          ? Colors.red.withAlpha(40)
                          : const Color(0xFFFEF2F2),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: _isDarkMode
                              ? Colors.transparent
                              : const Color(0xFFFCA5A5),
                          width: _isDarkMode ? 0 : 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(dateStringES,
                                          style: TextStyle(
                                              color: _isDarkMode
                                                  ? Colors.redAccent
                                                  : const Color(0xFF991B1B),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18)),
                                      const SizedBox(height: 6),
                                      Text("FALTA / NO LABORADO",
                                          style: TextStyle(
                                              color: _isDarkMode
                                                  ? Colors.white
                                                  : const Color(0xFF1E293B),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14)),
                                    ]),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit,
                                          color: _isDarkMode
                                              ? Colors.orange
                                              : const Color(0xFFC2410C),
                                          size: 20),
                                      tooltip: "Editar registro",
                                      onPressed: () => _editExistingWorkDay(
                                          _weeklyHistory.indexOf(day)),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline,
                                          color: _isDarkMode
                                              ? Colors.white54
                                              : const Color(0xFF64748B),
                                          size: 24),
                                      onPressed: () => _showDeleteDialog(
                                          _weeklyHistory.indexOf(day)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Divider(
                                color: _isDarkMode
                                    ? Colors.white24
                                    : const Color(0xFFE2E8F0)),
                            _buildNotesSection(day),
                          ],
                        ),
                      ),
                    );
                  }

                  if (day.esVacaciones) {
                    return Card(
                      color: _isDarkMode
                          ? Colors.lightGreen.withAlpha(30)
                          : const Color(0xFFF0FDF4),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                            color: _isDarkMode
                                ? Colors.lightGreenAccent.withAlpha(100)
                                : const Color(0xFF86EFAC),
                            width: _isDarkMode ? 2 : 1.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(dateStringES,
                                        style: TextStyle(
                                            color: _isDarkMode
                                                ? Colors.lightGreenAccent
                                                : const Color(0xFF166534),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18)),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                          color: _isDarkMode
                                              ? Colors.lightGreen.withAlpha(60)
                                              : const Color(0xFFDCFCE7),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: _isDarkMode
                                              ? null
                                              : Border.all(
                                                  color: const Color(0xFF86EFAC))),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.star,
                                              color: _isDarkMode
                                                  ? Colors.lightGreenAccent
                                                  : const Color(0xFF15803D),
                                              size: 14),
                                          const SizedBox(width: 4),
                                          Text("VACACIONES",
                                              style: TextStyle(
                                                  color: _isDarkMode
                                                      ? Colors.lightGreenAccent
                                                      : const Color(0xFF15803D),
                                                  fontSize: 11,
                                                  fontWeight:
                                                      FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit,
                                          color: _isDarkMode
                                              ? Colors.orange
                                              : const Color(0xFFC2410C),
                                          size: 20),
                                      tooltip: "Editar registro",
                                      onPressed: () => _editExistingWorkDay(
                                          _weeklyHistory.indexOf(day)),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline,
                                          color: _isDarkMode
                                              ? Colors.white54
                                              : const Color(0xFF64748B),
                                          size: 24),
                                      onPressed: () => _showDeleteDialog(
                                          _weeklyHistory.indexOf(day)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _isDarkMode
                                    ? Colors.lightGreen.withAlpha(20)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: _isDarkMode
                                        ? Colors.lightGreenAccent.withAlpha(100)
                                        : const Color(0xFF86EFAC)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      "VACACIONES - PAGO BASE COMPLETO",
                                      style: TextStyle(
                                          color: _isDarkMode
                                              ? Colors.lightGreenAccent
                                              : const Color(0xFF15803D),
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(
                                      "Pago base: \$${day.dailyPay.toStringAsFixed(2)} | Sin descuento ni horas extra",
                                      style: TextStyle(
                                          color: _isDarkMode
                                              ? Colors.white70
                                              : const Color(0xFF334155),
                                          fontSize: 13)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Divider(
                                color: _isDarkMode
                                    ? Colors.white24
                                    : const Color(0xFFE2E8F0)),
                            _buildNotesSection(day),
                          ],
                        ),
                      ),
                    );
                  } else if (day.esFestivo && !day.festivoTrabajado) {
                    return Card(
                      color: _isDarkMode
                          ? Colors.purple.withAlpha(30)
                          : const Color(0xFFFAF5FF),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                            color: _isDarkMode
                                ? Colors.purpleAccent.withAlpha(100)
                                : const Color(0xFFD8B4FE),
                            width: _isDarkMode ? 2 : 1.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(dateStringES,
                                        style: TextStyle(
                                            color: _isDarkMode
                                                ? Colors.purpleAccent
                                                : const Color(0xFF6B21A8),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18)),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                          color: _isDarkMode
                                              ? Colors.purple.withAlpha(60)
                                              : const Color(0xFFF3E8FF),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: _isDarkMode
                                              ? null
                                              : Border.all(
                                                  color: const Color(0xFFD8B4FE))),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.star,
                                              color: _isDarkMode
                                                  ? Colors.purpleAccent
                                                  : const Color(0xFF7E22CE),
                                              size: 14),
                                          const SizedBox(width: 4),
                                          Text("DÍA FESTIVO",
                                              style: TextStyle(
                                                  color: _isDarkMode
                                                      ? Colors.purpleAccent
                                                      : const Color(0xFF7E22CE),
                                                  fontSize: 11,
                                                  fontWeight:
                                                      FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit,
                                          color: _isDarkMode
                                              ? Colors.orange
                                              : const Color(0xFFC2410C),
                                          size: 20),
                                      tooltip: "Editar registro",
                                      onPressed: () => _editExistingWorkDay(
                                          _weeklyHistory.indexOf(day)),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline,
                                          color: _isDarkMode
                                              ? Colors.white54
                                              : const Color(0xFF64748B),
                                          size: 24),
                                      onPressed: () => _showDeleteDialog(
                                          _weeklyHistory.indexOf(day)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _isDarkMode
                                    ? Colors.purple.withAlpha(20)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: _isDarkMode
                                        ? Colors.purpleAccent.withAlpha(100)
                                        : const Color(0xFFD8B4FE)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      "DÍA FESTIVO - PAGO BASE COMPLETO",
                                      style: TextStyle(
                                          color: _isDarkMode
                                              ? Colors.purpleAccent
                                              : const Color(0xFF7E22CE),
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(
                                      "Pago base: \$${day.dailyPay.toStringAsFixed(2)} | Sin descuento ni horas extra",
                                      style: TextStyle(
                                          color: _isDarkMode
                                              ? Colors.white70
                                              : const Color(0xFF334155),
                                          fontSize: 13)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Divider(
                                color: _isDarkMode
                                    ? Colors.white24
                                    : const Color(0xFFE2E8F0)),
                            _buildNotesSection(day),
                          ],
                        ),
                      ),
                    );
                  }

                  bool startedOnWeekend =
                      day.entrada.weekday == DateTime.saturday ||
                          day.entrada.weekday == DateTime.sunday;
                  double normalHrs = day.totalHours > day.baseHours
                      ? day.baseHours
                      : day.totalHours;

                  // Determine colors based on day type
                  Color cardColor;
                  Color headerColor;
                  Color borderColor;
                  if (_isDarkMode) {
                    if (day.esMantenimiento) {
                      cardColor = isSelected
                          ? Colors.blue.withAlpha(50)
                          : Colors.blue.withAlpha(20);
                      headerColor = Colors.blueAccent;
                      borderColor = Colors.blueAccent;
                    } else if (day.esFestivo && day.festivoTrabajado) {
                      cardColor = isSelected
                          ? Colors.purple.withAlpha(50)
                          : Colors.purple.withAlpha(20);
                      headerColor = Colors.purpleAccent;
                      borderColor = Colors.purpleAccent;
                    } else if (startedOnWeekend) {
                      cardColor = isSelected
                          ? Colors.orange.withAlpha(50)
                          : Colors.white.withAlpha(20);
                      headerColor = Colors.yellowAccent;
                      borderColor = Colors.orange;
                    } else {
                      cardColor = isSelected
                          ? Colors.orange.withAlpha(50)
                          : Colors.white.withAlpha(20);
                      headerColor = Colors.orange;
                      borderColor = Colors.orange;
                    }
                  } else {
                    // Light Mode
                    if (day.esMantenimiento) {
                      cardColor = isSelected
                          ? const Color(0xFFEFF6FF)
                          : Colors.white;
                      headerColor = const Color(0xFF1D4ED8);
                      borderColor = isSelected
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF93C5FD);
                    } else if (day.esFestivo && day.festivoTrabajado) {
                      cardColor = isSelected
                          ? const Color(0xFFFAF5FF)
                          : Colors.white;
                      headerColor = const Color(0xFF6B21A8);
                      borderColor = isSelected
                          ? const Color(0xFF9333EA)
                          : const Color(0xFFD8B4FE);
                    } else {
                      cardColor = isSelected
                          ? const Color(0xFFFFF7ED)
                          : Colors.white;
                      headerColor = Colors.black;
                      borderColor = isSelected
                          ? const Color(0xFFEA580C)
                          : const Color(0xFFCBD5E1);
                    }
                  }

                  return Card(
                      color: cardColor,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                            color: _isDarkMode
                                ? borderColor.withAlpha(100)
                                : borderColor,
                            width: _isDarkMode
                                ? ((day.esMantenimiento || (day.esFestivo && day.festivoTrabajado)) ? 2 : 0)
                                : (isSelected ? 2.0 : 1.5)),
                      ),
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(children: [
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(dateStringES,
                                            style: TextStyle(
                                                color: headerColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18)),
                                        if (day.esMantenimiento)
                                          Container(
                                              margin:
                                                  const EdgeInsets.only(top: 6),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                  color: _isDarkMode
                                                      ? Colors.blueAccent.withAlpha(60)
                                                      : const Color(0xFFDBEAFE),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  border: _isDarkMode
                                                      ? null
                                                      : Border.all(
                                                          color: const Color(0xFF93C5FD))),
                                              child: Text(
                                                  "DÍA DE MANTENIMIENTO",
                                                  style: TextStyle(
                                                      color: _isDarkMode
                                                          ? Colors.blueAccent
                                                          : const Color(0xFF1D4ED8),
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold))),
                                        if (day.esFestivo && day.festivoTrabajado)
                                          Container(
                                              margin:
                                                  const EdgeInsets.only(top: 6),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                  color: _isDarkMode
                                                      ? Colors.purpleAccent.withAlpha(60)
                                                      : const Color(0xFFF3E8FF),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  border: _isDarkMode
                                                      ? null
                                                      : Border.all(
                                                          color: const Color(0xFFD8B4FE))),
                                              child: Text(
                                                  "DÍA FESTIVO",
                                                  style: TextStyle(
                                                      color: _isDarkMode
                                                          ? Colors.purpleAccent
                                                          : const Color(0xFF6B21A8),
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold))),
                                        if (day.isOvernight &&
                                            !day.esMantenimiento)
                                          Container(
                                              margin:
                                                  const EdgeInsets.only(top: 6),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                  color: _isDarkMode
                                                      ? Colors.redAccent.withAlpha(60)
                                                      : const Color(0xFFFEE2E2),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  border: _isDarkMode
                                                      ? null
                                                      : Border.all(
                                                          color: const Color(0xFFFCA5A5))),
                                              child: Text(
                                                  "SALIDA DÍA SIGUIENTE",
                                                  style: TextStyle(
                                                      color: _isDarkMode
                                                          ? Colors.redAccent
                                                          : const Color(0xFFB91C1C),
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold)))
                                      ]),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit,
                                            color: _isDarkMode
                                                ? Colors.orange
                                                : const Color(0xFFC2410C),
                                            size: 20),
                                        tooltip: "Editar turno",
                                        onPressed: () => _editExistingWorkDay(
                                            _weeklyHistory.indexOf(day)),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline,
                                            color: _isDarkMode
                                                ? Colors.white54
                                                : const Color(0xFF64748B),
                                            size: 24),
                                        onPressed: () => _showDeleteDialog(
                                            _weeklyHistory.indexOf(day)),
                                      ),
                                    ],
                                  ),
                                ]),
                            Divider(
                                color: _isDarkMode
                                    ? Colors.white24
                                    : const Color(0xFFE2E8F0)),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                          "Entrada Asignada: ${DateFormat('hh:mm a').format(day.entrada)}",
                                          style: TextStyle(
                                              color: _isDarkMode
                                                  ? (day.esMantenimiento
                                                      ? Colors.blueAccent
                                                      : Colors.orangeAccent)
                                                  : (day.esMantenimiento
                                                      ? const Color(0xFF1D4ED8)
                                                      : const Color(0xFFC2410C)),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500)),
                                      Text(
                                          "Salida: ${DateFormat('hh:mm a').format(day.salida)}",
                                          style: TextStyle(
                                              color: _isDarkMode
                                                  ? Colors.redAccent
                                                  : const Color(0xFFB91C1C),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                  if (day.entradaReal != null &&
                                      day.entradaReal != day.entrada)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                          "Registro Real: ${DateFormat('hh:mm a').format(day.entradaReal!)} ${day.entradaReal!.isBefore(day.entrada) ? '(Temprano)' : '(Tarde)'}",
                                          style: TextStyle(
                                              color: _isDarkMode
                                                  ? (day.entradaReal!.isBefore(day.entrada)
                                                      ? Colors.greenAccent
                                                      : Colors.yellowAccent)
                                                  : (day.entradaReal!.isBefore(day.entrada)
                                                      ? const Color(0xFF15803D)
                                                      : const Color(0xFFB45309)),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500)),
                                    ),
                                ],
                              ),
                            ),
                            if (day.esFestivo && day.festivoTrabajado)
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _statDetail(
                                        "DESGLOSE DE HORAS",
                                        "${normalHrs.toStringAsFixed(1)}h (Base) + ${day.holidayExtraHours.toStringAsFixed(2)}h (Extra)",
                                        "${day.totalHours.toStringAsFixed(2)} hrs totales"),
                                    _statDetail(
                                        "DESGLOSE DE PAGO",
                                        "Pago Base: \$${day.sueldoBase.toStringAsFixed(2)} × 2 = \$${(day.sueldoBase * 2).toStringAsFixed(2)}\n"
                                        "EXTRAS FESTIVO 3×: ${day.holidayExtraHours.toStringAsFixed(1)} hrs = \$${day.holidayExtrasPay.toStringAsFixed(2)}",
                                        "\$${day.totalPay.toStringAsFixed(2)}",
                                        isMoney: true)
                                  ])
                            else if (!day.esMantenimiento)
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _statDetail(
                                        "DESGLOSE DE HORAS",
                                        "${normalHrs.toStringAsFixed(1)}h (Base) + ${day.extraHoursCount.toStringAsFixed(2)}h (Extra)",
                                        "${day.totalHours.toStringAsFixed(2)} hrs totales"),
                                    _statDetail(
                                        "DESGLOSE DE PAGO",
                                        "\$${day.dailyPay.toStringAsFixed(2)} Base\n"
                                            "2× ${breakdown.hours2x.toStringAsFixed(2)}h  \$${breakdown.pay2x.toStringAsFixed(2)}\n"
                                            "3× ${breakdown.hours3x.toStringAsFixed(2)}h  \$${breakdown.pay3x.toStringAsFixed(2)}",
                                        "\$${(day.dailyPay + realExtrasPay).toStringAsFixed(2)}",
                                        isMoney: true)
                                  ])
                            else
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _isDarkMode
                                      ? Colors.blue.withAlpha(30)
                                      : const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: _isDarkMode
                                          ? Colors.blueAccent.withAlpha(100)
                                          : const Color(0xFF93C5FD)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        "MANTENIMIENTO - SIN HORAS EXTRA",
                                        style: TextStyle(
                                            color: _isDarkMode
                                                ? Colors.blueAccent
                                                : const Color(0xFF1D4ED8),
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(
                                        "Jornada: ${day.totalHours.toStringAsFixed(2)} hrs | Pago base: \$${day.dailyPay.toStringAsFixed(2)}",
                                        style: TextStyle(
                                            color: _isDarkMode
                                                ? Colors.white70
                                                : const Color(0xFF334155),
                                            fontSize: 13)),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 8),
                            Divider(
                                color: _isDarkMode
                                    ? Colors.white24
                                    : const Color(0xFFE2E8F0)),
                            _buildNotesSection(day),
                          ])));
                }),
        ),
      ],
    );
  }

  final List<GlobalKey> _weekKeys = List.generate(53, (_) => GlobalKey());
  bool _hasAutoScrolledAnoTab = false;

  void _scrollToCurrentWeek() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      DateTime now = DateTime.now();
      int year = now.year;
      DateTime jan1 = DateTime(year, 1, 1);
      DateTime firstMonday = jan1.subtract(Duration(days: jan1.weekday - 1));

      int currentWeekIndex = -1;
      for (int i = 0; i < 53; i++) {
        DateTime weekStart = firstMonday.add(Duration(days: i * 7));
        DateTime weekEnd = weekStart.add(const Duration(days: 6));

        if (now.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
            now.isBefore(weekEnd.add(const Duration(seconds: 1)))) {
          currentWeekIndex = i;
          break;
        }
      }

      if (currentWeekIndex != -1 && currentWeekIndex < _weekKeys.length) {
        final key = _weekKeys[currentWeekIndex];
        if (key.currentContext != null) {
          Scrollable.ensureVisible(
            key.currentContext!,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            alignment: 0.15,
          );
        }
      }
    });
  }

  Widget _buildAnoTab() {
    int year = DateTime.now().year;
    DateTime jan1 = DateTime(year, 1, 1);
    // Find the Monday of the week containing Jan 1st
    DateTime firstMonday = jan1.subtract(Duration(days: jan1.weekday - 1));

    // Spanish month abbreviations
    const List<String> monthNames = [
      'ENE',
      'FEB',
      'MAR',
      'ABR',
      'MAY',
      'JUN',
      'JUL',
      'AGO',
      'SEP',
      'OCT',
      'NOV',
      'DIC'
    ];

    // Trigger auto-scroll on first display of this tab
    if (!_hasAutoScrolledAnoTab) {
      _hasAutoScrolledAnoTab = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentWeek();
      });
    }

    return SingleChildScrollView(
      controller: _anoScrollController,
      child: Column(
        children: [
        Container(
          padding: const EdgeInsets.all(20),
          width: double.infinity,
          decoration: BoxDecoration(
            color: _isDarkMode
                ? Colors.orange.withAlpha(30)
                : const Color(0xFFFFF7ED),
            border: _isDarkMode
                ? null
                : const Border(
                    bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
          ),
          child: Text("REGISTRO ANUAL $year",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: _isDarkMode
                      ? Colors.orange
                      : const Color(0xFFC2410C),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2)),
        ),
        // Month header row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              const SizedBox(width: 60), // Space for week label
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('L',
                        style: TextStyle(
                            color: _isDarkMode
                                ? Colors.orange
                                : const Color(0xFFC2410C),
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    Text('M',
                        style: TextStyle(
                            color: _isDarkMode
                                ? Colors.orange
                                : const Color(0xFFC2410C),
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    Text('M',
                        style: TextStyle(
                            color: _isDarkMode
                                ? Colors.orange
                                : const Color(0xFFC2410C),
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    Text('J',
                        style: TextStyle(
                            color: _isDarkMode
                                ? Colors.orange
                                : const Color(0xFFC2410C),
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    Text('V',
                        style: TextStyle(
                            color: _isDarkMode
                                ? Colors.orange
                                : const Color(0xFFC2410C),
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    Text('S',
                        style: TextStyle(
                            color: _isDarkMode
                                ? Colors.orange
                                : const Color(0xFFC2410C),
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    Text('D',
                        style: TextStyle(
                            color: _isDarkMode
                                ? Colors.orange
                                : const Color(0xFFC2410C),
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(
            color: _isDarkMode ? Colors.white24 : const Color(0xFFCBD5E1),
            height: 1),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: 53, // Covers all potential weeks in a year
            itemBuilder: (context, index) {
              DateTime weekStart = firstMonday.add(Duration(days: index * 7));
              DateTime weekEnd = weekStart.add(const Duration(days: 6));

              // Highlight current week logic
              DateTime now = DateTime.now();
              bool isCurrent =
                  now.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
                      now.isBefore(weekEnd.add(const Duration(seconds: 1)));

              // Check if this week contains the first day of a month
              String? monthLabel;
              for (int day = 0; day < 7; day++) {
                DateTime checkDate = weekStart.add(Duration(days: day));
                if (checkDate.day == 1) {
                  monthLabel = monthNames[checkDate.month - 1];
                  break;
                }
              }

              return Padding(
                key: _weekKeys[index],
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Container(
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? (_isDarkMode
                            ? Colors.orange.withAlpha(30)
                            : const Color(0xFFFFF7ED))
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    border: isCurrent
                        ? Border.all(
                            color: _isDarkMode
                                ? Colors.orangeAccent.withAlpha(150)
                                : const Color(0xFFEA580C),
                            width: 2,
                          )
                        : null,
                  ),
                  padding: isCurrent ? const EdgeInsets.all(8) : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isCurrent)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8, left: 70),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isDarkMode
                                ? Colors.orangeAccent
                                : const Color(0xFFEA580C),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.today,
                                    color: _isDarkMode
                                        ? Colors.black
                                        : Colors.white,
                                    size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  "SEMANA ACTUAL",
                                  style: TextStyle(
                                    color: _isDarkMode
                                        ? Colors.black
                                        : Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ]),
                        ),
                      if (monthLabel != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6, left: 70),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _isDarkMode
                                  ? Colors.orange.withAlpha(80)
                                  : const Color(0xFFC2410C),
                              borderRadius: BorderRadius.circular(6),
                              border: _isDarkMode
                                  ? Border.all(
                                      color: Colors.orangeAccent.withAlpha(100))
                                  : null,
                            ),
                            child: Text(
                              monthLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16, // INCREASED from 11 to 16
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      _buildWeekRow(weekStart, "SEM ${index + 1}", isCurrent),
                      // Show overtime summary for this week if data exists
                      _buildWeekOvertimeSummary(weekStart),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    ));
  }

  Widget _buildWeekOvertimeSummary(DateTime weekStart) {
    // Get all days in this week (Monday to Sunday)
    DateTime weekEnd = weekStart.add(const Duration(days: 6));
    List<WorkDay> weekDays = _weeklyHistory.where((d) {
      return d.entrada
              .isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
          d.entrada.isBefore(weekEnd.add(const Duration(seconds: 1))) &&
          !d.esFalta;
    }).toList();

    if (weekDays.isEmpty) return const SizedBox.shrink();

    // Calculate overtime for this week
    final breakdownMap = calculateWeeklyOvertimeBreakdown(weekDays);
    double totalPay = 0.0;
    double totalHours = 0.0;
    for (var b in breakdownMap.values) {
      totalPay += b.totalPay;
      totalHours += b.hours2x + b.hours3x;
    }

    if (totalHours <= 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(left: 70, right: 10, bottom: 8, top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _isDarkMode
            ? Colors.orange.withAlpha(30)
            : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(8),
        border: _isDarkMode
            ? Border.all(color: Colors.orange.withAlpha(60))
            : Border.all(color: const Color(0xFFFED7AA), width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Extras: ${totalHours.toStringAsFixed(1)} hrs",
            style: TextStyle(
              color: _isDarkMode
                  ? Colors.orangeAccent
                  : const Color(0xFFC2410C),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "\$${totalPay.toStringAsFixed(2)}",
            style: TextStyle(
              color: _isDarkMode
                  ? Colors.greenAccent
                  : const Color(0xFF15803D),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekRow(DateTime startDay, String label, bool isCurrent) {
    // Check if today is in this week
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    return Row(
      children: [
        SizedBox(
            width: 60,
            child: Column(
              children: [
                Text(label,
                    style: TextStyle(
                        color: isCurrent
                            ? (_isDarkMode
                                ? Colors.orangeAccent
                                : Colors.black)
                            : (_isDarkMode
                                ? Colors.white54
                                : Colors.black),
                        fontSize: isCurrent ? 14 : 12,
                        fontWeight: FontWeight.bold)),
                if (isCurrent)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _isDarkMode
                          ? Colors.orangeAccent
                          : const Color(0xFFC2410C),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            )),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              DateTime dayDate = startDay.add(Duration(days: index));
              DateTime dayDateNormalized =
                  DateTime(dayDate.year, dayDate.month, dayDate.day);
              bool isToday = dayDateNormalized == today;
              bool isSelected = dayDate.day == _selectedCalendarDay.day &&
                  dayDate.month == _selectedCalendarDay.month &&
                  dayDate.year == _selectedCalendarDay.year;
              bool hasData = _weeklyHistory.any((d) =>
                  d.entrada.day == dayDate.day &&
                  d.entrada.month == dayDate.month &&
                  d.entrada.year == dayDate.year);
              bool isMantenimiento = _weeklyHistory.any((d) =>
                  d.entrada.day == dayDate.day &&
                  d.entrada.month == dayDate.month &&
                  d.entrada.year == dayDate.year &&
                  d.esMantenimiento);
              bool isVacaciones = _weeklyHistory.any((d) =>
                  d.entrada.day == dayDate.day &&
                  d.entrada.month == dayDate.month &&
                  d.entrada.year == dayDate.year &&
                  d.esVacaciones);
              bool isFestivo = _weeklyHistory.any((d) =>
                  d.entrada.day == dayDate.day &&
                  d.entrada.month == dayDate.month &&
                  d.entrada.year == dayDate.year &&
                  d.esFestivo);
              bool isFalta = _weeklyHistory.any((d) =>
                  d.entrada.day == dayDate.day &&
                  d.entrada.month == dayDate.month &&
                  d.entrada.year == dayDate.year &&
                  d.esFalta);
              bool hasNotes = _weeklyHistory.any((d) =>
                  d.entrada.day == dayDate.day &&
                  d.entrada.month == dayDate.month &&
                  d.entrada.year == dayDate.year &&
                  d.notas.isNotEmpty);

              // Manual Spanish Map
              const dialNames = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
              String dayLetter = dialNames[dayDate.weekday - 1];
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedCalendarDay = dayDate);
                  _showManualDayDialog(dayDate);
                },
                child: Container(
                  width: isToday ? 48 : 42, // Slightly larger for today
                  height: isToday ? 48 : 42,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isToday
                        ? (_isDarkMode
                            ? Colors.orangeAccent.withAlpha(80) // Strong highlight for today
                            : const Color(0xFFFFEDD5))
                        : isSelected
                            ? (_isDarkMode
                                ? (isMantenimiento
                                    ? Colors.blue.withAlpha(50)
                                    : isFestivo
                                        ? Colors.purple.withAlpha(50)
                                        : isVacaciones
                                            ? Colors.lightGreen.withAlpha(50)
                                            : isFalta
                                                ? Colors.red.shade700
                                                : Colors.green.withAlpha(50)) // Asistencia GREEN
                                : (isMantenimiento
                                    ? const Color(0xFFDBEAFE)
                                    : isFestivo
                                        ? const Color(0xFFF3E8FF)
                                        : isVacaciones
                                            ? const Color(0xFFDCFCE7)
                                            : isFalta
                                                ? const Color(0xFFFEE2E2)
                                                : (hasData
                                                    ? const Color(0xFFDCFCE7)
                                                    : Colors.white)))
                            : (hasData
                                ? (_isDarkMode
                                    ? (isMantenimiento
                                        ? Colors.blue.withAlpha(40)
                                        : isFestivo
                                            ? Colors.purple.withAlpha(40)
                                            : isVacaciones
                                                ? Colors.lightGreen.withAlpha(40)
                                                : isFalta
                                                    ? Colors.red.shade700
                                                    : Colors.green.withAlpha(40)) // Asistencia GREEN
                                    : (isMantenimiento
                                        ? const Color(0xFFEFF6FF)
                                        : isFestivo
                                            ? const Color(0xFFFAF5FF)
                                            : isVacaciones
                                                ? const Color(0xFFDCFCE7)
                                                : isFalta
                                                    ? const Color(0xFFFEF2F2)
                                                    : const Color(0xFFDCFCE7)))
                                : (_isDarkMode
                                    ? (isCurrent
                                        ? Colors.transparent
                                        : Colors.white.withAlpha(5))
                                    : Colors.white)),
                    borderRadius: BorderRadius.circular(
                        isToday ? 12 : 8), // More rounded for today
                    border: Border.all(
                        color: isToday
                            ? (_isDarkMode
                                ? Colors.orangeAccent // Bright border for today
                                : const Color(0xFFEA580C))
                            : isSelected
                                ? (_isDarkMode
                                    ? (isMantenimiento
                                        ? Colors.blueAccent
                                        : isFestivo
                                            ? Colors.purpleAccent
                                            : isVacaciones
                                                ? Colors.lightGreenAccent
                                                : isFalta
                                                    ? Colors.redAccent
                                                    : Colors.greenAccent)
                                    : const Color(0xFFEA580C))
                                : (hasData
                                    ? (_isDarkMode
                                        ? (isMantenimiento
                                            ? Colors.blueAccent
                                            : isFestivo
                                                ? Colors.purpleAccent
                                                : isVacaciones
                                                    ? Colors.lightGreenAccent
                                                    : isFalta
                                                        ? Colors.redAccent
                                                        : Colors.greenAccent)
                                        : (isMantenimiento
                                            ? const Color(0xFF93C5FD)
                                            : isFestivo
                                                ? const Color(0xFFD8B4FE)
                                                : isVacaciones
                                                    ? const Color(0xFF16A34A)
                                                    : isFalta
                                                        ? const Color(0xFFFCA5A5)
                                                        : const Color(0xFF16A34A)))
                                    : (_isDarkMode
                                        ? Colors.white10
                                        : const Color(0xFFCBD5E1))),
                        width: isToday
                            ? 3
                            : (isSelected ? 2.0 : (hasData ? 2.0 : 1.2))), // Thicker border for today
                    boxShadow: isToday
                        ? [
                            BoxShadow(
                              color: _isDarkMode
                                  ? Colors.orangeAccent.withAlpha(100)
                                  : const Color(0xFFEA580C).withAlpha(60),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(dayLetter,
                                  style: TextStyle(
                                      color: isToday
                                          ? (_isDarkMode
                                              ? Colors.white // White for today
                                              : const Color(0xFF9A3412))
                                          : (isFalta
                                              ? (_isDarkMode
                                                  ? Colors.white
                                                  : const Color(0xFF991B1B))
                                              : (_isDarkMode
                                                  ? Colors.orange
                                                  : const Color(0xFFC2410C))),
                                      fontSize: isToday ? 12 : 10,
                                      height: 1.0,
                                      fontWeight: FontWeight.bold)),
                              if (hasNotes) ...[
                                const SizedBox(width: 2),
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: _isDarkMode
                                        ? Colors.orangeAccent
                                        : const Color(0xFFC2410C),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                              if (isVacaciones || isFestivo) ...[
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.star,
                                  color: _isDarkMode
                                      ? (isVacaciones
                                          ? Colors.lightGreenAccent
                                          : Colors.purpleAccent)
                                      : (isVacaciones
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFF9333EA)),
                                  size: 10,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(dayDate.day.toString(),
                              style: TextStyle(
                                  color: isToday
                                      ? (_isDarkMode
                                          ? Colors.black // Black number on orange for contrast
                                          : const Color(0xFF7C2D12))
                                      : (hasData
                                          ? (_isDarkMode
                                              ? (isMantenimiento
                                                  ? Colors.blueAccent
                                                  : isFestivo
                                                      ? Colors.purpleAccent
                                                      : isVacaciones
                                                          ? Colors.lightGreenAccent
                                                          : isFalta
                                                              ? Colors.white
                                                              : Colors.greenAccent)
                                              : (isMantenimiento
                                                  ? const Color(0xFF1D4ED8)
                                                  : isFestivo
                                                      ? const Color(0xFF6B21A8)
                                                      : isVacaciones
                                                          ? const Color(0xFF14532D)
                                                          : isFalta
                                                              ? const Color(0xFF991B1B)
                                                              : const Color(0xFF14532D)))
                                          : (_isDarkMode
                                              ? (isCurrent
                                                  ? Colors.white
                                                  : Colors.white70)
                                              : Colors.black)),
                                  fontSize: isToday ? 16 : 14,
                                  height: 1.0,
                                  fontWeight: isToday
                                      ? FontWeight.w900
                                      : FontWeight.bold)), // Extra bold for today
                        ]),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  void _scrollToActiveNomina() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted || !_nominaScrollController.hasClients) return;

      DateTime now = DateTime.now();
      int enProgresoIndex = -1;

      for (int i = 0; i < _payCalendar2026.length; i++) {
        var cfg = _payCalendar2026.values.elementAt(i);
        List<int> quincenaWeeks = List<int>.from(cfg['weeks']);
        if (quincenaWeeks.isNotEmpty) {
          quincenaWeeks.sort();
          int firstWeek = quincenaWeeks.first;
          int lastWeek = quincenaWeeks.last;
          int yearForFirstWeek = firstWeek >= 48 ? now.year - 1 : now.year;
          int yearForLastWeek = lastWeek >= 48 ? now.year - 1 : now.year;
          DateTime jan4First = DateTime(yearForFirstWeek, 1, 4);
          DateTime firstMonday = jan4First.subtract(Duration(days: jan4First.weekday - 1));
          DateTime quincenaStartDate = firstMonday.add(Duration(days: (firstWeek - 1) * 7));
          DateTime jan4Last = DateTime(yearForLastWeek, 1, 4);
          DateTime lastMonday = jan4Last.subtract(Duration(days: jan4Last.weekday - 1));
          DateTime lastWeekStart = lastMonday.add(Duration(days: (lastWeek - 1) * 7));
          DateTime quincenaEndDate = lastWeekStart.add(const Duration(days: 6, hours: 23, minutes: 59));
          bool isCurrentlyAffected = now.isAfter(quincenaStartDate.subtract(const Duration(seconds: 1))) &&
                                     now.isBefore(quincenaEndDate.add(const Duration(seconds: 1)));
          if (isCurrentlyAffected) {
            enProgresoIndex = i;
            break;
          }
        }
      }

      if (enProgresoIndex != -1) {
        double estimatedItemHeight = 135.0;
        double viewport = _nominaScrollController.position.viewportDimension;
        
        // Formula from Screenshot 1 shifted up by 2 cards (-250px) to match Screenshot 2
        double targetOffset = (((enProgresoIndex + 1) * estimatedItemHeight) - viewport + 24.0) - 250.0;
        double maxScroll = _nominaScrollController.position.maxScrollExtent;
        targetOffset = targetOffset.clamp(0.0, maxScroll);

        _nominaScrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Widget _buildNominaTab() {
    double retentionPct = double.tryParse(_retentionController.text) ?? 15.22;
    double fomentoRate =
        (double.tryParse(_fomentoController.text) ?? 2.0) / 100.0;
    double cuotaSindicalRate =
        (double.tryParse(_cuotaController.text) ?? 2.0) / 100.0;

    // Get current date info for determining quincena status
    DateTime now = DateTime.now();

    return ListView.builder(
      controller: _nominaScrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _payCalendar2026.length,
      itemBuilder: (context, index) {
        String pid = _payCalendar2026.keys.elementAt(index);
        var cfg = _payCalendar2026[pid]!;
        List<WorkDay> matched = _weeklyHistory
            .where((d) => cfg['weeks'].contains(_getWeekNumber(d.entrada)))
            .toList();

        // Parse payout date (format: "dd/MM/yy")
        DateTime? payoutDate;
        try {
          String payoutStr = cfg['payout'] as String;
          List<String> parts = payoutStr.split('/');
          if (parts.length == 3) {
            int day = int.parse(parts[0]);
            int month = int.parse(parts[1]);
            int year = 2000 + int.parse(parts[2]); // Convert "26" to "2026"
            payoutDate = DateTime(year, month, day);
          }
        } catch (e) {
          payoutDate = null;
        }

        // Determine quincena status
        // 1. Paid out: payout date is today or has passed (GREEN) - DATE BASED ONLY
        // 2. Currently affected: current week is in this quincena's weeks (ORANGE)
        // 3. Next to be paid: the next quincena after the current one (YELLOW)

        bool isPaidOut = payoutDate != null &&
            (payoutDate.isBefore(now) ||
                (payoutDate.year == now.year &&
                    payoutDate.month == now.month &&
                    payoutDate.day == now.day));

        // Calculate date range for this quincena based on its weeks
        DateTime? quincenaStartDate;
        DateTime? quincenaEndDate;

        // Find the first and last week of this quincena
        List<int> quincenaWeeks = List<int>.from(cfg['weeks']);
        if (quincenaWeeks.isNotEmpty) {
          // Sort weeks to find first and last
          quincenaWeeks.sort();

          // Find dates for first week (Monday) and last week (Sunday)
          // Week 1 starts on first Monday of year
          DateTime jan4 = DateTime(now.year, 1, 4); // Jan 4 is always in week 1
          DateTime firstMonday =
              jan4.subtract(Duration(days: jan4.weekday - 1));

          int firstWeek = quincenaWeeks.first;
          int lastWeek = quincenaWeeks.last;

          // Handle year boundary - if week is 48+, it's likely previous year
          // For 2026 calendar, weeks 48+ are from 2025
          int yearForFirstWeek = firstWeek >= 48 ? now.year - 1 : now.year;
          int yearForLastWeek = lastWeek >= 48 ? now.year - 1 : now.year;

          // Recalculate firstMonday for correct year
          DateTime jan4First = DateTime(yearForFirstWeek, 1, 4);
          firstMonday =
              jan4First.subtract(Duration(days: jan4First.weekday - 1));
          quincenaStartDate =
              firstMonday.add(Duration(days: (firstWeek - 1) * 7));

          // For end date, use the year of the last week
          DateTime jan4Last = DateTime(yearForLastWeek, 1, 4);
          DateTime lastMonday =
              jan4Last.subtract(Duration(days: jan4Last.weekday - 1));
          DateTime lastWeekStart =
              lastMonday.add(Duration(days: (lastWeek - 1) * 7));
          quincenaEndDate = lastWeekStart
              .add(const Duration(days: 6, hours: 23, minutes: 59));
        }

        // Currently affected if today falls within the quincena's date range
        bool isCurrentlyAffected = quincenaStartDate != null &&
            quincenaEndDate != null &&
            now.isAfter(
                quincenaStartDate.subtract(const Duration(seconds: 1))) &&
            now.isBefore(quincenaEndDate.add(const Duration(seconds: 1)));

        // Find if this is the next quincena after current
        bool isNextToPay = false;
        if (!isPaidOut && !isCurrentlyAffected && payoutDate != null) {
          // Find the earliest unpaid payout date (that is not currently affected)
          // This is the true "next to pay" - the chronologically next unpaid quincena
          DateTime? earliestUnpaidPayoutDate;
          String? earliestUnpaidPid;

          for (int i = 0; i < _payCalendar2026.length; i++) {
            String checkPid = _payCalendar2026.keys.elementAt(i);
            var checkCfg = _payCalendar2026.values.elementAt(i);

            // Parse payout date
            DateTime? checkPayoutDate;
            try {
              String checkPayoutStr = checkCfg['payout'] as String;
              List<String> parts = checkPayoutStr.split('/');
              if (parts.length == 3) {
                int day = int.parse(parts[0]);
                int month = int.parse(parts[1]);
                int year = 2000 + int.parse(parts[2]);
                checkPayoutDate = DateTime(year, month, day);
              }
            } catch (e) {
              continue;
            }

            // Skip if paid out (payout date is today or in the past)
            bool checkIsPaidOut = checkPayoutDate != null &&
                (checkPayoutDate.isBefore(now) ||
                    (checkPayoutDate.year == now.year &&
                        checkPayoutDate.month == now.month &&
                        checkPayoutDate.day == now.day));

            if (checkIsPaidOut) continue;

            // Skip if currently affected
            List<int> checkWeeks = List<int>.from(checkCfg['weeks']);
            DateTime? checkStartDate;
            DateTime? checkEndDate;
            List<int> checkQuincenaWeeks = List<int>.from(checkWeeks);
            if (checkQuincenaWeeks.isNotEmpty) {
              checkQuincenaWeeks.sort();
              int firstWeek = checkQuincenaWeeks.first;
              int lastWeek = checkQuincenaWeeks.last;
              int yearForFirstWeek = firstWeek >= 48 ? now.year - 1 : now.year;
              int yearForLastWeek = lastWeek >= 48 ? now.year - 1 : now.year;
              DateTime jan4First = DateTime(yearForFirstWeek, 1, 4);
              DateTime firstMonday =
                  jan4First.subtract(Duration(days: jan4First.weekday - 1));
              checkStartDate =
                  firstMonday.add(Duration(days: (firstWeek - 1) * 7));
              DateTime jan4Last = DateTime(yearForLastWeek, 1, 4);
              DateTime lastMonday =
                  jan4Last.subtract(Duration(days: jan4Last.weekday - 1));
              DateTime lastWeekStart =
                  lastMonday.add(Duration(days: (lastWeek - 1) * 7));
              checkEndDate = lastWeekStart
                  .add(const Duration(days: 6, hours: 23, minutes: 59));
            }

            bool checkIsCurrentlyAffected = checkStartDate != null &&
                checkEndDate != null &&
                now.isAfter(
                    checkStartDate.subtract(const Duration(seconds: 1))) &&
                now.isBefore(checkEndDate.add(const Duration(seconds: 1)));

            if (checkIsCurrentlyAffected) continue;

            // This quincena is unpaid and not currently affected
            // Check if it's the earliest one
            if (checkPayoutDate != null) {
              if (earliestUnpaidPayoutDate == null ||
                  checkPayoutDate.isBefore(earliestUnpaidPayoutDate)) {
                earliestUnpaidPayoutDate = checkPayoutDate;
                earliestUnpaidPid = checkPid;
              }
            }
          }

          // Mark as next to pay if this is the earliest unpaid quincena
          isNextToPay = (pid == earliestUnpaidPid);
        }

        // Determine colors based on status - NOW PURELY DATE-BASED, NOT DATA-DEPENDENT
        Color cardColor;
        Color borderColor;
        Color titleColor;
        Color iconColor;
        Color statusBgColor;
        Color statusTextColor;
        String statusLabel;

        if (isPaidOut) {
          // PAID OUT - Green theme (ALL past quincenas regardless of data)
          cardColor = _isDarkMode
              ? Colors.green.withAlpha(15)
              : const Color(0xFFF0FDF4);
          borderColor = _isDarkMode
              ? Colors.green.withAlpha(80)
              : const Color(0xFF86EFAC);
          titleColor = _isDarkMode
              ? Colors.greenAccent
              : const Color(0xFF15803D);
          iconColor = _isDarkMode
              ? Colors.greenAccent
              : const Color(0xFF15803D);
          statusBgColor = _isDarkMode
              ? borderColor.withAlpha(40)
              : const Color(0xFFDCFCE7);
          statusTextColor = _isDarkMode
              ? titleColor
              : const Color(0xFF166534);
          statusLabel = "PAGADO";
        } else if (isCurrentlyAffected) {
          // CURRENTLY AFFECTED - Orange theme
          cardColor = _isDarkMode
              ? Colors.orange.withAlpha(15)
              : const Color(0xFFFFF7ED);
          borderColor = _isDarkMode
              ? Colors.orange.withAlpha(80)
              : const Color(0xFFFDBA74);
          titleColor = _isDarkMode
              ? Colors.orange
              : const Color(0xFFC2410C);
          iconColor = _isDarkMode
              ? Colors.orange
              : const Color(0xFFC2410C);
          statusBgColor = _isDarkMode
              ? borderColor.withAlpha(40)
              : const Color(0xFFFFEDD5);
          statusTextColor = _isDarkMode
              ? titleColor
              : const Color(0xFF9A3412);
          statusLabel = "EN PROGRESO";
        } else if (isNextToPay) {
          // NEXT TO PAY - Yellow theme
          cardColor = _isDarkMode
              ? Colors.yellow.withAlpha(15)
              : const Color(0xFFFEFCE8);
          borderColor = _isDarkMode
              ? Colors.yellowAccent.withAlpha(80)
              : const Color(0xFFFDE047);
          titleColor = _isDarkMode
              ? Colors.yellowAccent
              : const Color(0xFF854D0E);
          iconColor = _isDarkMode
              ? Colors.yellowAccent
              : const Color(0xFF854D0E);
          statusBgColor = _isDarkMode
              ? borderColor.withAlpha(40)
              : const Color(0xFFFEF9C3);
          statusTextColor = _isDarkMode
              ? titleColor
              : const Color(0xFF713F12);
          statusLabel = "PRÓXIMO PAGO";
        } else {
          // Default - Future quincenas beyond next
          cardColor = _isDarkMode
              ? Colors.white.withAlpha(5)
              : Colors.white;
          borderColor = _isDarkMode
              ? Colors.transparent
              : const Color(0xFFCBD5E1);
          titleColor = _isDarkMode
              ? Colors.white60
              : Colors.black;
          iconColor = _isDarkMode
              ? Colors.white38
              : Colors.black54;
          statusBgColor = Colors.transparent;
          statusTextColor = Colors.transparent;
          statusLabel = "";
        }

        // Calculate base quincena using actual applicable salary for date
        // A standard Mexican quincena represents 15 calendar days of base salary.
        DateTime referenceDate = payoutDate ?? now;
        double applicableSalary = _getSalaryForDate(referenceDate);
        double baseQuincena = applicableSalary * 15;

        int faltasCount = matched.where((d) => d.esFalta).length;
        int diasLaborados =
            matched.where((d) => !d.esFalta && !d.isInProgress).length;

        // Total scheduled workdays in this quincena's weeks (e.g., 2 weeks = 10 workdays)
        int scheduledWorkdays = (cfg['weeks'] as List).length * 5;
        if (scheduledWorkdays == 0) scheduledWorkdays = 10;

        double descuentoFaltas = 0.0;
        if (faltasCount > 0) {
          if (faltasCount >= scheduledWorkdays && diasLaborados == 0) {
            // Employee missed all scheduled workdays in the period: 100% deduction ($0 payout)
            descuentoFaltas = baseQuincena;
          } else {
            // Each missed workday discounts its proportional share of the 15-day base quincena
            // (e.g., In a 10-day period, 1 falta discounts 15/10 = 1.5 days of base pay,
            // covering 1 workday + 0.5 proportional rest day per Mexican LFT Art. 29/30).
            double factorPerFalta = 15.0 / scheduledWorkdays;
            descuentoFaltas = faltasCount * factorPerFalta * applicableSalary;
            if (descuentoFaltas > baseQuincena) {
              descuentoFaltas = baseQuincena;
            }
          }
        }

        double baseEarned = baseQuincena - descuentoFaltas;
        if (baseEarned < 0) baseEarned = 0.0;

        double totalExtras = 0.0;
        double totalHours2x = 0.0;
        double totalHours3x = 0.0;

        // Group days by ISO week (Monday–Sunday)
        final Map<int, List<WorkDay>> weeks = {};

        for (final d in matched) {
          final int week = _getWeekNumber(d.entrada);
          weeks.putIfAbsent(week, () => []);
          weeks[week]!.add(d);
        }

        // Apply centralized weekly overtime logic and accumulate hours
        for (final weekDays in weeks.values) {
          final breakdownMap = calculateWeeklyOvertimeBreakdown(weekDays);
          for (var b in breakdownMap.values) {
            totalExtras += b.totalPay;
            totalHours2x += b.hours2x;
            totalHours3x += b.hours3x;
          }
        }

        double weekendBonus = matched
            .where((d) => d.entrada.weekday > 5 && !d.esFalta)
            .fold(0, (totalSum, d) => totalSum + d.dailyPay);
        double fomentoEficiencia = baseEarned * fomentoRate;
        double totalBruto = baseEarned +
            fomentoEficiencia +
            totalExtras +
            weekendBonus;
        if (totalBruto < 0) totalBruto = 0.0;

        double cuotaSindical = baseEarned * cuotaSindicalRate;
        double isrEstimate =
            totalBruto > 0 ? totalBruto * (retentionPct / 100) : 0.0;
        double netDeposit = totalBruto - (isrEstimate + cuotaSindical);
        if (netDeposit < 0) netDeposit = 0.0;
        return Card(
          color: cardColor,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(
                  color: borderColor,
                  width:
                      isPaidOut || isNextToPay || isCurrentlyAffected ? 2 : 1)),
          child: ExpansionTile(
            iconColor: iconColor,
            title: Row(
              children: [
                Expanded(
                  child: Text("PAGO: ${cfg['payout']}",
                      style: TextStyle(
                          color: titleColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 22)),
                ),
                if (statusLabel.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: _isDarkMode
                              ? borderColor.withAlpha(100)
                              : borderColor),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusTextColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    "SEMANAS HRS EXTRAS A PAGAR: ${(cfg['weeks'] as List).join(', ')}",
                    style: TextStyle(
                        color: _isDarkMode
                            ? Colors.white70
                            : Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                Text("DEPÓSITO EST.: \$${netDeposit.toStringAsFixed(2)}",
                    style: TextStyle(
                        color: _isDarkMode
                            ? Colors.greenAccent
                            : const Color(0xFF15803D),
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(children: [
                  _confirmRow("NOMBRE:",
                      "${_firstNameController.text} ${_lastNameController.text}"),
                  _confirmRow("NO. EMPLEADO:", _userEmpNoController.text),
                  Divider(
                      color: _isDarkMode
                          ? Colors.white10
                          : const Color(0xFFE2E8F0)),
                  _confirmRow("Salario Base (15d):",
                      "\$${baseQuincena.toStringAsFixed(2)}"),
                  if (descuentoFaltas > 0)
                    _confirmRow("Descuento Faltas ($faltasCount):",
                        "-\$${descuentoFaltas.toStringAsFixed(2)}"),
                  _confirmRow("Fomento Eficiencia:",
                      "+\$${fomentoEficiencia.toStringAsFixed(2)}"),
                  _confirmRow("Extras + Domingos:",
                      "+\$${(totalExtras + weekendBonus).toStringAsFixed(2)}"),
                  _confirmRow("Horas Extras (2x):",
                      "${totalHours2x.toStringAsFixed(1)} hrs"),
                  _confirmRow("Horas Extras (3x):",
                      "${totalHours3x.toStringAsFixed(1)} hrs"),
                  _confirmRow("I.S.R. Estimado:",
                      "-\$${isrEstimate.toStringAsFixed(2)}"),
                  Divider(
                      color: _isDarkMode
                          ? Colors.orange
                          : const Color(0xFFEA580C),
                      thickness: 2),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("TOTAL NETO:",
                            style: TextStyle(
                                color: _isDarkMode
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                        Text("\$${netDeposit.toStringAsFixed(2)}",
                            style: TextStyle(
                                color: _isDarkMode
                                    ? Colors.greenAccent
                                    : const Color(0xFF15803D),
                                fontWeight: FontWeight.w900,
                                fontSize: 28)),
                      ]),
                ]),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildExtrasTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SECTION 1: LINKS
          Text("LINKS",
              style: TextStyle(
                  color: _isDarkMode ? Colors.orange : const Color(0xFFC2410C),
                  fontWeight: FontWeight.bold,
                  fontSize: 20)),
          const SizedBox(height: 15),
          _buildShareAppTile(),
          const SizedBox(height: 10),
          _buildLinkTile("Portal Televisa", Icons.work,
              "https://tuportaldevacaciones.televisaunivision.com/portaltv/inicio.aspx"),
          const SizedBox(height: 10),
          _buildLinkTile("Monedero Chedraui", Icons.shopping_bag,
              "https://monederodespensa.chedraui.com.mx/home"),
          const SizedBox(height: 25),
          Divider(
              color: _isDarkMode ? Colors.white24 : const Color(0xFFCBD5E1)),

          // SECTION 2: REDES WI-FI
          const SizedBox(height: 25),
          Text("REDES WI-FI",
              style: TextStyle(
                  color: _isDarkMode ? Colors.orange : const Color(0xFFC2410C),
                  fontWeight: FontWeight.bold,
                  fontSize: 20)),
          const SizedBox(height: 15),

          // Televisa San Angel
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.white.withAlpha(10) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: _isDarkMode
                  ? Border.all(color: Colors.orange.withAlpha(50))
                  : Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Televisa San Angel",
                    style: TextStyle(
                        color: _isDarkMode
                            ? Colors.white
                            : const Color(0xFF0F172A),
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                _buildWifiTile("TUGuest", r"4N1V$sI0N*TvsA",
                    note: "(Tiene acceso a Portal Televisa)"),
                Divider(
                    color:
                        _isDarkMode ? Colors.white24 : const Color(0xFFE2E8F0),
                    height: 20),
                _buildWifiTile("#tvsauniv", r"welcome.2021"),
                Divider(
                    color:
                        _isDarkMode ? Colors.white24 : const Color(0xFFE2E8F0),
                    height: 20),
                _buildWifiTile("SSID FORO-1", r"7oR0_$%1"),
                Divider(
                    color:
                        _isDarkMode ? Colors.white24 : const Color(0xFFE2E8F0),
                    height: 20),
                _buildWifiTile("SSID FORO-2", r"S4g_F0%2"),
                Divider(
                    color:
                        _isDarkMode ? Colors.white24 : const Color(0xFFE2E8F0),
                    height: 20),
                _buildWifiTile("SSID FORO-4", r"4_$%5gT3I3"),
                Divider(
                    color:
                        _isDarkMode ? Colors.white24 : const Color(0xFFE2E8F0),
                    height: 20),
                _buildWifiTile("SSID FORO-5", r"T3I3@F0r0_5"),
                Divider(
                    color:
                        _isDarkMode ? Colors.white24 : const Color(0xFFE2E8F0),
                    height: 20),
                _buildWifiTile("SSID FORO-6", r"SNG_$6/For0"),
                Divider(
                    color:
                        _isDarkMode ? Colors.white24 : const Color(0xFFE2E8F0),
                    height: 20),
                _buildWifiTile("SSID FORO-8", r"f0r0_53I/8",
                    note: "(Clave vieja, nos compartes la nueva?)"),
                Divider(
                    color:
                        _isDarkMode ? Colors.white24 : const Color(0xFFE2E8F0),
                    height: 20),
                _buildWifiTile("SSID FORO-9", r"9@_T3I3v*",
                    note: "(Clave vieja, nos compartes la nueva?)"),
                Divider(
                    color:
                        _isDarkMode ? Colors.white24 : const Color(0xFFE2E8F0),
                    height: 20),
                _buildWifiTile("SSID FORO-11", r"t3@v1s4/11"),
                Divider(
                    color:
                        _isDarkMode ? Colors.white24 : const Color(0xFFE2E8F0),
                    height: 20),
                _buildWifiTile("SSID FORO-12", r"T31e$srlJ"),
                Divider(
                    color:
                        _isDarkMode ? Colors.white24 : const Color(0xFFE2E8F0),
                    height: 20),
                _buildWifiTile("SSID FORO-14", r"14_@S4g/vI5a"),
                Divider(
                    color:
                        _isDarkMode ? Colors.white24 : const Color(0xFFE2E8F0),
                    height: 20),
                _buildWifiTile("SSID FORO-15", r"Sg3L/T3v15"),
              ],
            ),
          ),

          const SizedBox(height: 15),
          // Televisa Chapultepec (placeholder)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.white.withAlpha(5) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: _isDarkMode
                  ? Border.all(color: Colors.white24)
                  : Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Televisa Chapultepec",
                    style: TextStyle(
                        color: _isDarkMode
                            ? Colors.white70
                            : const Color(0xFF0F172A),
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                Text("Información no disponible",
                    style: TextStyle(
                        color: _isDarkMode
                            ? Colors.white38
                            : const Color(0xFF64748B),
                        fontSize: 14)),
              ],
            ),
          ),

          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isDarkMode
                  ? Colors.orange.withAlpha(20)
                  : const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: _isDarkMode
                      ? Colors.orange.withAlpha(60)
                      : const Color(0xFFFED7AA),
                  width: 1.2),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color:
                        _isDarkMode ? Colors.orange : const Color(0xFFC2410C),
                    size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Las redes pueden cambiar sin previo aviso, en caso de que quieras contribuir, favor de enviarnos un correo en Ajustes > Información. Ayudanos a encontrar las claves de las redes faltantes! :D",
                    style: TextStyle(
                        color: _isDarkMode
                            ? Colors.orangeAccent
                            : const Color(0xFF9A3412),
                        fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),
          Divider(
              color: _isDarkMode ? Colors.white24 : const Color(0xFFCBD5E1)),

          // SECTION 3: INFORMACIÓN GENERAL
          const SizedBox(height: 25),
          Text("INFORMACIÓN GENERAL",
              style: TextStyle(
                  color: _isDarkMode ? Colors.orange : const Color(0xFFC2410C),
                  fontWeight: FontWeight.bold,
                  fontSize: 20)),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.white.withAlpha(5) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: _isDarkMode
                  ? Border.all(color: Colors.white24)
                  : Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
            ),
            child: Center(
              child: Text(
                "Próximamente...",
                style: TextStyle(
                    color: _isDarkMode
                        ? Colors.white38
                        : const Color(0xFF64748B),
                    fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTile(String title, IconData icon, String url) {
    return ListTile(
      leading: Icon(icon,
          color: _isDarkMode ? Colors.orange : const Color(0xFFC2410C),
          size: 28),
      title: Text(title,
          style: TextStyle(
              color: _isDarkMode ? Colors.white : const Color(0xFF1E293B),
              fontSize: 16,
              fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.open_in_new,
          color:
              _isDarkMode ? Colors.orangeAccent : const Color(0xFFC2410C),
          size: 20),
      tileColor: _isDarkMode ? Colors.white.withAlpha(10) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: _isDarkMode
            ? BorderSide(color: Colors.orange.withAlpha(30))
            : const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
      ),
      onTap: () async {
        final Uri uri = Uri.parse(url);
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("No se pudo abrir: $url")),
            );
          }
        }
      },
    );
  }

  Widget _buildShareAppTile() {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _isDarkMode
              ? Colors.green.withAlpha(30)
              : const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: _isDarkMode
                  ? Colors.green.withAlpha(80)
                  : const Color(0xFF86EFAC)),
        ),
        child: Icon(Icons.share,
            color: _isDarkMode
                ? Colors.greenAccent
                : const Color(0xFF15803D),
            size: 28),
      ),
      title: Text("Compartir App",
          style: TextStyle(
              color: _isDarkMode ? Colors.white : const Color(0xFF1E293B),
              fontSize: 16,
              fontWeight: FontWeight.w500)),
      subtitle: Text("Invita a tus compañeros",
          style: TextStyle(
              color: _isDarkMode ? Colors.white54 : const Color(0xFF64748B),
              fontSize: 12)),
      trailing: Icon(Icons.arrow_forward_ios,
          color: _isDarkMode
              ? Colors.greenAccent
              : const Color(0xFF15803D),
          size: 18),
      tileColor: _isDarkMode ? Colors.white.withAlpha(10) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: _isDarkMode
            ? BorderSide(color: Colors.green.withAlpha(50))
            : const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
      ),
      onTap: () async {
        const String appUrl = 'https://nomina-televisa-v2.web.app/';
        const String shareMessage =
            '¡Hola! Te invito a usar Mi Nómina Pro, la app para llevar el control de tus horas y nómina de Televisa. '
            'Es muy útil y fácil de usar. ¡Utilizala con esta liga!\n\n'
            '$appUrl';

        await Share.share(
          shareMessage,
          subject: '¡Te invito a usar Mi Nómina Pro!',
        );
      },
    );
  }

  Widget _buildWifiTile(String ssid, String password, {String? note}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(" $ssid",
                      style: TextStyle(
                          color: _isDarkMode
                              ? Colors.white
                              : const Color(0xFF1E293B),
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  if (note != null)
                    Text(note,
                        style: TextStyle(
                            color: _isDarkMode
                                ? Colors.orangeAccent.withAlpha(180)
                                : const Color(0xFFC2410C),
                            fontSize: 11)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text("Contraseña: ",
                          style: TextStyle(
                              color: _isDarkMode
                                  ? Colors.white70
                                  : const Color(0xFF475569),
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                      Text(password,
                          style: TextStyle(
                              color: _isDarkMode
                                  ? Colors.greenAccent
                                  : const Color(0xFF15803D),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace')),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.copy,
                  color:
                      _isDarkMode ? Colors.orange : const Color(0xFFC2410C),
                  size: 22),
              onPressed: () {
                // Copy password to clipboard
                Clipboard.setData(ClipboardData(text: password));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Contraseña copiada: $password"),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              tooltip: "Copiar contraseña",
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("MI PERFIL",
              style: TextStyle(
                  color: _isDarkMode ? Colors.orange : const Color(0xFFC2410C),
                  fontWeight: FontWeight.bold,
                  fontSize: 20)),
          const SizedBox(height: 15),
          _buildSettTextField(_firstNameController, "Nombre"),
          _buildSettTextField(_lastNameController, "Apellido"),
          _buildSettTextField(_userEmpNoController, "No. Empleado"),
          _buildSettTextField(
              _recoveryEmailController, "Correo de Recuperación",
              hint: "Para restablecer contraseña"),
          Divider(
              color: _isDarkMode ? Colors.white24 : const Color(0xFFCBD5E1),
              height: 40),
          Text("AJUSTES DE NÓMINA",
              style: TextStyle(
                  color: _isDarkMode ? Colors.orange : const Color(0xFFC2410C),
                  fontWeight: FontWeight.bold,
                  fontSize: 20)),
          const SizedBox(height: 20),
          _buildSettTextField(_salaryController, "Sueldo Diario Base (Actual)",
              prefix: "\$ "),

          // Show salary history if available
          if (_salaryHistory.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isDarkMode
                    ? Colors.orange.withAlpha(15)
                    : const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: _isDarkMode
                    ? Border.all(color: Colors.orange.withAlpha(50))
                    : Border.all(
                        color: const Color(0xFFFED7AA), width: 1.4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "HISTORIAL DE CAMBIOS DE SUELDO",
                        style: TextStyle(
                          color: _isDarkMode
                              ? Colors.orange
                              : const Color(0xFFC2410C),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      if (_salaryHistory.length > 1)
                        TextButton.icon(
                          onPressed: () => _showClearSalaryHistoryDialog(),
                          icon: Icon(Icons.delete_forever,
                              color: _isDarkMode
                                  ? Colors.redAccent
                                  : const Color(0xFFDC2626),
                              size: 16),
                          label: Text(
                            "BORRAR TODO",
                            style: TextStyle(
                                color: _isDarkMode
                                    ? Colors.redAccent
                                    : const Color(0xFFDC2626),
                                fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._salaryHistory.asMap().entries.map((entry) {
                    final index = entry.key;
                    final historyEntry = entry.value;
                    final date = DateTime.parse(
                        historyEntry['effective_date'] as String);
                    final salary = (historyEntry['salary'] as num).toDouble();
                    final prevSalary = historyEntry['previous_salary'] != null
                        ? (historyEntry['previous_salary'] as num).toDouble()
                        : null;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Desde: ${DateFormat('dd/MM/yyyy').format(date)}",
                                  style: TextStyle(
                                    color: _isDarkMode
                                        ? Colors.white70
                                        : Colors.black,
                                    fontSize: 13,
                                    fontWeight: _isDarkMode
                                        ? FontWeight.normal
                                        : FontWeight.w600,
                                  ),
                                ),
                                if (prevSalary != null)
                                  Text(
                                    "Anterior: \$${prevSalary.toStringAsFixed(2)}",
                                    style: TextStyle(
                                      color: _isDarkMode
                                          ? Colors.white.withAlpha(128)
                                          : Colors.black87,
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                "\$${salary.toStringAsFixed(2)}",
                                style: TextStyle(
                                  color: _isDarkMode
                                      ? Colors.greenAccent
                                      : const Color(0xFF15803D),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Delete button for individual entry (except the first/original)
                              if (index > 0 || _salaryHistory.length > 1)
                                IconButton(
                                  icon: Icon(Icons.delete_outline,
                                      color: _isDarkMode
                                          ? Colors.redAccent
                                          : const Color(0xFFDC2626),
                                      size: 20),
                                  onPressed: () =>
                                      _showDeleteSalaryEntryDialog(index),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  tooltip: "Eliminar este cambio",
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          _buildSettTextField(
              _baseHoursController, "Horas Base Diarias (Jornada)",
              suffix: " hrs"),
          _buildSettTextField(_retentionController, "Retención I.S.R. (%)",
              suffix: "%"),
          _buildSettTextField(_fomentoController, "Fomento Eficiencia (%)",
              suffix: "%"),
          _buildSettTextField(_cuotaController, "Cuota Sindical (%)",
              suffix: "%"),
          const SizedBox(height: 20),
          OutlinedButton(
              style: OutlinedButton.styleFrom(
                  backgroundColor:
                      _isDarkMode ? Colors.transparent : Colors.white,
                  side: BorderSide(
                      color: _isDarkMode
                          ? Colors.blueAccent
                          : const Color(0xFF2563EB),
                      width: 1.5),
                  minimumSize: const Size(double.infinity, 50)),
              onPressed: _showInfoDialog,
              child: Text("INFORMACIÓN",
                  style: TextStyle(
                      color: _isDarkMode
                          ? Colors.blueAccent
                          : const Color(0xFF1D4ED8),
                      fontWeight: FontWeight.bold))),
          const SizedBox(height: 25),
          Divider(
              color: _isDarkMode ? Colors.white24 : const Color(0xFFCBD5E1)),
          const SizedBox(height: 25),
          Text("MIGRACIÓN DE DATOS",
              style: TextStyle(
                  color: _isDarkMode ? Colors.orange : const Color(0xFFC2410C),
                  fontWeight: FontWeight.bold,
                  fontSize: 20)),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _exportData,
                  icon: Icon(Icons.upload_file,
                      color: _isDarkMode
                          ? Colors.green
                          : const Color(0xFF15803D)),
                  label: Text("EXPORTAR",
                      style: TextStyle(
                          color: _isDarkMode
                              ? Colors.green
                              : const Color(0xFF15803D),
                          fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                      backgroundColor:
                          _isDarkMode ? Colors.transparent : Colors.white,
                      side: BorderSide(
                          color: _isDarkMode
                              ? Colors.green
                              : const Color(0xFF16A34A),
                          width: 1.5)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _importData,
                  icon: Icon(Icons.download,
                      color: _isDarkMode
                          ? Colors.blue
                          : const Color(0xFF1D4ED8)),
                  label: Text("IMPORTAR",
                      style: TextStyle(
                          color: _isDarkMode
                              ? Colors.blue
                              : const Color(0xFF1D4ED8),
                          fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                      backgroundColor:
                          _isDarkMode ? Colors.transparent : Colors.white,
                      side: BorderSide(
                          color: _isDarkMode
                              ? Colors.blue
                              : const Color(0xFF2563EB),
                          width: 1.5)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildButton("CAMBIAR CONTRASEÑA",
              _isDarkMode ? Colors.orangeAccent : const Color(0xFFEA580C), () {
            _showChangePasswordDialog();
          }),
          const SizedBox(height: 12),
          _buildButton("RECUPERAR CONTRASEÑA",
              _isDarkMode ? Colors.blueAccent : const Color(0xFF2563EB), () {
            _showForgotPasswordFromSettingsDialog();
          }),
          const SizedBox(height: 30),
          _buildButton("CERRAR SESIÓN",
              _isDarkMode ? Colors.redAccent : const Color(0xFFDC2626), () {
            _confirmSignOut(context);
          }),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          scrollable: true,
          backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
          title: Text(
            "¿Cerrar sesión?",
            style: TextStyle(
                color: _isDarkMode ? Colors.orange : const Color(0xFFC2410C),
                fontWeight: FontWeight.bold),
          ),
          content: Text(
            "¿Estás seguro de que deseas cerrar sesión?",
            style: TextStyle(
                color: _isDarkMode ? Colors.white : const Color(0xFF1E293B)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                "Cancelar",
                style: TextStyle(
                    color: _isDarkMode
                        ? Colors.white54
                        : const Color(0xFF64748B)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isDarkMode ? Colors.redAccent : const Color(0xFFDC2626),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                FirebaseAuth.instance.signOut();
              },
              child: const Text(
                "Cerrar sesión",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showChangelogDialog() {
    final currentVersion = _getLatestVersion();
    final lastSeen = _lastSeenVersion ?? "0.0.0";

    List<String> versionsToShow = _changelogByVersion.keys
        .where((v) => _compareVersions(v, lastSeen) > 0)
        .toList();

    if (versionsToShow.isEmpty) {
      versionsToShow = _changelogByVersion.keys.toList();
    }

    versionsToShow.sort((a, b) => _compareVersions(b, a));

    showModalBottomSheet(
      context: context,
      backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.new_releases,
                          color: _isDarkMode ? Colors.orange : const Color(0xFFC2410C),
                          size: 24),
                      const SizedBox(width: 8),
                      Text(
                        "Novedades",
                        style: TextStyle(
                          color: _isDarkMode ? Colors.orange : const Color(0xFFC2410C),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close,
                        color: _isDarkMode ? Colors.white54 : Colors.black54),
                    onPressed: () => Navigator.pop(sheetContext),
                  ),
                ],
              ),
              Divider(color: _isDarkMode ? Colors.white24 : const Color(0xFFCBD5E1)),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: versionsToShow.length,
                  itemBuilder: (context, index) {
                    final ver = versionsToShow[index];
                    final notes = _changelogByVersion[ver] ?? [];
                    final verTitle = _changelogTitles[ver] ?? "Versión $ver";
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            verTitle,
                            style: TextStyle(
                              color: _isDarkMode ? Colors.orangeAccent : const Color(0xFFC2410C),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...notes.map(
                            (note) {
                              final colonIndex = note.indexOf(':');
                              final hasColon = colonIndex != -1;
                              final titlePart = hasColon ? note.substring(0, colonIndex + 1) : '';
                              final bodyPart = hasColon ? note.substring(colonIndex + 1) : note;

                              final trimmed = note.trim();
                              final startsWithAlphanumeric = RegExp(r'^[a-zA-Z0-9]').hasMatch(trimmed);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0, left: 2.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (startsWithAlphanumeric) ...[
                                      Text(
                                        "• ",
                                        style: TextStyle(
                                          color: _isDarkMode ? Colors.orange : const Color(0xFFC2410C),
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                    Expanded(
                                      child: Text.rich(
                                        TextSpan(
                                          children: [
                                            if (hasColon) ...[
                                              TextSpan(
                                                text: titlePart,
                                                style: TextStyle(
                                                  color: _isDarkMode ? Colors.white : Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  height: 1.35,
                                                ),
                                              ),
                                              TextSpan(
                                                text: bodyPart,
                                                style: TextStyle(
                                                  color: _isDarkMode ? Colors.white70 : const Color(0xFF1E293B),
                                                  fontWeight: FontWeight.normal,
                                                  fontSize: 14,
                                                  height: 1.35,
                                                ),
                                              ),
                                            ] else ...[
                                              TextSpan(
                                                text: note,
                                                style: TextStyle(
                                                  color: _isDarkMode ? Colors.white : Colors.black,
                                                  fontSize: 14,
                                                  height: 1.35,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_seen_version', currentVersion);
      if (mounted) {
        setState(() {
          _lastSeenVersion = currentVersion;
        });
      }
    });
  }

  void _showDeleteSalaryEntryDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
      scrollable: true,
        backgroundColor: Colors.grey[900],
        title: const Text("Eliminar Cambio de Sueldo",
            style: TextStyle(
                color: Colors.orange,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        content: const Text(
          "¿Estás seguro de que deseas eliminar este cambio de sueldo? Los registros de trabajo existentes mantendrán sus valores, pero los cálculos futuros usarán el sueldo anterior.",
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text("CANCELAR", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              setState(() {
                _salaryHistory.removeAt(index);
              });
              await _saveData(checkSalaryChange: false);
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Cambio de sueldo eliminado"),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text("ELIMINAR",
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showClearSalaryHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
      scrollable: true,
        backgroundColor: Colors.grey[900],
        title: const Text("Borrar Todo el Historial",
            style: TextStyle(
                color: Colors.redAccent,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        content: const Text(
          "¿Estás seguro de que deseas borrar TODO el historial de cambios de sueldo? Se mantendrá solo el sueldo actual. Esta acción no se puede deshacer.",
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text("CANCELAR", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              setState(() {
                _salaryHistory = [];
              });
              await _saveData(checkSalaryChange: false);
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Historial de sueldos borrado"),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
            child: const Text("BORRAR TODO",
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    bool isLoading = false;

    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
      scrollable: true,
              backgroundColor: Colors.grey[900],
              title: const Column(
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: Colors.orange,
                    size: 48,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Cambiar Contraseña",
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Para cambiar tu contraseña, primero ingresa tu contraseña actual y luego la nueva contraseña.",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: currentPasswordController,
                        obscureText: true,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 18),
                        decoration: const InputDecoration(
                          labelText: "Contraseña Actual",
                          labelStyle: TextStyle(
                            color: Colors.orange,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.orange),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.orange, width: 2),
                          ),
                          prefixIcon: Icon(Icons.lock, color: Colors.orange),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa tu contraseña actual';
                          }
                          if (value.length < 6) {
                            return 'La contraseña debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: newPasswordController,
                        obscureText: true,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 18),
                        decoration: const InputDecoration(
                          labelText: "Nueva Contraseña",
                          labelStyle: TextStyle(
                            color: Colors.orange,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.orange),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.orange, width: 2),
                          ),
                          prefixIcon:
                              Icon(Icons.lock_outline, color: Colors.orange),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa la nueva contraseña';
                          }
                          if (value.length < 6) {
                            return 'La contraseña debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 18),
                        decoration: const InputDecoration(
                          labelText: "Confirmar Nueva Contraseña",
                          labelStyle: TextStyle(
                            color: Colors.orange,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.orange),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.orange, width: 2),
                          ),
                          prefixIcon:
                              Icon(Icons.lock_outline, color: Colors.orange),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Confirma la nueva contraseña';
                          }
                          if (value != newPasswordController.text) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.blueAccent.withAlpha(60)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.blueAccent, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "La nueva contraseña debe tener al menos 6 caracteres. Asegúrate de recordarla para tu próximo inicio de sesión.",
                                style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Forgot password option
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _showForgotPasswordFromSettingsDialog();
                        },
                        icon: const Icon(Icons.help_outline,
                            color: Colors.orangeAccent, size: 18),
                        label: const Text(
                          "¿Olvidaste tu contraseña actual?",
                          style: TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isLoading ? null : () => Navigator.pop(dialogContext),
                  child: const Text(
                    "CANCELAR",
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          setDialogState(() => isLoading = true);

                          try {
                            final user = FirebaseAuth.instance.currentUser;
                            final email = user?.email;

                            if (user == null || email == null) {
                              throw Exception("No hay usuario autenticado");
                            }

                            // Re-authenticate user with current password
                            final credential = EmailAuthProvider.credential(
                              email: email,
                              password: currentPasswordController.text.trim(),
                            );

                            await user.reauthenticateWithCredential(credential);

                            // Update password
                            await user.updatePassword(
                                newPasswordController.text.trim());

                            if (!context.mounted) return;
                            Navigator.pop(dialogContext);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text("Contraseña actualizada exitosamente"),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } on FirebaseAuthException catch (e) {
                            String errorMessage =
                                "Error al cambiar la contraseña";

                            if (e.code == 'wrong-password') {
                              errorMessage =
                                  "La contraseña actual es incorrecta";
                            } else if (e.code == 'weak-password') {
                              errorMessage = "La nueva contraseña es muy débil";
                            } else if (e.code == 'requires-recent-login') {
                              errorMessage =
                                  "Requiere inicio de sesión reciente. Cierra sesión y vuelve a entrar";
                            }

                            setDialogState(() => isLoading = false);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(errorMessage),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } catch (e) {
                            setDialogState(() => isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Error: ${e.toString()}"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "CAMBIAR CONTRASEÑA",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showForgotPasswordFromSettingsDialog() {
    final TextEditingController resetEmailController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
      scrollable: true,
              backgroundColor: Colors.grey[900],
              title: const Column(
                children: [
                  Icon(
                    Icons.lock_reset,
                    color: Colors.orange,
                    size: 48,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Recuperar Contraseña",
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Ingresa el correo de recuperación asociado a tu cuenta. Te enviaremos un enlace para restablecer tu contraseña.",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Email Field
                      TextFormField(
                        controller: resetEmailController,
                        keyboardType: TextInputType.emailAddress,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 18),
                        decoration: const InputDecoration(
                          labelText: "Correo Electrónico",
                          hintText: "El correo que registraste",
                          hintStyle:
                              TextStyle(color: Colors.white30, fontSize: 14),
                          labelStyle: TextStyle(
                            color: Colors.orange,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.orange),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.orange, width: 2),
                          ),
                          prefixIcon: Icon(Icons.email, color: Colors.orange),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu correo';
                          }
                          final emailRegex =
                              RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegex.hasMatch(value)) {
                            return 'Ingresa un correo válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.blueAccent.withAlpha(60)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.blueAccent, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Revisa tu bandeja de entrada y carpeta de spam. El enlace expira en 1 hora.",
                                style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    "CANCELAR",
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          setDialogState(() => isLoading = true);

                          final String email =
                              resetEmailController.text.trim().toLowerCase();
                          final user = FirebaseAuth.instance.currentUser;

                          if (user == null) {
                            setDialogState(() => isLoading = false);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    "No hay usuario autenticado. Inicia sesión nuevamente."),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          try {
                            // Get user document directly by UID (no query needed - avoids permission issues)
                            final userDoc = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .get();

                            if (!userDoc.exists) {
                              setDialogState(() => isLoading = false);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      "No se encontró información de recuperación"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            final userData =
                                userDoc.data() as Map<String, dynamic>;
                            final storedRecoveryEmail =
                                userData['recovery_email'] as String?;

                            if (storedRecoveryEmail == null ||
                                storedRecoveryEmail.isEmpty) {
                              setDialogState(() => isLoading = false);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      "No hay correo de recuperación configurado"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            if (storedRecoveryEmail.toLowerCase().trim() !=
                                email) {
                              setDialogState(() => isLoading = false);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      "El correo no coincide con el registrado"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            // DEBUG: Print what we're about to do
                            debugPrint(
                                'Sending password reset to: $storedRecoveryEmail');
                            debugPrint(
                                'Current user email in Auth: ${user.email}');

                            // NOTE: Firebase Auth can only send password resets to the user's primary email
                            // (the fake @televisa.com email), NOT to alternate/recovery emails stored in Firestore.
                            // The recovery email verification only works if it matches the Firebase Auth email.
                            //
                            // REAL FIX NEEDED: Create a Cloud Function that uses Firebase Admin SDK
                            // to generate a password reset link and send it via custom email to the recovery email.
                            //
                            // For now, we try sending to recovery email but it will only work if user
                            // manually set their Firebase Auth email to match recovery email in Firebase Console.

                            await FirebaseAuth.instance.sendPasswordResetEmail(
                              email: storedRecoveryEmail,
                            );

                            if (!context.mounted) return;
                            Navigator.pop(dialogContext);

                            // Show success dialog inline
                            await showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext successContext) {
                                return AlertDialog(
      scrollable: true,
                                  backgroundColor: Colors.grey[900],
                                  title: const Row(
                                    children: [
                                      Icon(Icons.check_circle,
                                          color: Colors.green, size: 32),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          "¡Enlace Enviado!",
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: Text(
                                    "Se ha enviado un enlace de recuperación a:\n$storedRecoveryEmail\n\nRevisa tu bandeja de entrada (incluyendo spam). El enlace expirará en 1 hora.",
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 14),
                                  ),
                                  actions: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                      ),
                                      onPressed: () =>
                                          Navigator.pop(successContext),
                                      child: const Text(
                                        "ENTENDIDO",
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          } on FirebaseAuthException catch (e) {
                            setDialogState(() => isLoading = false);
                            String errorMessage = "Error al enviar el correo";

                            if (e.code == 'user-not-found') {
                              errorMessage = "No existe cuenta con ese correo";
                            } else if (e.code == 'invalid-email') {
                              errorMessage = "Formato de correo inválido";
                            } else if (e.code == 'too-many-requests') {
                              errorMessage =
                                  "Demasiados intentos. Intenta más tarde";
                            }

                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(errorMessage),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } catch (e) {
                            setDialogState(() => isLoading = false);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Error: ${e.toString()}"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "ENVIAR ENLACE",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
      scrollable: true,
        backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
        title: Text("INFORMACIÓN",
            style: TextStyle(
                color: _isDarkMode ? Colors.orange : const Color(0xFFC2410C),
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Mi Nómina Pro",
                style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            Text("Versión v.23.11.1 13/10/26",
                style: TextStyle(
                    color: _isDarkMode ? Colors.orangeAccent : const Color(0xFFC2410C),
                    fontSize: 14)),
            Divider(
                color: _isDarkMode ? Colors.white38 : const Color(0xFFCBD5E1),
                height: 25),
            Text(
                "Esta aplicación es una herramienta independiente creada con el objetivo de ayudar a los usuarios a estimar y visualizar cierta información de forma práctica.\n\nNo es una aplicación oficial ni está afiliada, respaldada o relacionada de ninguna manera con Televisa.\n\nLas cantidades, cálculos o resultados mostrados son estimaciones generadas con base en la información disponible al momento de su desarrollo. Estos valores pueden contener errores o variaciones, ya que Televisa puede modificar en cualquier momento sus métodos de cálculo, agregar conceptos adicionales o aplicar retenciones distintas sin previo aviso.\n\nPor lo tanto, la información proporcionada por esta aplicación debe considerarse únicamente como una referencia orientativa y no como un dato definitivo, oficial o garantizado.",
                style: TextStyle(
                    color: _isDarkMode ? Colors.white70 : Colors.black87,
                    fontSize: 13)),
            Divider(
                color: _isDarkMode ? Colors.white38 : const Color(0xFFCBD5E1),
                height: 25),
            Text("Desarrollado por: MD",
                style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black,
                    fontSize: 16)),
            const SizedBox(height: 12),
            Text("Sugerencias y/o quejas a: minominapro@gmail.com",
                style: TextStyle(
                    fontSize: 14,
                    color: _isDarkMode ? Colors.white70 : Colors.black87)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CERRAR",
                style: TextStyle(
                    color: _isDarkMode ? Colors.orange : const Color(0xFFC2410C))),
          )
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      Map<String, dynamic> exportData = {
        'salary': _salaryController.text,
        'salary_history': _salaryHistory,
        'base_hours': _baseHoursController.text,
        'retention': _retentionController.text,
        'fomento': _fomentoController.text,
        'cuota': _cuotaController.text,
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'user_emp': _userEmpNoController.text,
        'history': _weeklyHistory.map((e) => e.toJson()).toList(),
      };
      String jsonString = jsonEncode(exportData);
      await Share.share(jsonString, subject: 'Respaldo Datos Televisa');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error al exportar: $e"), backgroundColor: Colors.red));
    }
  }

  Future<void> _importData() async {
    TextEditingController importController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
      scrollable: true,
        backgroundColor: Colors.grey[900],
        title: const Text("Importar Datos",
            style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                "Pega aquí el código que generaste al exportar. Esto SOBREESCRIBIRÁ tus datos actuales.",
                style: TextStyle(color: Colors.white, fontSize: 14)),
            const SizedBox(height: 10),
            TextField(
              controller: importController,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Pega el código aquí...",
                hintStyle: TextStyle(color: Colors.white38),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child:
                const Text("CANCELAR", style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () async {
              try {
                if (importController.text.isEmpty) return;
                Map<String, dynamic> data = jsonDecode(importController.text);

                setState(() {
                  _salaryController.text = data['salary'] ?? "";

                  // Import salary history
                  if (data['salary_history'] != null) {
                    _salaryHistory =
                        List<Map<String, dynamic>>.from(data['salary_history']);
                  }

                  _baseHoursController.text = data['base_hours'] ?? "9.5";
                  _retentionController.text = data['retention'] ?? "15.22";
                  _fomentoController.text = data['fomento'] ?? "2.0";
                  _cuotaController.text = data['cuota'] ?? "2.0";
                  _firstNameController.text = data['first_name'] ?? "";
                  _lastNameController.text = data['last_name'] ?? "";
                  _userEmpNoController.text = data['user_emp'] ?? "";

                  if (data['history'] != null) {
                    Iterable l = data['history'];
                    _weeklyHistory = List<WorkDay>.from(
                        l.map((model) => WorkDay.fromJson(model)));
                    _weeklyHistory
                        .sort((a, b) => b.entrada.compareTo(a.entrada));
                  }
                });
                await _saveData();

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(" Datos importados correctamente"),
                      backgroundColor: Colors.green),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(" Error al importar: Formato inválido"),
                      backgroundColor: Colors.red),
                );
              }
            },
            child:
                const Text("IMPORTAR", style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  Future<void> _startEditingField(String label, TextEditingController controller) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
        title: Text("¿Editar $label?",
            style: TextStyle(
                color: _isDarkMode ? Colors.orange : const Color(0xFFC2410C),
                fontWeight: FontWeight.bold)),
        content: Text("Podrás modificar la información de '$label'.",
            style: TextStyle(
                color: _isDarkMode ? Colors.white : const Color(0xFF1E293B))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text("Cancelar",
                style: TextStyle(
                    color: _isDarkMode
                        ? Colors.white54
                        : const Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isDarkMode ? Colors.orange : const Color(0xFFEA580C)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Sí, editar",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() {
        _originalFieldValues[label] = controller.text;
        _editingFieldLabels.add(label);
      });
    }
  }

  Future<void> _confirmSaveField(String label, TextEditingController controller) async {
    final String originalVal = _originalFieldValues[label] ?? controller.text;
    final bool hasChanged = controller.text != originalVal;

    final String? action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
        title: Text("¿Guardar $label?",
            style: TextStyle(
                color: _isDarkMode ? Colors.orange : const Color(0xFFC2410C),
                fontWeight: FontWeight.bold)),
        content: Text(
          hasChanged
              ? "¿Estás seguro de que deseas guardar la nueva información para '$label'?"
              : "No se detectaron cambios en '$label'. ¿Deseas salir del modo de edición?",
          style: TextStyle(
              color: _isDarkMode ? Colors.white : const Color(0xFF1E293B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop("cancel"),
            child: Text("Cancelar cambios",
                style: TextStyle(
                    color: _isDarkMode
                        ? Colors.redAccent
                        : const Color(0xFFDC2626))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isDarkMode ? Colors.green : const Color(0xFF15803D)),
            onPressed: () => Navigator.of(ctx).pop("save"),
            child: const Text("Guardar",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (action == "cancel" && mounted) {
      setState(() {
        controller.text = originalVal;
        _editingFieldLabels.remove(label);
        _originalFieldValues.remove(label);
      });
    } else if (action == "save" && mounted) {
      setState(() {
        _editingFieldLabels.remove(label);
        _originalFieldValues.remove(label);
      });
      await _saveData();
    }
  }

  Widget _buildSettTextField(TextEditingController controller, String label,
      {String? prefix, String? suffix, String? hint}) {
    final bool isEditing = _editingFieldLabels.contains(label);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        readOnly: !isEditing,
        style: TextStyle(
          color: _isDarkMode
              ? (isEditing ? Colors.white : Colors.white70)
              : Colors.black,
          fontSize: 18,
          fontWeight: _isDarkMode
              ? (isEditing ? FontWeight.bold : FontWeight.normal)
              : FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(
              color: _isDarkMode ? Colors.white30 : const Color(0xFF94A3B8),
              fontSize: 14),
          labelStyle: TextStyle(
              color: _isDarkMode ? Colors.orange : const Color(0xFFC2410C),
              fontSize: 16,
              fontWeight: FontWeight.bold),
          prefixText: prefix,
          prefixStyle: TextStyle(
              color: _isDarkMode ? Colors.white : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold),
          suffixText: suffix,
          suffixStyle: TextStyle(
              color: _isDarkMode ? Colors.white : Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold),
          helperText: isEditing
              ? "Los cambios no se aplicarán hasta que los guardes"
              : null,
          helperStyle: TextStyle(
              color: _isDarkMode
                  ? Colors.orangeAccent
                  : const Color(0xFFEA580C),
              fontSize: 12),
          suffixIcon: IconButton(
            icon: Icon(
              isEditing ? Icons.check_circle : Icons.edit,
              color: isEditing
                  ? (_isDarkMode ? Colors.greenAccent : const Color(0xFF15803D))
                  : (_isDarkMode ? Colors.orange : const Color(0xFFC2410C)),
              size: 22,
            ),
            tooltip: isEditing ? "Guardar cambios" : "Editar campo",
            onPressed: () {
              if (isEditing) {
                _confirmSaveField(label, controller);
              } else {
                _startEditingField(label, controller);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _statDetail(String label, String breakdown, String total,
      {bool isMoney = false}) {
    return Expanded(
        child: Column(
            crossAxisAlignment:
                isMoney ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
          Text(label,
              style: TextStyle(
                  color: _isDarkMode ? Colors.white60 : Colors.black87,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
          Text(breakdown,
              style: TextStyle(
                  color: _isDarkMode ? Colors.white : Colors.black,
                  fontSize: 13)),
          Text(total,
              style: TextStyle(
                  color: isMoney
                      ? (_isDarkMode ? Colors.greenAccent : const Color(0xFF2E7D32))
                      : (_isDarkMode ? Colors.white : Colors.black),
                  fontSize: 18,
                  fontWeight: FontWeight.w900))
        ]));
  }

  Future<TimeOfDay?> _showScrollTimePicker(
    BuildContext context, {
    required TimeOfDay initialTime,
    String? title,
    bool forceScrollMode = false,
  }) async {
    if (!forceScrollMode) {
      // MODE 1: Unsquished Native Analog Clock (Default)
      bool switchRequested = false;
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: initialTime,
        cancelText: "CANCELAR",
        confirmText: "CONFIRMAR",
        helpText: title ?? "SELECCIONAR HORA",
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Colors.orange,
                onPrimary: Colors.black,
                surface: Color(0xFF1E1E1E),
                onSurface: Colors.white,
              ),
              timePickerTheme: const TimePickerThemeData(
                backgroundColor: Color(0xFF1E1E1E),
                hourMinuteTextColor: Colors.orange,
                hourMinuteColor: Color(0xFF2C2C2C),
                dialHandColor: Colors.orange,
                dialBackgroundColor: Color(0xFF2C2C2C),
                dialTextColor: Colors.white,
                entryModeIconColor: Colors.orangeAccent,
              ),
            ),
            child: Stack(
              children: [
                child!,
                Positioned(
                  top: 14,
                  right: 14,
                  child: IconButton(
                    icon: const Icon(Icons.unfold_more_rounded,
                        color: Colors.orangeAccent, size: 24),
                    tooltip: "Cambiar a Rodillo",
                    onPressed: () {
                      switchRequested = true;
                      Navigator.pop(context, null);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );

      if (switchRequested) {
        if (!context.mounted) return null;
        return await _showScrollTimePicker(
          context,
          initialTime: initialTime,
          title: title,
          forceScrollMode: true,
        );
      }
      return picked;
    }

    // MODE 2: Cupertino Vertical Scroll Wheel
    DateTime now = DateTime.now();
    DateTime selectedDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      initialTime.hour,
      initialTime.minute,
    );
    bool switchRequested = false;

    final TimeOfDay? result = await showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext builderContext) {
        return Container(
          height: 310,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Responsive Header Bar
              Row(
                children: [
                  // CANCELAR
                  Flexible(
                    fit: FlexFit.loose,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => Navigator.pop(builderContext, null),
                        child: const Text(
                          "CANCELAR",
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // TITLE
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        title ?? "SELECCIONAR HORA",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // SWITCH TO ANALOG CLOCK BUTTON
                  IconButton(
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(
                      Icons.access_time_filled,
                      color: Colors.orangeAccent,
                      size: 22,
                    ),
                    tooltip: "Cambiar a Reloj Análogo",
                    onPressed: () {
                      switchRequested = true;
                      Navigator.pop(builderContext, null);
                    },
                  ),
                  const SizedBox(width: 4),
                  // CONFIRMAR
                  Flexible(
                    fit: FlexFit.loose,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => Navigator.pop(
                            builderContext,
                            TimeOfDay(
                                hour: selectedDateTime.hour,
                                minute: selectedDateTime.minute)),
                        child: const Text(
                          "CONFIRMAR",
                          style: TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white24, height: 14),
              // Cupertino Scroll Wheel
              Expanded(
                child: CupertinoTheme(
                  data: const CupertinoThemeData(
                    brightness: Brightness.dark,
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: selectedDateTime,
                    use24hFormat: false,
                    onDateTimeChanged: (DateTime newDate) {
                      selectedDateTime = newDate;
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (switchRequested) {
      if (!context.mounted) return null;
      return await _showScrollTimePicker(
        context,
        initialTime: initialTime,
        title: title,
        forceScrollMode: false,
      );
    }
    return result;
  }

  Widget _buildNotesSection(WorkDay day, {BuildContext? dialogContext}) {
    final BuildContext ctx = dialogContext ?? context;
    if (day.notas.isNotEmpty) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isDarkMode
              ? Colors.orange.withAlpha(25)
              : const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: _isDarkMode
                  ? Colors.orangeAccent.withAlpha(100)
                  : const Color(0xFFFCD34D),
              width: _isDarkMode ? 1.0 : 1.4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.note_alt_outlined,
                        color: _isDarkMode
                            ? Colors.orangeAccent
                            : const Color(0xFFD97706),
                        size: 16),
                    const SizedBox(width: 6),
                    Text("NOTAS:",
                        style: TextStyle(
                            color: _isDarkMode
                                ? Colors.orangeAccent
                                : const Color(0xFF334155),
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ],
                ),
                InkWell(
                  onTap: () async {
                    final String? newNotes = await _promptForNotes(ctx,
                        initialNotes: day.notas);
                    if (newNotes != null) {
                      setState(() {
                        day.notas = newNotes;
                      });
                      await _userHistory.doc(day.id).set(day.toJson());
                      await _saveData();
                    }
                  },
                  child: Text("Editar",
                      style: TextStyle(
                          color: _isDarkMode
                              ? Colors.orangeAccent
                              : const Color(0xFFB45309),
                          fontSize: 12,
                          decoration: TextDecoration.underline)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(day.notas,
                style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isDarkMode
                  ? Colors.orange.withAlpha(25)
                  : const Color(0xFFFEF3C7),
              foregroundColor: _isDarkMode
                  ? Colors.orangeAccent
                  : const Color(0xFF78350F),
              elevation: _isDarkMode ? 0 : 1,
              side: BorderSide(
                color: _isDarkMode
                    ? Colors.orangeAccent.withAlpha(120)
                    : const Color(0xFFD97706),
                width: _isDarkMode ? 1.2 : 1.5,
              ),
              minimumSize: const Size(double.infinity, 48),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.note_add_outlined, size: 20),
            label: const Text(
              "Agregar notas",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () async {
              final String? newNotes =
                  await _promptForNotes(ctx, initialNotes: "");
              if (newNotes != null && newNotes.isNotEmpty) {
                setState(() {
                  day.notas = newNotes;
                });
                await _userHistory.doc(day.id).set(day.toJson());
                await _saveData();
              }
            },
          ),
        ),
      );
    }
  }

  Future<String?> _promptForNotes(BuildContext context,
      {String initialNotes = ""}) async {
    TextEditingController notesController =
        TextEditingController(text: initialNotes);
    return await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          scrollable: true,
          backgroundColor:
              _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.note_alt_outlined,
                  color: _isDarkMode
                      ? Colors.orangeAccent
                      : const Color(0xFFD9531E)),
              const SizedBox(width: 8),
              Text("Notas del registro",
                  style: TextStyle(
                      color: _isDarkMode
                          ? Colors.white
                          : const Color(0xFF111827),
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "¿Deseas agregar notas a este registro?",
                style: TextStyle(
                    color: _isDarkMode
                        ? Colors.white70
                        : const Color(0xFF4B5563),
                    fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 3,
                style: TextStyle(
                    color: _isDarkMode
                        ? Colors.white
                        : const Color(0xFF111827)),
                decoration: InputDecoration(
                  hintText:
                      "Escribe tus notas aquí (ej. Guardia, Turno especial, etc.)...",
                  hintStyle: TextStyle(
                      color: _isDarkMode
                          ? Colors.white38
                          : const Color(0xFF9CA3AF),
                      fontSize: 13),
                  filled: true,
                  fillColor: _isDarkMode
                      ? const Color(0xFF2C2C2C)
                      : const Color(0xFFF3F4F6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color: _isDarkMode
                            ? Colors.transparent
                            : const Color(0xFFD1D5DB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color: _isDarkMode
                            ? Colors.transparent
                            : const Color(0xFFD1D5DB)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, initialNotes),
              child: Text("OMITIR",
                  style: TextStyle(
                      color: _isDarkMode
                          ? Colors.white54
                          : const Color(0xFF6B7280),
                      fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isDarkMode ? Colors.orange : const Color(0xFFD9531E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () =>
                  Navigator.pop(context, notesController.text.trim()),
              child: const Text("GUARDAR NOTAS",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showManualDayDialog(DateTime date) {
    // Check if we already have data for this specific date
    int existingIndex = _weeklyHistory.indexWhere((d) =>
        d.entrada.year == date.year &&
        d.entrada.month == date.month &&
        d.entrada.day == date.day);

    // Spanish day and month names
    final List<String> daysES = [
      'Lun',
      'Mar',
      'Mié',
      'Jue',
      'Vie',
      'Sáb',
      'Dom'
    ];
    final List<String> monthsES = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic'
    ];

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // If record exists, show detailed view with Edit/Delete
        if (existingIndex != -1) {
          final day = _weeklyHistory[existingIndex];
          final String dateStringES =
              "${daysES[day.entrada.weekday - 1]}, ${day.entrada.day} ${monthsES[day.entrada.month - 1]}";

          // Calculate overtime breakdown for this day
          final int week = _getWeekNumber(day.entrada);
          final List<WorkDay> weekDays = _weeklyHistory
              .where((d) => _getWeekNumber(d.entrada) == week)
              .toList();
          final weeklyOTMap = calculateWeeklyOvertimeBreakdown(weekDays);
          final breakdown = weeklyOTMap[day] ?? OvertimeBreakdown();
          final double realExtrasPay = breakdown.totalPay;

          bool startedOnWeekend = day.entrada.weekday == DateTime.saturday ||
              day.entrada.weekday == DateTime.sunday;
          double normalHrs =
              day.totalHours > day.baseHours ? day.baseHours : day.totalHours;

          return AlertDialog(
      scrollable: true,
            backgroundColor: Colors.grey[900],
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dateStringES,
                    style: TextStyle(
                        color: startedOnWeekend
                            ? Colors.yellowAccent
                            : Colors.orange,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    // EDIT BUTTON (Modifies existing clock-in, clock-out, and notes)
                    IconButton(
                      icon: const Icon(Icons.edit,
                          color: Colors.blueAccent, size: 24),
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        _editExistingWorkDay(existingIndex);
                      },
                    ),
                    // DELETE BUTTON
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.redAccent, size: 24),
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        _showDeleteDialog(existingIndex);
                      },
                    ),
                  ],
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (day.esFalta) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(40),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.redAccent),
                      ),
                      child: const Text(
                        "FALTA / NO LABORADO",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ] else if (day.esVacaciones) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withAlpha(40),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amberAccent),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star, color: Colors.amberAccent, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "VACACIONES",
                            style: TextStyle(
                              color: Colors.amberAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amberAccent.withAlpha(100)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("VACACIONES - PAGO BASE COMPLETO",
                              style: TextStyle(
                                  color: Colors.amberAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                              "Pago base: \$${day.dailyPay.toStringAsFixed(2)} | Sin descuento ni horas extra",
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                  ] else if (day.esFestivo && !day.festivoTrabajado) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.withAlpha(40),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.purpleAccent),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star, color: Colors.purpleAccent, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "DÍA FESTIVO (NO LABORADO)",
                            style: TextStyle(
                              color: Colors.purpleAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.purpleAccent.withAlpha(100)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("DÍA FESTIVO - PAGO BASE COMPLETO",
                              style: TextStyle(
                                  color: Colors.purpleAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                              "Pago base: \$${day.dailyPay.toStringAsFixed(2)} | Sin descuento ni horas extra",
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                  ] else if (day.esMantenimiento) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha(40),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blueAccent),
                      ),
                      child: const Text(
                        "DÍA DE MANTENIMIENTO",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Times section for mantenimiento
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Entrada: ${DateFormat('hh:mm a').format(day.entrada)}",
                                style: const TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                "Salida: ${DateFormat('hh:mm a').format(day.salida)}",
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          if (day.entradaReal != null &&
                              day.entradaReal != day.entrada)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                "Registro Real: ${DateFormat('hh:mm a').format(day.entradaReal!)} ${day.entradaReal!.isBefore(day.entrada) ? '(Temprano)' : '(Tarde)'}",
                                style: TextStyle(
                                  color: day.entradaReal!.isBefore(day.entrada)
                                      ? Colors.greenAccent
                                      : Colors.yellowAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: Colors.blueAccent.withAlpha(100)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("MANTENIMIENTO - SIN HORAS EXTRA",
                              style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                              "Jornada: ${day.totalHours.toStringAsFixed(2)} hrs | Pago base: \$${day.dailyPay.toStringAsFixed(2)}",
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Times section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Entrada: ${DateFormat('hh:mm a').format(day.entrada)}",
                                style: const TextStyle(
                                  color: Colors.orangeAccent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                "Salida: ${DateFormat('hh:mm a').format(day.salida)}",
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          if (day.entradaReal != null &&
                              day.entradaReal != day.entrada)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                "Registro Real: ${DateFormat('hh:mm a').format(day.entradaReal!)} ${day.entradaReal!.isBefore(day.entrada) ? '(Temprano)' : '(Tarde)'}",
                                style: TextStyle(
                                  color: day.entradaReal!.isBefore(day.entrada)
                                      ? Colors.greenAccent
                                      : Colors.yellowAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          if (day.isOvernight)
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withAlpha(60),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                "SALIDA DÍA SIGUIENTE",
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 12),
                    // Hours breakdown
                    Row(
                      children: [
                        if (day.esFestivo && day.festivoTrabajado)
                          _statDetail(
                            "HORAS",
                            "${normalHrs.toStringAsFixed(1)}h Base\n${day.holidayExtraHours.toStringAsFixed(2)}h Extra",
                            "${day.totalHours.toStringAsFixed(2)} hrs totales",
                          )
                        else
                          _statDetail(
                            "HORAS",
                            "${normalHrs.toStringAsFixed(1)}h Base\n${day.extraHoursCount.toStringAsFixed(2)}h Extra",
                            "${day.totalHours.toStringAsFixed(2)} hrs totales",
                          ),
                        if (day.esFestivo && day.festivoTrabajado)
                          _statDetail(
                            "PAGO",
                            "\$${day.sueldoBase.toStringAsFixed(2)} × 2 (Base)\n\$${day.holidayExtrasPay.toStringAsFixed(2)} (Extras 3×)",
                            "\$${day.totalPay.toStringAsFixed(2)}",
                            isMoney: true,
                          )
                        else
                          _statDetail(
                            "PAGO",
                            "\$${day.dailyPay.toStringAsFixed(2)} Base\n2× ${breakdown.hours2x.toStringAsFixed(2)}h  \$${breakdown.pay2x.toStringAsFixed(2)}\n3× ${breakdown.hours3x.toStringAsFixed(2)}h  \$${breakdown.pay3x.toStringAsFixed(2)}",
                            "\$${(day.dailyPay + realExtrasPay).toStringAsFixed(2)}",
                            isMoney: true,
                          ),
                      ],
                    ),
                  ],
                  // Notes Section
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white24),
                  _buildNotesSection(day, dialogContext: dialogContext),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text("CERRAR",
                    style: TextStyle(color: Colors.white70)),
              ),
            ],
          );
        }

        // No record exists - show creation options
        return AlertDialog(
      scrollable: true,
          backgroundColor: Colors.grey[900],
          title: Text("Registrar: ${DateFormat('d MMM').format(date)}",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildButton("ASISTENCIA", Colors.green, () {
                Navigator.pop(dialogContext);
                _pickTimeForWorkDay(date);
              }),
              const SizedBox(height: 10),
              _buildButton("DÍA DE MANTENIMIENTO", Colors.blue, () async {
                Navigator.pop(dialogContext);
                // Ask for clock-in time
                final TimeOfDay? inTime = await _showScrollTimePicker(
                  context,
                  initialTime: const TimeOfDay(hour: 8, minute: 0),
                  title: "¿A QUÉ HORA ENTRASTE?",
                );
                if (!mounted || inTime == null) return;

                // Calculate clock-out based on base hours
                double baseHrs =
                    double.tryParse(_baseHoursController.text) ?? 9.5;
                int baseMinutes = (baseHrs * 60).round();

                DateTime entrada = DateTime(date.year, date.month, date.day,
                    inTime.hour, inTime.minute);
                DateTime salida = entrada.add(Duration(minutes: baseMinutes));

                // Optional notes
                final String? notes = await _promptForNotes(context);

                // Get the correct salary for the entry date
                final double salaryForDate = _getSalaryForDate(entrada);

                _addAndSortHistory(WorkDay(
                    entrada: entrada,
                    salida: salida,
                    entradaReal: entrada,
                    sueldoBase: salaryForDate,
                    baseHours: baseHrs,
                    notas: notes ?? "",
                    esMantenimiento: true));
              }),
              const SizedBox(height: 10),
              _buildButton("VACACIONES", Colors.lightGreen.shade700, () async {
                Navigator.pop(dialogContext);
                DateTime noon =
                    DateTime(date.year, date.month, date.day, 12, 0);
                final String? notes = await _promptForNotes(context);
                final double salaryForDate = _getSalaryForDate(noon);

                _addAndSortHistory(WorkDay(
                    entrada: noon,
                    salida: noon,
                    sueldoBase: salaryForDate,
                    baseHours:
                        double.tryParse(_baseHoursController.text) ?? 9.5,
                    notas: notes ?? "",
                    esVacaciones: true));
              }),
              const SizedBox(height: 10),
              _buildButton("FESTIVO NO LABORADO", Colors.purple.shade400, () async {
                Navigator.pop(dialogContext);
                DateTime noon =
                    DateTime(date.year, date.month, date.day, 12, 0);
                final String? notes = await _promptForNotes(context);
                final double salaryForDate = _getSalaryForDate(noon);

                _addAndSortHistory(WorkDay(
                    entrada: noon,
                    salida: noon,
                    sueldoBase: salaryForDate,
                    baseHours:
                        double.tryParse(_baseHoursController.text) ?? 9.5,
                    notas: notes ?? "",
                    esFestivo: true,
                    festivoTrabajado: false));
              }),
              const SizedBox(height: 10),
              _buildButton("FESTIVO LABORADO", Colors.purple.shade700, () async {
                Navigator.pop(dialogContext);
                final TimeOfDay? inTime = await _showScrollTimePicker(
                    context,
                    initialTime: const TimeOfDay(hour: 8, minute: 0),
                    title: "HORA ENTRADA");
                if (!mounted || inTime == null) return;
                final TimeOfDay? outTime = await _showScrollTimePicker(
                    context,
                    initialTime: const TimeOfDay(hour: 18, minute: 0),
                    title: "HORA SALIDA");
                if (!mounted || outTime == null) return;

                final String? notes = await _promptForNotes(context);

                DateTime fEntrada = DateTime(date.year, date.month, date.day,
                    inTime.hour, inTime.minute);
                DateTime fSalida = DateTime(date.year, date.month, date.day,
                    outTime.hour, outTime.minute);
                if (fSalida.isBefore(fEntrada)) {
                  fSalida = fSalida.add(const Duration(days: 1));
                }

                final double salaryForDate = _getSalaryForDate(fEntrada);

                _addAndSortHistory(WorkDay(
                    entrada: fEntrada,
                    salida: fSalida,
                    entradaReal: fEntrada,
                    sueldoBase: salaryForDate,
                    baseHours:
                        double.tryParse(_baseHoursController.text) ?? 9.5,
                    notas: notes ?? "",
                    esFestivo: true,
                    festivoTrabajado: true));
              }),
              const SizedBox(height: 10),
              _buildButton("NO LABORÉ HOY", Colors.red, () {
                Navigator.pop(dialogContext);
                DateTime noon =
                    DateTime(date.year, date.month, date.day, 12, 0);
                // Get the correct salary for the entry date
                final double salaryForDate = _getSalaryForDate(noon);

                _addAndSortHistory(WorkDay(
                    entrada: noon,
                    salida: noon,
                    sueldoBase: salaryForDate,
                    baseHours:
                        double.tryParse(_baseHoursController.text) ?? 9.5,
                    esFalta: true));
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editExistingWorkDay(int existingIndex) async {
    if (existingIndex < 0 || existingIndex >= _weeklyHistory.length) return;
    WorkDay day = _weeklyHistory[existingIndex];

    if (day.esVacaciones || day.esFalta || (day.esFestivo && !day.festivoTrabajado)) {
      final String? updatedNotes =
          await _promptForNotes(context, initialNotes: day.notas);
      if (!mounted) return;
      setState(() {
        day.notas = updatedNotes ?? day.notas;
      });
      await _userHistory.doc(day.id).set(day.toJson());
      await _saveData();
      _syncTodayStateFromHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Notas actualizadas exitosamente"),
          backgroundColor: Colors.green,
        ));
      }
      return;
    }

    if (day.isInProgress) {
      final TimeOfDay? inTime = await _showScrollTimePicker(
        context,
        initialTime: TimeOfDay.fromDateTime(day.entrada),
        title: "EDITAR HORA ENTRADA",
      );
      if (!mounted || inTime == null) return;
      final String? updatedNotes =
          await _promptForNotes(context, initialNotes: day.notas);
      if (!mounted) return;
      DateTime date = day.entrada;
      DateTime fEntrada =
          DateTime(date.year, date.month, date.day, inTime.hour, inTime.minute);
      setState(() {
        day.entrada = fEntrada;
        day.entradaReal = fEntrada;
        day.notas = updatedNotes ?? day.notas;
      });
      await _userHistory.doc(day.id).set(day.toJson());
      await _saveData();
      _syncTodayStateFromHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Turno en progreso actualizado"),
          backgroundColor: Colors.green,
        ));
      }
      return;
    }

    // Step 1: Pick updated entrance time (pre-filled)
    final TimeOfDay? inTime = await _showScrollTimePicker(
      context,
      initialTime: TimeOfDay.fromDateTime(day.entrada),
      title: "EDITAR HORA ENTRADA",
    );
    if (!mounted || inTime == null) return;

    // Step 2: Pick updated exit time (pre-filled)
    final TimeOfDay? outTime = await _showScrollTimePicker(
      context,
      initialTime: TimeOfDay.fromDateTime(day.salida),
      title: "EDITAR HORA SALIDA",
    );
    if (!mounted || outTime == null) return;

    // Step 3: Prompt for notes (pre-filled with existing notes)
    final String? updatedNotes =
        await _promptForNotes(context, initialNotes: day.notas);

    DateTime date = day.entrada;
    DateTime fEntrada =
        DateTime(date.year, date.month, date.day, inTime.hour, inTime.minute);
    DateTime fSalida =
        DateTime(date.year, date.month, date.day, outTime.hour, outTime.minute);
    if (fSalida.isBefore(fEntrada)) {
      fSalida = fSalida.add(const Duration(days: 1));
    }

    setState(() {
      day.entrada = fEntrada;
      day.salida = fSalida;
      day.entradaReal = fEntrada;
      day.notas = updatedNotes ?? day.notas;
      day.esFalta = false;
    });

    await _userHistory.doc(day.id).set(day.toJson());
    await _saveData();
    _syncTodayStateFromHistory();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Registro actualizado exitosamente"),
        backgroundColor: Colors.green,
      ));
    }
  }

  Future<void> _pickTimeForWorkDay(DateTime date, {bool isFestivo = false}) async {
    final TimeOfDay? inTime = await _showScrollTimePicker(
        context,
        initialTime: const TimeOfDay(hour: 8, minute: 0),
        title: "HORA ENTRADA");
    if (!mounted || inTime == null) return;
    final TimeOfDay? outTime = await _showScrollTimePicker(
        context,
        initialTime: const TimeOfDay(hour: 18, minute: 0),
        title: "HORA SALIDA");
    if (!mounted || outTime == null) return;

    // Prompt for notes with Skip / Save option
    final String? notes = await _promptForNotes(context);

    DateTime fEntrada =
        DateTime(date.year, date.month, date.day, inTime.hour, inTime.minute);
    DateTime fSalida =
        DateTime(date.year, date.month, date.day, outTime.hour, outTime.minute);
    if (fSalida.isBefore(fEntrada)) {
      fSalida = fSalida.add(const Duration(days: 1));
    }

    // Get the correct salary for the entry date
    final double salaryForDate = _getSalaryForDate(fEntrada);

    _addAndSortHistory(WorkDay(
        entrada: fEntrada,
        salida: fSalida,
        entradaReal: fEntrada,
        sueldoBase: salaryForDate,
        baseHours: double.tryParse(_baseHoursController.text) ?? 9.5,
        notas: notes ?? "",
        esFestivo: isFestivo,
        festivoTrabajado: isFestivo,
        esFalta: false));
  }

  Widget _confirmRow(String label, String val) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: TextStyle(
                color: _isDarkMode
                    ? Colors.white70
                    : Colors.black87,
                fontSize: 14)),
        Text(val,
            style: TextStyle(
                color: _isDarkMode
                    ? Colors.white
                    : Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold))
      ]);
  void _showDeleteDialog(int index) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
      scrollable: true,
              backgroundColor: Colors.grey[900],
              title: const Text("¿Borrar registro?",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("NO")),
                TextButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);
                      final dayToDelete = _weeklyHistory[index];
                      final bool isCurrentShift = dayToDelete.id == _currentShiftId ||
                          dayToDelete.isInProgress ||
                          (_entradaDateTime != null && dayToDelete.entrada == _entradaDateTime) ||
                          (dayToDelete.entrada.year == DateTime.now().year &&
                              dayToDelete.entrada.month == DateTime.now().month &&
                              dayToDelete.entrada.day == DateTime.now().day);

                      if (isCurrentShift) {
                        _countdownTimer?.cancel();
                      }

                      setState(() {
                        _weeklyHistory.removeAt(index);
                        if (isCurrentShift) {
                          _isClockedIn = false;
                          _completedToday = false;
                          _currentShiftId = null;
                          _entradaDateTime = null;
                          _entradaRealDateTime = null;
                          _salidaDateTime = null;
                          _entradaDisplay = "--/-- --:--";
                          _salidaDisplay = "--/-- --:--";
                          _timeRemainingMessage = "";
                        }
                      });

                      if (isCurrentShift) {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('pending_entrada');
                        await prefs.remove('pending_entrada_real');
                        await prefs.setBool('pending_clocked_in', false);
                      }

                      await _userHistory.doc(dayToDelete.id).delete();
                      await _saveData();
                      navigator.pop();
                      messenger.showSnackBar(const SnackBar(
                          content: Text(" Registro eliminado"),
                          backgroundColor: Colors.redAccent));
                    },
                    child:
                        const Text("SÍ", style: TextStyle(color: Colors.red)))
              ]);
        });
  }


  Widget _buildButton(String text, Color color, VoidCallback? onPressed, {bool isCompact = false}) {
    // If the app is uploading, we force the button to be disabled (null)
    final bool isDisabled = onPressed == null || _isProcessing;

    return ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: isDisabled
                ? (_isDarkMode ? Colors.grey.shade800 : const Color(0xFFD1D5DB))
                : color,
            minimumSize: Size(double.infinity, isCompact ? 50 : 70),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))),
        onPressed: isDisabled ? null : onPressed,
        child: _isProcessing && onPressed != null
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 3))
            : Text(text,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: isCompact ? 14 : 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)));
  }
}
