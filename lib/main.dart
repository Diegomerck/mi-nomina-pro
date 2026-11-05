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
import 'dart:math' as math;
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'web_reload_stub.dart' if (dart.library.html) 'web_reload.dart';

part 'screens/login_screen.dart';
part 'widgets/edit_work_day_dialog.dart';
part 'screens/unit_share_screen.dart';
part 'screens/history_screens.dart';
part 'screens/admin_screens.dart';
part 'tabs/hoy_tab.dart';
part 'tabs/quincena_tab.dart';
part 'tabs/ano_tab.dart';
part 'tabs/nomina_tab.dart';
part 'tabs/extras_tab.dart';
part 'tabs/settings_tab.dart';
part 'tabs/unit_manager_tab.dart';
part 'tabs/day_dialogs_and_io.dart';

final Map<String, String> _changelogTitles = {
  "23.17.0": "🤝 Versión 23.17.0 (04/11/26) — Modo Sin Conexión, Estado en la Nube y Pantalla Más Cómoda",
  "23.16.0": "🤝 Versión 23.16.0 (03/11/26) — Compartir Horarios, Nómina 2027 y Soporte de Cuenta",
  "23.15.0": "🛠️ Versión 23.15.0 (28/10/26) — Herramientas de Soporte y Fusión de Cuentas",
  "23.14.0": "⏱️ Versión 23.14.0 (27/10/26) — Edición de Turnos Renovada y Mejoras de Rendimiento",
  "23.13.1": "🔑 Versión 23.13.1 (16/10/26) — Acceso con Empleado o Correo y Recuperación",
  "23.12.1": "🎉 Versión 23.12.1 (15/10/26) — Días de Descanso & Historial de Cambios",
  "23.11.1": "☀️ Versión 23.11.1 (13/10/26) — Modo Luz y Pantalla más Clara",
};

final Map<String, List<String>> _changelogByVersion = {
  "23.17.0": [
    "⚡ Úsala sin internet (Modo Fuera de Línea): Ahora puedes registrar tus turnos, entradas y salidas aunque no tengas señal ni internet. Tus datos se guardan en tu celular y se subirán solitos a la nube en cuanto vuelvas a tener conexión.",
    "☁️ Barra de estado de conexión: Nueva barra arriba de la pantalla que te avisa con letras grandes y claras si tus datos ya están respaldados en la nube o si estás sin conexión, junto con la hora exacta del último respaldo. ¡Puedes tocarla cuando quieras para forzar el guardado!",
    "📱 Pantalla Hoy más cómoda y visible: Ajustamos los espacios para que veas toda tu información de un solo vistazo en tu celular sin tener que deslizar la pantalla hacia abajo, con la fecha de hoy en letras grandes y legibles.",
  ],
  "23.16.0": [
    "🤝 Comparte tus horarios con más de una persona: En Ajustes ahora puedes compartir tus entradas y salidas con varios Ingenieros de Unidad al mismo tiempo, configurando permisos por separado para cada uno (tu sueldo y pagos nunca se comparten).",
    "📆 Elige días específicos o semanas completas: Puedes decidir exactamente qué días o qué semanas completas quieres compartir con cada ingeniero desde un calendario rápido, o elegir 'Solo Hoy' cuando trabajes en una unidad por un día.",
    "📅 Adelanto de pagos de 2027: Ya puedes ver cuándo se pagarán tus horas extra de diciembre en las primeras quincenas de enero y febrero de 2027.",
    "🔄 Botón para cambiar entre 2026 y 2027: En las pestañas de Nómina y Año ahora tienes un botón arriba para saltar de un año a otro en un toque.",
    "🎉 Días festivos al triple y mejoras en Modo Claro: Los días festivos trabajados ahora se calculan al triple automáticamente y mejoramos la lectura en pantallas claras y oscuras.",
  ],
  "23.15.0": [
    "🆘 Ayuda del Administrador para recuperar tu cuenta: Si olvidaste con qué correo te registraste o no puedes entrar, el administrador ahora puede consultar tu correo, enviarte un enlace para cambiar tu contraseña o actualizar tu correo registrado.",
    "🔗 Unificación limpia de cuentas duplicadas: Si tenías dos cuentas por error, el administrador puede unir todos tus turnos y ajustes en una sola cuenta limpia y eliminar la cuenta repetida.",
  ],
  "23.14.0": [
    "✨ Nueva ventana unificada para editar turnos: Modifica tu hora de entrada, salida, entrada real y notas en una sola pantalla ágil y moderna.",
    "🛡️ Protección contra cierres accidentales: Si modificas algún dato, la app te pedirá confirmación antes de salir para que nunca pierdas tus cambios.",
    "⚡ Sincronización y rendimiento optimizados: Mejoras en la velocidad de guardado y carga de registros de asistencia.",
  ],
  "23.13.1": [
    "🆔 Inicia con tu número o tu correo: Ahora puedes entrar a tu cuenta usando tu número de empleado o tu correo indistintamente.",
    "✨ Pantalla de acceso renovada: Nuevo diseño de bienvenida, botones más claros y opción para mostrar u ocultar tu contraseña.",
    "🔒 Mensajes de contraseña claros: Si hay un error con tu contraseña, la app te lo indica amablemente y te recuerda que tu cuenta no se bloqueará por múltiples intentos.",
    "🔑 Recuperación directa de contraseña: Nuevo botón en la pantalla de acceso para solicitar el enlace de restablecimiento si olvidaste tu contraseña.",
  ],
  "23.12.1": [
    "📅 Días de descanso a tu medida: Ahora puedes elegir qué días descansas (por ejemplo si descansas entre semana).",
    "💵 Historial de aumentos y jornada: Si te suben el sueldo o cambia tu horario, puedes guardarlo por fecha sin que se alteren tus quincenas anteriores.",
    "⭐ Horas extra en descanso: Si trabajas en tu día de descanso, tus horas extra ahora se pagan al triple automáticamente como marca la ley.",
    "🔍 Desglose más claro: En tus días de descanso laborados verás por separado tu pago base y el pago de tu descanso.",
    "⌨️ Centavos en tu sueldo: El teclado ahora te permite escribir punto decimal fácilmente al ingresar tu salario.",
  ],
  "23.11.1": [
    "☀️ Modo Día: Agregamos un botón para cambiar entre fondo oscuro y fondo claro según tu preferencia.",
    "👁️ Reloj y letras más grandes: La pestaña Hoy ahora tiene números y botones más grandes para que puedas verlos fácil bajo la luz del sol.",
    "⚡ Entrada y salida rápida: Ahora puedes registrar tu marcaje manual en un solo paso.",
    "📝 Notas en turno: Ya puedes anotar detalles de tu jornada sin tener que esperar a finalizarla.",
    "💰 Descuento por faltas: Si faltas en la quincena, el descuento ahora se calcula de forma exacta y sin duplicar cobros.",
  ],
  "23.9.2": [
    "📅 Calendario del Año: Al entrar a la pestaña Año, la pantalla va directo a tu semana actual para que no tengas que buscarla.",
    "🔒 Ajustes protegidos: Ahora puedes editar cada dato con el icono de lápiz y confirmar antes de guardar, evitando cambios por accidente.",
    "✨ Ajustes más limpios: Se quitaron botones innecesarios para que la pantalla sea más sencilla y clara.",
  ],
  "23.9.1": [
    "📱 Mejor vista en tu celular: Los formularios ahora se adaptan bien cuando se abre el teclado, sin tapar lo que estás escribiendo.",
    "📋 Quincena más clara: Diseño más compacto para ver tus semanas y horas extra de un vistazo.",
    "📤 Compartir resumen: Ahora es más fácil y rápido compartir tu reporte semanal por mensaje o correo.",
    "💰 Nómina directa: La pestaña Nómina te muestra directo tu quincena activa sin tener que buscarla.",
    "📶 Redes de Televisa: Seguimos trabajando para que la app funcione directo en las redes internas de la empresa.",
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
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
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

// ---------------------------------------------------------------------------
// CLOUD SYNC STATUS TRACKER
// ---------------------------------------------------------------------------
enum SyncStatus {
  synced,
  syncing,
  offlinePending,
  error,
}

// ---------------------------------------------------------------------------
// ADMIN ROLE DEFINITION & ACCESS CONTROL
// ---------------------------------------------------------------------------
const String kAdminEmail = 'minominapro@gmail.com';
const String kAdminUid = 'RybFq34QonRHbx3m1KitV1Wcft83';

bool isAppAdminUser(User? user) {
  if (user == null) return false;
  final email = (user.email ?? "").trim().toLowerCase();
  final uid = user.uid;
  return uid == kAdminUid || email == kAdminEmail;
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
          final user = snapshot.data;
          if (isAppAdminUser(user)) {
            return const AdminPortalScaffold();
          }
          return const TelevisaApp();
        }
        return const LoginScreen();
      },
    );
  }
}

class WorkDay {
  static List<int> restDays = [DateTime.saturday, DateTime.sunday];
  static List<Map<String, dynamic>> restDaysHistory = [];
  static List<Map<String, dynamic>> salaryHistory = [];
  static List<Map<String, dynamic>> jornadaHistory = [];
  static double defaultSalary = 0.0;
  static double defaultJornada = 9.5;

  List<int> get applicableRestDays =>
      getRestDaysForDate(entrada, restDaysHistory, restDays);

  bool get isRestDay => applicableRestDays.contains(entrada.weekday);

  DateTime entrada;
  DateTime salida;
  DateTime? entradaReal; // Actual clock-in time (when button was pressed)
  double _storedSueldoBase;
  double _storedBaseHours;
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
      double sueldoBase = 0.0,
      double baseHours = 9.5,
      this.isInProgress = false,
      this.esFalta = false,
      this.esMantenimiento = false,
      this.esVacaciones = false,
      this.esFestivo = false,
      this.festivoTrabajado = false,
      this.notas = "",
      String? id})
      : _storedSueldoBase = sueldoBase,
        _storedBaseHours = baseHours,
        id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  double get sueldoBase {
    if (salaryHistory.isNotEmpty) {
      return getNumericParamForDate(
          entrada, salaryHistory, _storedSueldoBase > 0 ? _storedSueldoBase : defaultSalary);
    }
    return _storedSueldoBase > 0 ? _storedSueldoBase : defaultSalary;
  }

  set sueldoBase(double val) => _storedSueldoBase = val;

  double get baseHours {
    if (jornadaHistory.isNotEmpty) {
      return getNumericParamForDate(
          entrada, jornadaHistory, _storedBaseHours > 0 ? _storedBaseHours : defaultJornada);
    }
    return _storedBaseHours > 0 ? _storedBaseHours : defaultJornada;
  }

  set baseHours(double val) => _storedBaseHours = val;

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
    bool restDay = isRestDay;
    double baseDailyPay = restDay ? sueldoBase * 2 : sueldoBase;
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
    if (isRestDay) {
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
  SyncStatus _syncStatus = SyncStatus.synced;
  DateTime? _lastSyncTime;

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

  // History lists to track changes with date ranges
  List<Map<String, dynamic>> _salaryHistory = [];
  List<Map<String, dynamic>> _jornadaHistory = [];
  List<Map<String, dynamic>> _retentionHistory = [];
  List<Map<String, dynamic>> _fomentoHistory = [];
  List<Map<String, dynamic>> _cuotaHistory = [];
  List<Map<String, dynamic>> _restDaysHistory = [];

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

  // Unit Share ("Compartir Con") State
  bool _isUnitManager = false;
  bool _isUnitShareActive = false;
  Map<String, dynamic>? _activeUnitShareData;

  StreamSubscription? _userRoleSubscription;
  StreamSubscription? _unitShareMembersSubscription;
  StreamSubscription? _unitShareEmpSubscription;
  Stream<List<DocumentSnapshot>>? _unitMembersStream;
  String? _unitMembersStreamUid;
  String? _unitMembersStreamEmp;

  final ScrollController _nominaScrollController = ScrollController();
  final ScrollController _anoScrollController = ScrollController();

  final Map<String, String> _originalFieldValues = {};
  final Set<String> _editingFieldLabels = {};
  List<int> _restDays = [DateTime.saturday, DateTime.sunday];

  late Timer _timer;
  Timer? _countdownTimer;
  String _timeString = "";
  String _dateString = "";
  String _timeRemainingMessage = "";

  int _selectedNominaYear = 2026;
  int _selectedAnoYear = 2026;
  final List<GlobalKey> _weekKeys = List.generate(53, (_) => GlobalKey());
  bool _hasAutoScrolledAnoTab = false;

  final Map<String, Map<String, dynamic>> _payCalendar = {
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
    "2027001": {
      "weeks": [49, 50, 51],
      "payout": "15/01/27",
      "label": "Ene - 1ra"
    },
    "2027002": {
      "weeks": [52, 53],
      "payout": "29/01/27",
      "label": "Ene - 2da"
    },
    "2027003": {
      "weeks": [1, 2, 3],
      "payout": "15/02/27",
      "label": "Feb - 1ra"
    },
    "2027004": {
      "weeks": [4],
      "payout": "26/02/27",
      "label": "Feb - 2da"
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

    // Check if user needs Google employee number setup / Smart Account Merge
    // and then check if user needs onboarding (missing salary or base hours)
    await _checkAndShowOnboarding();
  }

  Future<void> _checkAndShowOnboarding() async {
    // 1. If the user signed in via Google and has no employee number yet,
    // prompt for Employee Number & run Smart Account Merge check first.
    await _checkAndHandleGoogleEmployeeSetup();
    if (!mounted) return;

    // 2. Check if salary or base hours are empty/default
    bool needsOnboarding = _salaryController.text.isEmpty ||
        double.tryParse(_salaryController.text) == 0.0;

    if (needsOnboarding && mounted) {
      // Small delay to ensure UI is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _showOnboardingDialog();
        }
      });
    }
  }

  void _showOnboardingDialog() {
    final TextEditingController salaryInputController = TextEditingController();
    final TextEditingController jornadaInputController =
        TextEditingController(text: "9.5");
    List<int> onboardingRestDays = List<int>.from(_restDays);

    showDialog(
      context: context,
      barrierDismissible: false, // User CANNOT dismiss by tapping outside
      builder: (BuildContext context) {
        return PopScope(
          // Prevent back button from closing - user MUST complete setup
          canPop: false,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
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
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
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
                            borderSide:
                                BorderSide(color: Colors.orange, width: 2),
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
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
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
                            borderSide:
                                BorderSide(color: Colors.orange, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "DÍAS DE DESCANSO",
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Selecciona tus días de descanso habituales (turno doble):",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(7, (index) {
                          final int dayNum = index + 1; // 1: Lun .. 7: Dom
                          const dialNames = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
                          final bool isSelected =
                              onboardingRestDays.contains(dayNum);
                          return InkWell(
                            onTap: () {
                              setDialogState(() {
                                if (isSelected) {
                                  onboardingRestDays.remove(dayNum);
                                } else {
                                  onboardingRestDays.add(dayNum);
                                  onboardingRestDays.sort();
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 36,
                              height: 38,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.orange
                                    : Colors.white.withAlpha(20),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.orangeAccent
                                      : Colors.white24,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Text(
                                dialNames[index],
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.orange.withAlpha(60)),
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

                        // Update controllers and rest days
                        setState(() {
                          _salaryController.text = salary.toString();
                          _baseHoursController.text = jornada.toString();
                          _restDays = onboardingRestDays.isNotEmpty
                              ? onboardingRestDays
                              : [6, 7];
                          WorkDay.restDays = _restDays;
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
              );
            },
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

  // Helpers to get applicable numeric parameters for a specific date using date-range history
  double _getSalaryForDate(DateTime date) {
    return getNumericParamForDate(
        date, _salaryHistory, double.tryParse(_salaryController.text) ?? 0.0);
  }

  double _getJornadaForDate(DateTime date) {
    return getNumericParamForDate(
        date, _jornadaHistory, double.tryParse(_baseHoursController.text) ?? 9.5);
  }

  double _getRetentionForDate(DateTime date) {
    return getNumericParamForDate(
        date, _retentionHistory, double.tryParse(_retentionController.text) ?? 15.22);
  }

  double _getFomentoForDate(DateTime date) {
    return getNumericParamForDate(
        date, _fomentoHistory, double.tryParse(_fomentoController.text) ?? 2.0);
  }

  double _getCuotaForDate(DateTime date) {
    return getNumericParamForDate(
        date, _cuotaHistory, double.tryParse(_cuotaController.text) ?? 2.0);
  }

  List<int> _getRestDaysForDate(DateTime date) {
    return getRestDaysForDate(date, _restDaysHistory, _restDays);
  }

  String _formatRestDaysDisplay(List<int> days) {
    if (days.isEmpty) return "Ninguno";
    const shortNames = {
      1: 'Lun',
      2: 'Mar',
      3: 'Mié',
      4: 'Jue',
      5: 'Vie',
      6: 'Sáb',
      7: 'Dom',
    };
    final sorted = List<int>.from(days)..sort();
    return sorted.map((d) => shortNames[d] ?? d.toString()).join(", ");
  }

  List<Map<String, dynamic>> _normalizeRestDaysHistoryList(dynamic rawList) {
    if (rawList == null || rawList is! List) return [];
    List<Map<String, dynamic>> result = [];
    for (var item in rawList) {
      if (item is Map) {
        final map = Map<String, dynamic>.from(item);
        final rawDays = map['rest_days'];
        List<int> days = [];
        if (rawDays is List) {
          days = rawDays
              .map((e) => int.tryParse(e.toString()) ?? (e is int ? e : null))
              .whereType<int>()
              .where((d) => d >= 1 && d <= 7)
              .toList();
          days.sort();
        }
        if (days.isEmpty) days = [DateTime.saturday, DateTime.sunday];

        final sDate =
            (map['start_date'] ?? map['effective_date'] ?? '').toString();
        final eDate = (map['end_date'] ?? '').toString();

        result.add({
          'rest_days': days,
          'start_date': sDate,
          'end_date': (eDate.isEmpty || eDate == 'null') ? null : eDate,
        });
      }
    }
    return result;
  }

  List<Map<String, dynamic>> _normalizeHistoryList(dynamic rawList,
      {double? fallbackVal}) {
    if (rawList == null || rawList is! List) return [];
    List<Map<String, dynamic>> result = [];
    for (var item in rawList) {
      if (item is Map) {
        final map = Map<String, dynamic>.from(item);
        final valNum = (map['value'] ?? map['salary']) is num
            ? (map['value'] ?? map['salary']).toDouble()
            : (double.tryParse((map['value'] ?? map['salary'] ?? '').toString()) ??
                (fallbackVal ?? 0.0));
        final sDate =
            (map['start_date'] ?? map['effective_date'] ?? '').toString();
        final eDate = (map['end_date'] ?? '').toString();

        Map<String, dynamic> entry = {
          'value': valNum,
          'start_date': sDate,
          'end_date': (eDate.isEmpty || eDate == 'null') ? null : eDate,
        };
        if (map.containsKey('salary')) entry['salary'] = valNum;
        if (map.containsKey('previous_salary')) {
          entry['previous_salary'] = map['previous_salary'];
        }
        result.add(entry);
      }
    }
    return result;
  }

  void _syncWorkDayStatics() {
    WorkDay.restDays = _restDays;
    WorkDay.restDaysHistory = _restDaysHistory;
    WorkDay.salaryHistory = _salaryHistory;
    WorkDay.jornadaHistory = _jornadaHistory;
    WorkDay.defaultSalary = double.tryParse(_salaryController.text) ?? 0.0;
    WorkDay.defaultJornada = double.tryParse(_baseHoursController.text) ?? 9.5;
  }

  CollectionReference get _userHistory => FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser?.uid)
      .collection('history');
  Future<void> _saveData({bool checkSalaryChange = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    // Check for salary change FIRST, before saving
    if (checkSalaryChange && user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get()
            .timeout(const Duration(seconds: 3));

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          String? oldSalary = data['salary'] as String?;
          String? newSalary = _salaryController.text;

          if (oldSalary != null &&
              oldSalary.isNotEmpty &&
              newSalary.isNotEmpty &&
              oldSalary != newSalary) {
            // Salary has changed - prompt for effective date
            if (!mounted) return;

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
      } catch (e) {
        debugPrint("Notice: remote salary check skipped (offline or timeout): $e");
      }
    }

    if (!mounted) return;
    setState(() {
      _isProcessing = true;
      _syncStatus = SyncStatus.syncing;
    });

    try {
      // 1. Save locally to SharedPreferences first
      String jsonHistory =
          jsonEncode(_weeklyHistory.map((e) => e.toJson()).toList());
      await prefs.setString('history_v2', jsonHistory);
      await prefs.setString('salary', _salaryController.text);
      await prefs.setString('salary_history', jsonEncode(_salaryHistory));
      await prefs.setString('jornada_history', jsonEncode(_jornadaHistory));
      await prefs.setString('retention_history', jsonEncode(_retentionHistory));
      await prefs.setString('fomento_history', jsonEncode(_fomentoHistory));
      await prefs.setString('cuota_history', jsonEncode(_cuotaHistory));
      await prefs.setString('rest_days_history', jsonEncode(_restDaysHistory));
      await prefs.setStringList(
          'rest_days', _restDays.map((e) => e.toString()).toList());
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
              'jornada_history': _jornadaHistory,
              'retention_history': _retentionHistory,
              'fomento_history': _fomentoHistory,
              'cuota_history': _cuotaHistory,
              'rest_days_history': _restDaysHistory,
              'base_hours': _baseHoursController.text,
              'rest_days': _restDays,
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

        // Sync employee_directory mapping
        final empNumber = _userEmpNoController.text.trim();
        final recoveryEmail = _recoveryEmailController.text.trim().toLowerCase();
        final authEmail = (user.email ?? "").trim().toLowerCase();
        final userEmail = recoveryEmail.isNotEmpty
            ? recoveryEmail
            : (authEmail.endsWith('@televisa.com') ? "" : authEmail);
        if (empNumber.isNotEmpty && userEmail.isNotEmpty) {
          batch.set(
            FirebaseFirestore.instance
                .collection('employee_directory')
                .doc(empNumber),
            {
              'email': userEmail,
              'legacy_email': "$empNumber@televisa.com",
              'employee_number': empNumber,
              'uid': user.uid,
              'updated_at': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }

        await batch.commit().timeout(const Duration(seconds: 8));
        _syncShiftsToUnitManager();
      }

      await prefs.setBool('has_pending_sync', false);
      final nowSync = DateTime.now();
      _lastSyncTime = nowSync;
      await prefs.setString('last_sync_time', nowSync.toIso8601String());
      if (mounted) {
        setState(() {
          _syncStatus = SyncStatus.synced;
        });
      }
    } catch (e) {
      debugPrint("Notice: Cloud sync error or offline: $e");
      await prefs.setBool('has_pending_sync', true);
      if (mounted) {
        setState(() {
          if (e is TimeoutException ||
              e.toString().contains('unavailable') ||
              e.toString().contains('network') ||
              e.toString().contains('offline') ||
              e.toString().contains('SocketException')) {
            _syncStatus = SyncStatus.offlinePending;
          } else {
            _syncStatus = SyncStatus.error;
          }
        });
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _triggerManualSync() async {
    if (_syncStatus == SyncStatus.syncing) return;
    setState(() {
      _syncStatus = SyncStatus.syncing;
    });
    await _saveData(checkSalaryChange: false);
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

    // Clear user-specific local cache if a different Firebase Auth UID signed in
    if (user != null) {
      final lastUid = prefs.getString('last_logged_in_uid');
      if (lastUid != null && lastUid != user.uid) {
        for (final key in [
          'salary',
          'base_hours',
          'retention',
          'fomento',
          'cuota',
          'first_name',
          'last_name',
          'user_emp',
          'recovery_email',
          'history_v2',
          'salary_history',
          'jornada_history',
          'retention_history',
          'fomento_history',
          'cuota_history',
          'rest_days_history',
          'rest_days',
          'is_unit_manager',
          'pending_entrada',
          'pending_entrada_real',
          'pending_clocked_in',
          'last_sync_time',
        ]) {
          await prefs.remove(key);
        }
        _lastSyncTime = null;
      }
      await prefs.setString('last_logged_in_uid', user.uid);
    }

    final String? savedVersion = prefs.getString('last_seen_version');
    if (savedVersion == null) {
      await prefs.setString('last_seen_version', "0.0.0");
      _lastSeenVersion = "0.0.0";
    } else {
      _lastSeenVersion = savedVersion;
    }

    setState(() {
      _isDarkMode = prefs.getBool('app_is_dark_mode') ?? true;
      _isUnitManager = prefs.getBool('is_unit_manager') ?? false;
      _salaryController.text = prefs.getString('salary') ?? "";

      // Load history lists
      String? salaryHistoryJson = prefs.getString('salary_history');
      if (salaryHistoryJson != null && salaryHistoryJson.isNotEmpty) {
        try {
          _salaryHistory = _normalizeHistoryList(jsonDecode(salaryHistoryJson));
        } catch (e) {
          _salaryHistory = [];
        }
      } else {
        _salaryHistory = [];
      }

      String? jornadaHistoryJson = prefs.getString('jornada_history');
      if (jornadaHistoryJson != null && jornadaHistoryJson.isNotEmpty) {
        try {
          _jornadaHistory = _normalizeHistoryList(jsonDecode(jornadaHistoryJson));
        } catch (e) {
          _jornadaHistory = [];
        }
      } else {
        _jornadaHistory = [];
      }

      String? retentionHistoryJson = prefs.getString('retention_history');
      if (retentionHistoryJson != null && retentionHistoryJson.isNotEmpty) {
        try {
          _retentionHistory = _normalizeHistoryList(jsonDecode(retentionHistoryJson));
        } catch (e) {
          _retentionHistory = [];
        }
      } else {
        _retentionHistory = [];
      }

      String? fomentoHistoryJson = prefs.getString('fomento_history');
      if (fomentoHistoryJson != null && fomentoHistoryJson.isNotEmpty) {
        try {
          _fomentoHistory = _normalizeHistoryList(jsonDecode(fomentoHistoryJson));
        } catch (e) {
          _fomentoHistory = [];
        }
      } else {
        _fomentoHistory = [];
      }

      String? cuotaHistoryJson = prefs.getString('cuota_history');
      if (cuotaHistoryJson != null && cuotaHistoryJson.isNotEmpty) {
        try {
          _cuotaHistory = _normalizeHistoryList(jsonDecode(cuotaHistoryJson));
        } catch (e) {
          _cuotaHistory = [];
        }
      } else {
        _cuotaHistory = [];
      }

      String? restDaysHistoryJson = prefs.getString('rest_days_history');
      if (restDaysHistoryJson != null && restDaysHistoryJson.isNotEmpty) {
        try {
          _restDaysHistory =
              _normalizeRestDaysHistoryList(jsonDecode(restDaysHistoryJson));
        } catch (e) {
          _restDaysHistory = [];
        }
      } else {
        _restDaysHistory = [];
      }

      List<String>? savedRestDays = prefs.getStringList('rest_days');
      if (savedRestDays != null && savedRestDays.isNotEmpty) {
        _restDays = savedRestDays
            .map((e) => int.tryParse(e) ?? 0)
            .where((e) => e >= 1 && e <= 7)
            .toList();
      } else {
        _restDays = [6, 7];
      }
      WorkDay.restDays = _restDays;
      WorkDay.restDaysHistory = _restDaysHistory;

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
      _syncWorkDayStatics();

      final String? savedLastSync = prefs.getString('last_sync_time');
      if (savedLastSync != null) {
        try {
          _lastSyncTime = DateTime.parse(savedLastSync);
        } catch (_) {}
      }
    });

    final bool hasPendingSync = prefs.getBool('has_pending_sync') ?? false;
    if (hasPendingSync && mounted) {
      setState(() {
        _syncStatus = SyncStatus.offlinePending;
      });
    }

    if (user != null) {
      try {
        // 1. Load Settings from Cloud
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get()
            .timeout(const Duration(seconds: 4));
        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          final String userEmp = (data['user_emp'] ??
                  data['employee_number'] ??
                  _userEmpNoController.text)
              .toString()
              .trim();
          bool isMgr = data['is_unit_manager'] == true ||
              data['role'] == 'ingeniero_de_unidad';

          if (!isMgr) {
            isMgr = await _resolveIsUnitManager(user, userEmp);
          } else {
            await prefs.setBool('is_unit_manager', true);
          }

          _setupUnitManagerRealtimeListener(user, userEmp);

          setState(() {
            _isUnitManager = isMgr;
            _salaryController.text = data['salary'] ?? _salaryController.text;

            // Load history lists from cloud
            if (data['salary_history'] != null) {
              _salaryHistory = _normalizeHistoryList(data['salary_history']);
              prefs.setString('salary_history', jsonEncode(_salaryHistory));
            }
            if (data['jornada_history'] != null) {
              _jornadaHistory = _normalizeHistoryList(data['jornada_history']);
              prefs.setString('jornada_history', jsonEncode(_jornadaHistory));
            }
            if (data['retention_history'] != null) {
              _retentionHistory = _normalizeHistoryList(data['retention_history']);
              prefs.setString('retention_history', jsonEncode(_retentionHistory));
            }
            if (data['fomento_history'] != null) {
              _fomentoHistory = _normalizeHistoryList(data['fomento_history']);
              prefs.setString('fomento_history', jsonEncode(_fomentoHistory));
            }
            if (data['cuota_history'] != null) {
              _cuotaHistory = _normalizeHistoryList(data['cuota_history']);
              prefs.setString('cuota_history', jsonEncode(_cuotaHistory));
            }
            if (data['rest_days_history'] != null) {
              _restDaysHistory =
                  _normalizeRestDaysHistoryList(data['rest_days_history']);
              prefs.setString(
                  'rest_days_history', jsonEncode(_restDaysHistory));
            }
            _syncWorkDayStatics();

            if (data['rest_days'] != null) {
              _restDays = List<int>.from(
                  (data['rest_days'] as List).map((x) => (x as num).toInt()));
              if (_restDays.isEmpty) _restDays = [6, 7];
              prefs.setStringList(
                  'rest_days', _restDays.map((e) => e.toString()).toList());
              WorkDay.restDays = _restDays;
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
        } else {
          final String fallbackEmp = _userEmpNoController.text.trim();
          final bool isMgr = await _resolveIsUnitManager(user, fallbackEmp);
          if (isMgr) {
            await prefs.setBool('is_unit_manager', true);
            if (mounted) {
              setState(() {
                _isUnitManager = true;
              });
            }
          }
          _setupUnitManagerRealtimeListener(user, fallbackEmp);
        }

        // 2. Load History from Cloud
        final snapshot =
            await _userHistory.get().timeout(const Duration(seconds: 4));
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

        // 3. Load Unit Share Settings
        await _loadUnitShareSettings().timeout(const Duration(seconds: 4));

        if (!hasPendingSync && mounted) {
          final nowSync = DateTime.now();
          _lastSyncTime = nowSync;
          await prefs.setString('last_sync_time', nowSync.toIso8601String());
          setState(() {
            _syncStatus = SyncStatus.synced;
          });
        }
      } catch (e) {
        debugPrint(
            "Notice: Cloud load timed out or offline, using local data: $e");
        if (mounted) {
          setState(() {
            _syncStatus = SyncStatus.offlinePending;
          });
        }
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



  Future<bool> _resolveIsUnitManager(User user, String userEmp) async {
    // 1. Check unit_managers by UID
    try {
      final mgrDocByUid = await FirebaseFirestore.instance
          .collection('unit_managers')
          .doc(user.uid)
          .get();
      if (mgrDocByUid.exists && mgrDocByUid.data()?['is_unit_manager'] == true) {
        _selfHealUnitManagerStatus(user.uid, userEmp);
        return true;
      }
    } catch (e) {
      debugPrint("Notice: could not check unit_managers by UID: $e");
    }

    // 2. Check unit_managers by employee number
    final cleanEmp = userEmp.trim();
    if (cleanEmp.isNotEmpty) {
      try {
        final mgrDocByEmp = await FirebaseFirestore.instance
            .collection('unit_managers')
            .doc(cleanEmp)
            .get();
        if (mgrDocByEmp.exists && mgrDocByEmp.data()?['is_unit_manager'] == true) {
          _selfHealUnitManagerStatus(user.uid, cleanEmp);
          return true;
        }

        final empQuery = await FirebaseFirestore.instance
            .collection('unit_managers')
            .where('employee_number', isEqualTo: cleanEmp)
            .limit(1)
            .get();
        if (empQuery.docs.isNotEmpty) {
          _selfHealUnitManagerStatus(user.uid, cleanEmp);
          return true;
        }
      } catch (e) {
        debugPrint("Notice: could not check unit_managers by emp: $e");
      }
    }

    // 3. Query unit_managers where uid == user.uid
    try {
      final uidQuery = await FirebaseFirestore.instance
          .collection('unit_managers')
          .where('uid', isEqualTo: user.uid)
          .limit(1)
          .get();
      if (uidQuery.docs.isNotEmpty) {
        _selfHealUnitManagerStatus(user.uid, cleanEmp);
        return true;
      }
    } catch (e) {
      debugPrint("Notice: could not query unit_managers by uid: $e");
    }

    // 4. Check if any members exist under unit_shares/{user.uid}/members
    try {
      final sharesByUid = await FirebaseFirestore.instance
          .collection('unit_shares')
          .doc(user.uid)
          .collection('members')
          .limit(1)
          .get();
      if (sharesByUid.docs.isNotEmpty) {
        _selfHealUnitManagerStatus(user.uid, cleanEmp);
        return true;
      }
    } catch (e) {
      debugPrint("Notice: could not check unit_shares by UID: $e");
    }

    // 5. Check if any members exist under unit_shares/{cleanEmp}/members
    if (cleanEmp.isNotEmpty) {
      try {
        final sharesByEmp = await FirebaseFirestore.instance
            .collection('unit_shares')
            .doc(cleanEmp)
            .collection('members')
            .limit(1)
            .get();
        if (sharesByEmp.docs.isNotEmpty) {
          _selfHealUnitManagerStatus(user.uid, cleanEmp);
          return true;
        }
      } catch (e) {
        debugPrint("Notice: could not check unit_shares by emp: $e");
      }
    }

    return false;
  }

  Future<void> _selfHealUnitManagerStatus(String uid, String emp) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'is_unit_manager': true,
        'role': 'ingeniero_de_unidad',
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Notice: could not self-heal users doc: $e");
    }
  }

  void _setupUnitManagerRealtimeListener(User user, String userEmp) {
    _userRoleSubscription?.cancel();
    _unitShareMembersSubscription?.cancel();
    _unitShareEmpSubscription?.cancel();

    _userRoleSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots(includeMetadataChanges: true)
        .listen((snap) {
      if (snap.exists && mounted) {
        final d = snap.data();
        final bool isMgr = d?['is_unit_manager'] == true ||
            d?['role'] == 'ingeniero_de_unidad';
        if (_isUnitManager != isMgr) {
          setState(() {
            _isUnitManager = isMgr;
          });
          SharedPreferences.getInstance()
              .then((p) => p.setBool('is_unit_manager', isMgr));
        }
      }
      if (mounted) {
        if (snap.metadata.hasPendingWrites) {
          if (_syncStatus != SyncStatus.syncing) {
            setState(() {
              _syncStatus = SyncStatus.offlinePending;
            });
          }
        } else {
          if (_syncStatus != SyncStatus.syncing) {
            final nowSync = DateTime.now();
            _lastSyncTime = nowSync;
            SharedPreferences.getInstance().then(
                (p) => p.setString('last_sync_time', nowSync.toIso8601String()));
            setState(() {
              _syncStatus = SyncStatus.synced;
            });
          }
        }
      }
    }, onError: (e) {
      debugPrint("user role listener notice: $e");
      if (mounted && _syncStatus != SyncStatus.syncing) {
        setState(() {
          _syncStatus = SyncStatus.offlinePending;
        });
      }
    });

    _unitShareMembersSubscription = FirebaseFirestore.instance
        .collection('unit_shares')
        .doc(user.uid)
        .collection('members')
        .snapshots()
        .listen((snap) {
      if (snap.docs.isNotEmpty && !_isUnitManager && mounted) {
        setState(() {
          _isUnitManager = true;
        });
        SharedPreferences.getInstance().then((p) => p.setBool('is_unit_manager', true));
      }
    }, onError: (e) => debugPrint("unit_shares member listener notice: $e"));

    final cleanEmp = userEmp.trim();
    if (cleanEmp.isNotEmpty && cleanEmp != user.uid) {
      _unitShareEmpSubscription = FirebaseFirestore.instance
          .collection('unit_shares')
          .doc(cleanEmp)
          .collection('members')
          .snapshots()
          .listen((snap) {
        if (snap.docs.isNotEmpty && !_isUnitManager && mounted) {
          setState(() {
            _isUnitManager = true;
          });
          SharedPreferences.getInstance().then((p) => p.setBool('is_unit_manager', true));
        }
      }, onError: (e) => debugPrint("unit_shares emp listener notice: $e"));
    }
  }

  Stream<List<DocumentSnapshot>> _getOrCreateUnitMembersStream(
      String uid, String emp) {
    if (_unitMembersStream != null &&
        _unitMembersStreamUid == uid &&
        _unitMembersStreamEmp == emp) {
      return _unitMembersStream!;
    }
    _unitMembersStreamUid = uid;
    _unitMembersStreamEmp = emp;
    _unitMembersStream = _createUnitMembersStream(uid, emp).asBroadcastStream();
    return _unitMembersStream!;
  }

  Stream<List<DocumentSnapshot>> _createUnitMembersStream(
      String uid, String emp) {
    late StreamController<List<DocumentSnapshot>> controller;
    StreamSubscription? subUid;
    StreamSubscription? subEmp;
    final Map<String, DocumentSnapshot> uidDocs = {};
    final Map<String, DocumentSnapshot> empDocs = {};

    void emitMerged() {
      if (controller.isClosed) return;
      final Map<String, DocumentSnapshot> merged = {};
      for (final e in empDocs.entries) {
        merged[e.key] = e.value;
      }
      for (final e in uidDocs.entries) {
        merged[e.key] = e.value;
      }
      controller.add(merged.values.toList());
    }

    controller = StreamController<List<DocumentSnapshot>>(
      onListen: () {
        subUid = FirebaseFirestore.instance
            .collection('unit_shares')
            .doc(uid)
            .collection('members')
            .snapshots()
            .listen(
          (snap) {
            uidDocs.clear();
            for (final doc in snap.docs) {
              uidDocs[doc.id] = doc;
            }
            emitMerged();
          },
          onError: (err) {
            if (!controller.isClosed) controller.addError(err);
          },
        );

        final cleanEmp = emp.trim();
        if (cleanEmp.isNotEmpty && cleanEmp != uid) {
          subEmp = FirebaseFirestore.instance
              .collection('unit_shares')
              .doc(cleanEmp)
              .collection('members')
              .snapshots()
              .listen(
            (snap) {
              empDocs.clear();
              for (final doc in snap.docs) {
                empDocs[doc.id] = doc;
              }
              emitMerged();
            },
            onError: (err) {
              // Ignore if emp subcollection does not exist
            },
          );
        }
      },
      onCancel: () {
        subUid?.cancel();
        subEmp?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  void dispose() {
    _timer.cancel();
    _countdownTimer?.cancel();
    _userRoleSubscription?.cancel();
    _unitShareMembersSubscription?.cancel();
    _unitShareEmpSubscription?.cancel();
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
    // Jan 1-3, 2027 belong to Week 53 of 2026 rather than returning 0
    if (date.year == 2027 && date.month == 1 && date.day <= 3) {
      return 53;
    }
    int dayOfYear = int.parse(DateFormat("D").format(date));
    int week = ((dayOfYear - date.weekday + 10) / 7).floor();
    if (week == 0) {
      DateTime prevYearEnd = DateTime(date.year - 1, 12, 31);
      int prevDayOfYear = int.parse(DateFormat("D").format(prevYearEnd));
      return ((prevDayOfYear - prevYearEnd.weekday + 10) / 7).floor();
    }
    return week;
  }

  Map<WorkDay, OvertimeBreakdown> calculateWeeklyOvertimeBreakdown(
      List<WorkDay> weekDays) {
    final sortedDays = [...weekDays]
      ..sort((a, b) => a.entrada.compareTo(b.entrada));

    double accumulatedCreditedOT = 0.0;
    final Map<WorkDay, OvertimeBreakdown> result = {};

    for (final day in sortedDays) {
      final breakdown = OvertimeBreakdown();
      if (!day.isInProgress &&
          !day.esFalta &&
          !day.esMantenimiento &&
          !day.esFestivo &&
          day.creditedExtraHours > 0) {
        double hourlyRate = day.hourlyRate; // sueldoBase / baseHours

        if (day.isRestDay) {
          // Rest-day overtime is 100% 3x and does not consume regular 9h quota
          double h3x = day.creditedExtraHours;
          breakdown.hours2x = 0.0;
          breakdown.pay2x = 0.0;
          breakdown.hours3x = h3x;
          breakdown.pay3x = h3x * hourlyRate * 3;
        } else {
          double remainingOT = day.creditedExtraHours;

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
    setState(() {
      _isProcessing = true;
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

    final double salaryForDate = _getSalaryForDate(assignedTime);
    final double bHrs = _getJornadaForDate(assignedTime);

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
      final double bHrs =
          _getJornadaForDate(_entradaDateTime ?? salidaTime);
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
    _syncShiftsToUnitManager();

    if (mounted) {
      setState(() => _isProcessing = false);
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

  String _formatLastSyncTime(DateTime dt) {
    final now = DateTime.now();
    final bool isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final timeStr = DateFormat('hh:mm a').format(dt);
    if (isToday) {
      return "Hoy $timeStr";
    }
    return DateFormat('dd/MM hh:mm a').format(dt);
  }

  Widget _buildSyncStatusBanner() {
    Color bgColor;
    Color textColor;
    Color borderColor;
    Widget content;
    const double verticalPadding = 13.0;

    switch (_syncStatus) {
      case SyncStatus.synced:
        bgColor = _isDarkMode ? const Color(0xFF052E16) : const Color(0xFFDCFCE7);
        textColor = _isDarkMode ? const Color(0xFF4ADE80) : const Color(0xFF15803D);
        borderColor = _isDarkMode ? const Color(0xFF14532D) : const Color(0xFF86EFAC);
        final String syncText = _lastSyncTime != null
            ? "✓ Sincronizado con la nube • ${_formatLastSyncTime(_lastSyncTime!)}"
            : "✓ Sincronizado con la nube";
        content = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 21, color: textColor),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                syncText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
        break;

      case SyncStatus.syncing:
        bgColor = _isDarkMode ? const Color(0xFF1E3A8A) : const Color(0xFF2563EB);
        textColor = Colors.white;
        borderColor = _isDarkMode ? const Color(0xFF3B82F6) : const Color(0xFF1D4ED8);
        content = const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 8),
            Text(
              "🔄 Sincronizando datos...",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
        break;

      case SyncStatus.offlinePending:
        bgColor = const Color(0xFFD97706);
        textColor = Colors.white;
        borderColor = const Color(0xFFB45309);
        final String offlineText = _lastSyncTime != null
            ? "⚡ Modo sin conexión • Última sinc: ${_formatLastSyncTime(_lastSyncTime!)} • Toca para sincronizar"
            : "⚡ Modo sin conexión: Guardado en tu dispositivo. [ Toca aquí para sincronizar ]";
        content = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bolt, size: 21, color: Colors.white),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                offlineText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        );
        break;

      case SyncStatus.error:
        bgColor = const Color(0xFFDC2626);
        textColor = Colors.white;
        borderColor = const Color(0xFF991B1B);
        final String errorText = _lastSyncTime != null
            ? "⚠️ Error de conexión • Última sinc: ${_formatLastSyncTime(_lastSyncTime!)} • [ Reintentar ]"
            : "⚠️ Error de conexión: Datos seguros en tu dispositivo. [ Reintentar ]";
        content = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 21, color: Colors.white),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                errorText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        );
        break;
    }

    return Material(
      color: bgColor,
      child: InkWell(
        onTap: _triggerManualSync,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(vertical: verticalPadding, horizontal: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: borderColor, width: 1.0),
            ),
          ),
          child: Center(child: content),
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
                "v.23.17.0 04/11/26",
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
      key: ValueKey('main_tabs_$_isUnitManager'),
      length: _isUnitManager ? 7 : 6,
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
            tabs: [
              const Tab(text: "HOY", icon: Icon(Icons.access_time, size: 28)),
              const Tab(text: "QUINCENA", icon: Icon(Icons.calendar_month, size: 28)),
              const Tab(text: "AÑO", icon: Icon(Icons.calendar_today, size: 28)),
              const Tab(text: "NÓMINA", icon: Icon(Icons.payments, size: 28)),
              const Tab(text: "EXTRAS", icon: Icon(Icons.star, size: 28)),
              if (_isUnitManager)
                const Tab(text: "UNIDAD", icon: Icon(Icons.shield_rounded, size: 28)),
              const Tab(text: "AJUSTES", icon: Icon(Icons.settings, size: 28)),
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
        body: Column(
          children: [
            _buildSyncStatusBanner(),
            Expanded(
              child: TabBarView(children: [
                _buildHoyTab(),
                _buildQuincenaTab(),
                _buildAnoTab(),
                _buildNominaTab(),
                _buildExtrasTab(),
                if (_isUnitManager) _buildUnitManagerTab(),
                _buildSettingsTab()
              ]),
            ),
          ],
        ),
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

    bool startedOnWeekend = day.isRestDay;

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
                          day.isRestDay
                              ? "\$${day.sueldoBase.toStringAsFixed(2)} Base\n"
                                  "\$${day.sueldoBase.toStringAsFixed(2)} Día de descanso\n"
                                  "2× ${breakdown.hours2x.toStringAsFixed(2)}h  \$${breakdown.pay2x.toStringAsFixed(2)}\n"
                                  "3× ${breakdown.hours3x.toStringAsFixed(2)}h  \$${breakdown.pay3x.toStringAsFixed(2)}"
                              : "\$${day.dailyPay.toStringAsFixed(2)} Base\n"
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


  void _rebuild([VoidCallback? fn]) => setState(fn ?? () {});
}
