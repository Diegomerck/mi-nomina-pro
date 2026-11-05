part of '../main.dart';

class AdminUserSummary {
  final String uid;
  final String email;
  final String recoveryEmail;
  final String firstName;
  final String lastName;
  final String employeeNumber;
  final String salary;
  final String baseHours;
  final List<dynamic> restDays;
  final int shiftCount;
  final bool isMerged;
  final String? mergedInto;
  final bool isUnitManager;
  final String role;
  final Map<String, dynamic> rawData;

  AdminUserSummary({
    required this.uid,
    required this.email,
    required this.recoveryEmail,
    required this.firstName,
    required this.lastName,
    required this.employeeNumber,
    required this.salary,
    required this.baseHours,
    required this.restDays,
    required this.shiftCount,
    required this.isMerged,
    this.mergedInto,
    this.isUnitManager = false,
    this.role = 'empleado',
    required this.rawData,
  });

  String get fullName {
    final name = "$firstName $lastName".trim();
    return name.isEmpty ? "Sin nombre registrado" : name;
  }
}

class MergeFieldComparison {
  final String key;
  final String title;
  final IconData icon;
  final String sourceValue;
  final String targetValue;
  final bool isDifferent;
  final bool hasSourceData;

  const MergeFieldComparison({
    required this.key,
    required this.title,
    required this.icon,
    required this.sourceValue,
    required this.targetValue,
    required this.isDifferent,
    required this.hasSourceData,
  });
}

class AdminAccountMergeScreen extends StatefulWidget {
  final bool isDarkMode;
  final bool isEmbedded;
  final VoidCallback? onMergeComplete;
  const AdminAccountMergeScreen({
    super.key,
    required this.isDarkMode,
    this.isEmbedded = false,
    this.onMergeComplete,
  });

  @override
  State<AdminAccountMergeScreen> createState() =>
      _AdminAccountMergeScreenState();
}

class _AdminAccountMergeScreenState extends State<AdminAccountMergeScreen> {
  final _sourceController = TextEditingController();
  final _targetController = TextEditingController();

  AdminUserSummary? _sourceUser;
  AdminUserSummary? _targetUser;

  bool _isSearchingSource = false;
  bool _isSearchingTarget = false;

  String? _sourceError;
  String? _targetError;

  bool _isMerging = false;
  String _mergeStatus = "";
  double _mergeProgress = 0.0;

  // Selective Copy Matrix options
  final Map<String, bool> _selectedFields = {
    'turnos': true,
    'sueldo': true,
    'jornada': true,
    'descansos': true,
    'retencion': true,
    'fomento': true,
    'cuota': true,
    'historial_aumentos': true,
    'nombre': true,
    'apellido': true,
    'no_empleado': true,
  };
  bool _exactReplacement = true;
  bool _sendPasswordResetPostMerge = true;

  // Real-time debounced auto-search
  Timer? _sourceDebounceTimer;
  Timer? _targetDebounceTimer;
  bool _isDebouncingSource = false;
  bool _isDebouncingTarget = false;
  int _sourceQueryId = 0;
  int _targetQueryId = 0;

  @override
  void initState() {
    super.initState();
    _sourceController.addListener(_onSourceChanged);
    _targetController.addListener(_onTargetChanged);
  }

  @override
  void dispose() {
    _sourceDebounceTimer?.cancel();
    _targetDebounceTimer?.cancel();
    _sourceController.removeListener(_onSourceChanged);
    _targetController.removeListener(_onTargetChanged);
    _sourceController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  void _onSourceChanged() {
    final text = _sourceController.text.trim();
    _sourceDebounceTimer?.cancel();

    if (text.isEmpty) {
      _sourceQueryId++;
      setState(() {
        _isDebouncingSource = false;
        _isSearchingSource = false;
        _sourceUser = null;
        _sourceError = null;
      });
      return;
    }

    if (text.length < 3) {
      _sourceQueryId++;
      setState(() {
        _isDebouncingSource = false;
        _isSearchingSource = false;
        _sourceUser = null;
        _sourceError = null;
      });
      return;
    }

    setState(() {
      _isDebouncingSource = true;
    });

    _sourceDebounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _searchSource();
    });
  }

  void _onTargetChanged() {
    final text = _targetController.text.trim();
    _targetDebounceTimer?.cancel();

    if (text.isEmpty) {
      _targetQueryId++;
      setState(() {
        _isDebouncingTarget = false;
        _isSearchingTarget = false;
        _targetUser = null;
        _targetError = null;
      });
      return;
    }

    if (text.length < 3) {
      _targetQueryId++;
      setState(() {
        _isDebouncingTarget = false;
        _isSearchingTarget = false;
        _targetUser = null;
        _targetError = null;
      });
      return;
    }

    setState(() {
      _isDebouncingTarget = true;
    });

    _targetDebounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _searchTarget();
    });
  }

  Color get _bg =>
      widget.isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8FAFC);
  Color get _surface =>
      widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
  Color get _border =>
      widget.isDarkMode ? Colors.white12 : const Color(0xFFE2E8F0);
  Color get _textPrimary =>
      widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
  Color get _textSecondary =>
      widget.isDarkMode ? Colors.white60 : const Color(0xFF64748B);

  Future<AdminUserSummary?> _lookupUser(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.isEmpty) return null;

    String? foundUid;
    Map<String, dynamic>? userData;

    // 1. Direct UID lookup
    try {
      final docById = await FirebaseFirestore.instance
          .collection('users')
          .doc(query)
          .get();
      if (docById.exists) {
        foundUid = docById.id;
        userData = docById.data();
      }
    } catch (_) {}

    // 2. Directory lookup if employee number
    if (foundUid == null) {
      try {
        final dirDoc = await FirebaseFirestore.instance
            .collection('employee_directory')
            .doc(query)
            .get();
        if (dirDoc.exists) {
          final d = dirDoc.data();
          final uidFromDir = d?['uid'] as String?;
          if (uidFromDir != null && uidFromDir.isNotEmpty) {
            final uDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(uidFromDir)
                .get();
            if (uDoc.exists) {
              foundUid = uDoc.id;
              userData = uDoc.data();
            }
          }
        }
      } catch (_) {}
    }

    // 3. Search by email
    if (foundUid == null && query.contains('@')) {
      final qEmail = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: query.toLowerCase())
          .limit(1)
          .get();
      if (qEmail.docs.isNotEmpty) {
        foundUid = qEmail.docs.first.id;
        userData = qEmail.docs.first.data();
      } else {
        final qRec = await FirebaseFirestore.instance
            .collection('users')
            .where('recovery_email', isEqualTo: query.toLowerCase())
            .limit(1)
            .get();
        if (qRec.docs.isNotEmpty) {
          foundUid = qRec.docs.first.id;
          userData = qRec.docs.first.data();
        }
      }
    }

    // 4. Search by user_emp or employee_number
    if (foundUid == null) {
      final qEmp = await FirebaseFirestore.instance
          .collection('users')
          .where('user_emp', isEqualTo: query)
          .limit(1)
          .get();
      if (qEmp.docs.isNotEmpty) {
        foundUid = qEmp.docs.first.id;
        userData = qEmp.docs.first.data();
      } else {
        final qEmp2 = await FirebaseFirestore.instance
            .collection('users')
            .where('employee_number', isEqualTo: query)
            .limit(1)
            .get();
        if (qEmp2.docs.isNotEmpty) {
          foundUid = qEmp2.docs.first.id;
          userData = qEmp2.docs.first.data();
        }
      }
    }

    // 5. Search by legacy email if query is numeric
    if (foundUid == null && !query.contains('@')) {
      final legacyEmail = "$query@televisa.com".toLowerCase();
      final qLegacy = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: legacyEmail)
          .limit(1)
          .get();
      if (qLegacy.docs.isNotEmpty) {
        foundUid = qLegacy.docs.first.id;
        userData = qLegacy.docs.first.data();
      }
    }

    if (foundUid == null || userData == null) {
      return null;
    }

    // Count shifts in history subcollection
    int count = 0;
    try {
      final countSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(foundUid)
          .collection('history')
          .count()
          .get();
      count = countSnap.count ?? 0;
    } catch (_) {
      try {
        final histSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(foundUid)
            .collection('history')
            .get();
        count = histSnap.docs.length;
      } catch (_) {
        count = 0;
      }
    }

    final bool isUnitMgr = userData['is_unit_manager'] == true ||
        userData['role'] == 'ingeniero_de_unidad';
    final String userRole =
        (userData['role'] ?? (isUnitMgr ? 'ingeniero_de_unidad' : 'empleado'))
            .toString();

    return AdminUserSummary(
      uid: foundUid,
      email: (userData['email'] ?? '').toString(),
      recoveryEmail: (userData['recovery_email'] ?? '').toString(),
      firstName: (userData['first_name'] ?? '').toString(),
      lastName: (userData['last_name'] ?? '').toString(),
      employeeNumber:
          (userData['user_emp'] ?? userData['employee_number'] ?? '').toString(),
      salary: (userData['salary'] ?? '0.00').toString(),
      baseHours: (userData['base_hours'] ?? '9.5').toString(),
      restDays: (userData['rest_days'] as List<dynamic>?) ?? [],
      shiftCount: count,
      isMerged: userData['is_merged'] == true,
      mergedInto: userData['merged_into'] as String?,
      isUnitManager: isUnitMgr,
      role: userRole,
      rawData: userData,
    );
  }

  Future<void> _searchSource() async {
    _sourceDebounceTimer?.cancel();
    final query = _sourceController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _isDebouncingSource = false;
        _isSearchingSource = false;
        _sourceError = "Ingresa un número de empleado o correo";
        _sourceUser = null;
      });
      return;
    }

    final currentId = ++_sourceQueryId;
    setState(() {
      _isDebouncingSource = false;
      _isSearchingSource = true;
      _sourceError = null;
      _sourceUser = null;
    });

    try {
      final user = await _lookupUser(query);
      if (!mounted || currentId != _sourceQueryId) return;
      setState(() {
        _isSearchingSource = false;
        if (user != null) {
          _sourceUser = user;
          _sourceError = null;
          _initFieldSelections();
        } else {
          _sourceError = "No se encontró ninguna cuenta con '$query'";
        }
      });
    } on FirebaseException catch (fe) {
      if (!mounted || currentId != _sourceQueryId) return;
      setState(() {
        _isSearchingSource = false;
        _sourceError = fe.code == 'permission-denied'
            ? "Permiso denegado en Firestore. Asegúrate de haber publicado las reglas de administrador."
            : "Error de Firebase: ${fe.message}";
      });
    } catch (e) {
      if (!mounted || currentId != _sourceQueryId) return;
      setState(() {
        _isSearchingSource = false;
        _sourceError = "Error: $e";
      });
    }
  }

  Future<void> _searchTarget() async {
    _targetDebounceTimer?.cancel();
    final query = _targetController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _isDebouncingTarget = false;
        _isSearchingTarget = false;
        _targetError = "Ingresa un correo o número de empleado";
        _targetUser = null;
      });
      return;
    }

    final currentId = ++_targetQueryId;
    setState(() {
      _isDebouncingTarget = false;
      _isSearchingTarget = true;
      _targetError = null;
      _targetUser = null;
    });

    try {
      final user = await _lookupUser(query);
      if (!mounted || currentId != _targetQueryId) return;
      setState(() {
        _isSearchingTarget = false;
        if (user != null) {
          _targetUser = user;
          _targetError = null;
          _initFieldSelections();
        } else {
          _targetError = "No se encontró ninguna cuenta con '$query'";
        }
      });
    } on FirebaseException catch (fe) {
      if (!mounted || currentId != _targetQueryId) return;
      setState(() {
        _isSearchingTarget = false;
        _targetError = fe.code == 'permission-denied'
            ? "Permiso denegado en Firestore. Asegúrate de haber publicado las reglas de administrador."
            : "Error de Firebase: ${fe.message}";
      });
    } catch (e) {
      if (!mounted || currentId != _targetQueryId) return;
      setState(() {
        _isSearchingTarget = false;
        _targetError = "Error: $e";
      });
    }
  }

  Widget? _buildSourceSuffixIcon() {
    final hasText = _sourceController.text.isNotEmpty;
    final isLoading = _isSearchingSource || _isDebouncingSource;
    if (!hasText && !isLoading) return null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading)
          Padding(
            padding: EdgeInsets.only(right: hasText ? 4 : 12),
            child: const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
            ),
          ),
        if (hasText)
          IconButton(
            icon: Icon(Icons.clear_rounded, size: 18, color: _textSecondary),
            tooltip: "Borrar",
            splashRadius: 16,
            onPressed: () {
              _sourceDebounceTimer?.cancel();
              _sourceController.clear();
            },
          ),
      ],
    );
  }

  Widget? _buildTargetSuffixIcon() {
    final hasText = _targetController.text.isNotEmpty;
    final isLoading = _isSearchingTarget || _isDebouncingTarget;
    if (!hasText && !isLoading) return null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading)
          Padding(
            padding: EdgeInsets.only(right: hasText ? 4 : 12),
            child: const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              ),
            ),
          ),
        if (hasText)
          IconButton(
            icon: Icon(Icons.clear_rounded, size: 18, color: _textSecondary),
            tooltip: "Borrar",
            splashRadius: 16,
            onPressed: () {
              _targetDebounceTimer?.cancel();
              _targetController.clear();
            },
          ),
      ],
    );
  }

  List<MergeFieldComparison> _getComparisons() {
    if (_sourceUser == null || _targetUser == null) return [];
    final src = _sourceUser!;
    final tgt = _targetUser!;
    final srcData = src.rawData;
    final tgtData = tgt.rawData;

    final srcRet = (srcData['retention'] ?? '').toString().trim();
    final tgtRet = (tgtData['retention'] ?? '').toString().trim();

    final srcFom = (srcData['fomento'] ?? '').toString().trim();
    final tgtFom = (tgtData['fomento'] ?? '').toString().trim();

    final srcCuo = (srcData['cuota'] ?? '').toString().trim();
    final tgtCuo = (tgtData['cuota'] ?? '').toString().trim();

    final srcSalaryHist = (srcData['salary_history'] as List?) ?? [];
    final tgtSalaryHist = (tgtData['salary_history'] as List?) ?? [];
    final srcJornadaHist = (srcData['jornada_history'] as List?) ?? [];
    final tgtJornadaHist = (tgtData['jornada_history'] as List?) ?? [];

    final srcRestStr =
        src.restDays.isNotEmpty ? src.restDays.join(', ') : 'Ninguno';
    final tgtRestStr =
        tgt.restDays.isNotEmpty ? tgt.restDays.join(', ') : 'Ninguno';

    return [
      MergeFieldComparison(
        key: 'turnos',
        title: 'Turnos en historial',
        icon: Icons.calendar_month_outlined,
        sourceValue: '${src.shiftCount} turnos',
        targetValue: '${tgt.shiftCount} turnos',
        isDifferent: src.shiftCount != tgt.shiftCount,
        hasSourceData: src.shiftCount > 0,
      ),
      MergeFieldComparison(
        key: 'sueldo',
        title: 'Sueldo diario',
        icon: Icons.attach_money_rounded,
        sourceValue: '\$ ${src.salary}',
        targetValue: '\$ ${tgt.salary}',
        isDifferent: src.salary != tgt.salary,
        hasSourceData: src.salary.isNotEmpty &&
            src.salary != '0' &&
            src.salary != '0.00',
      ),
      MergeFieldComparison(
        key: 'jornada',
        title: 'Jornada laboral',
        icon: Icons.schedule_rounded,
        sourceValue: '${src.baseHours} hrs',
        targetValue: '${tgt.baseHours} hrs',
        isDifferent: src.baseHours != tgt.baseHours,
        hasSourceData: src.baseHours.isNotEmpty && src.baseHours != '0',
      ),
      MergeFieldComparison(
        key: 'descansos',
        title: 'Días de descanso',
        icon: Icons.weekend_outlined,
        sourceValue: srcRestStr,
        targetValue: tgtRestStr,
        isDifferent: srcRestStr != tgtRestStr,
        hasSourceData: src.restDays.isNotEmpty,
      ),
      MergeFieldComparison(
        key: 'retencion',
        title: 'Retención ISR',
        icon: Icons.receipt_long_outlined,
        sourceValue: srcRet.isNotEmpty ? srcRet : 'Sin asignar',
        targetValue: tgtRet.isNotEmpty ? tgtRet : 'Sin asignar',
        isDifferent: srcRet != tgtRet,
        hasSourceData: srcRet.isNotEmpty,
      ),
      MergeFieldComparison(
        key: 'fomento',
        title: 'Fomento al ahorro',
        icon: Icons.savings_outlined,
        sourceValue: srcFom.isNotEmpty ? srcFom : 'Sin asignar',
        targetValue: tgtFom.isNotEmpty ? tgtFom : 'Sin asignar',
        isDifferent: srcFom != tgtFom,
        hasSourceData: srcFom.isNotEmpty,
      ),
      MergeFieldComparison(
        key: 'cuota',
        title: 'Cuota sindical',
        icon: Icons.account_balance_outlined,
        sourceValue: srcCuo.isNotEmpty ? srcCuo : 'Sin asignar',
        targetValue: tgtCuo.isNotEmpty ? tgtCuo : 'Sin asignar',
        isDifferent: srcCuo != tgtCuo,
        hasSourceData: srcCuo.isNotEmpty,
      ),
      MergeFieldComparison(
        key: 'historial_aumentos',
        title: 'Historial aumentos / vigencias',
        icon: Icons.trending_up_rounded,
        sourceValue:
            '${srcSalaryHist.length} aumentos, ${srcJornadaHist.length} jornadas',
        targetValue:
            '${tgtSalaryHist.length} aumentos, ${tgtJornadaHist.length} jornadas',
        isDifferent: srcSalaryHist.length != tgtSalaryHist.length ||
            srcJornadaHist.length != tgtJornadaHist.length,
        hasSourceData: srcSalaryHist.isNotEmpty || srcJornadaHist.isNotEmpty,
      ),
      MergeFieldComparison(
        key: 'nombre',
        title: 'Nombre',
        icon: Icons.person_outline,
        sourceValue: src.firstName.isNotEmpty ? src.firstName : '(Vacío)',
        targetValue: tgt.firstName.isNotEmpty ? tgt.firstName : '(Vacío)',
        isDifferent: src.firstName.trim() != tgt.firstName.trim(),
        hasSourceData: src.firstName.trim().isNotEmpty,
      ),
      MergeFieldComparison(
        key: 'apellido',
        title: 'Apellido',
        icon: Icons.badge_outlined,
        sourceValue: src.lastName.isNotEmpty ? src.lastName : '(Vacío)',
        targetValue: tgt.lastName.isNotEmpty ? tgt.lastName : '(Vacío)',
        isDifferent: src.lastName.trim() != tgt.lastName.trim(),
        hasSourceData: src.lastName.trim().isNotEmpty,
      ),
      MergeFieldComparison(
        key: 'no_empleado',
        title: 'No. de Empleado',
        icon: Icons.pin_outlined,
        sourceValue: src.employeeNumber.isNotEmpty
            ? src.employeeNumber
            : '(Sin número)',
        targetValue: tgt.employeeNumber.isNotEmpty
            ? tgt.employeeNumber
            : '(Sin número)',
        isDifferent: src.employeeNumber.trim() != tgt.employeeNumber.trim(),
        hasSourceData: src.employeeNumber.trim().isNotEmpty,
      ),
    ];
  }

  void _initFieldSelections() {
    if (_sourceUser == null || _targetUser == null) return;
    if (_sourceUser!.uid == _targetUser!.uid) return;

    final comparisons = _getComparisons();
    for (var c in comparisons) {
      // Pre-check fields where Donante has data OR differs from Receptora
      _selectedFields[c.key] = c.hasSourceData || c.isDifferent;
    }
    _exactReplacement = true;
    _sendPasswordResetPostMerge = true;
  }

  Future<void> _confirmAndExecuteMerge() async {
    if (_sourceUser == null || _targetUser == null) return;

    if (_sourceUser!.uid == _targetUser!.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("La cuenta origen y la cuenta destino son la misma."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final selectedKeys = _selectedFields.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toSet();

    if (selectedKeys.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("Selecciona al menos un campo en la matriz para transferir."),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    int orphanDocsCount = 0;
    if (selectedKeys.contains('turnos') && _exactReplacement) {
      try {
        final srcSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(_sourceUser!.uid)
            .collection('history')
            .get();
        final tgtSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(_targetUser!.uid)
            .collection('history')
            .get();
        final srcIds = srcSnap.docs.map((d) => d.id).toSet();
        orphanDocsCount =
            tgtSnap.docs.where((d) => !srcIds.contains(d.id)).length;
      } catch (_) {
        orphanDocsCount = 0;
      }
    }

    if (!mounted) return;

    final comparisons = _getComparisons();
    final selectedComparisons =
        comparisons.where((c) => selectedKeys.contains(c.key)).toList();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _border),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withAlpha(40),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: Colors.amber, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "¿Confirmar Fusión?",
                style: TextStyle(
                  color: _textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Estás a punto de aplicar ${selectedKeys.length} campos seleccionados en la cuenta destino (${_targetUser!.fullName}):",
                style: TextStyle(color: _textPrimary, fontSize: 14),
              ),
              const SizedBox(height: 14),
              ...selectedComparisons.map((c) {
                if (c.key == 'turnos') {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildBulletItem(
                      "📦 ${c.title}:",
                      "${c.sourceValue} serán transferidos.${_exactReplacement ? (orphanDocsCount > 0 ? ' Se ELIMINARÁN $orphanDocsCount turnos huérfanos en destino para reemplazo exacto.' : ' (0 huérfanos a eliminar en destino)') : ' (Se conservan turnos existentes en destino no coincidentes).'}",
                      highlightColor: _exactReplacement && orphanDocsCount > 0
                          ? Colors.redAccent
                          : Colors.amber,
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildBulletItem(
                    "• ${c.title}:",
                    "${c.sourceValue}  ➔  reemplaza: ${c.targetValue}",
                  ),
                );
              }),
              const SizedBox(height: 10),
              _buildBulletItem(
                "⚠️ Eliminación Definitiva:",
                "La cuenta origen (${_sourceUser!.fullName}, UID: ${_sourceUser!.uid}) y todos sus registros (historial y configuración) serán ELIMINADOS POR COMPLETO de Firestore sin dejar cuentas fantasma.",
                highlightColor: Colors.redAccent,
              ),
              const SizedBox(height: 6),
              _buildBulletItem(
                "🔑 Acceso Post-Fusión:",
                _sendPasswordResetPostMerge
                    ? "Se enviará un correo de restablecimiento de contraseña a ${_targetUser!.email} para ingresar a la cuenta receptora."
                    : "Se conservará la contraseña actual de la cuenta destino sin enviar correos.",
                highlightColor: Colors.amber,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text("CANCELAR",
                style: TextStyle(
                    color: _textSecondary, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              _executeMerge();
            },
            child: const Text(
              "SÍ, EJECUTAR FUSIÓN",
              style: TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletItem(String title, String body, {Color? highlightColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: highlightColor ?? Colors.amber,
                fontSize: 13)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(body,
              style: TextStyle(color: _textSecondary, fontSize: 13)),
        ),
      ],
    );
  }

  Future<void> _executeMerge() async {
    final source = _sourceUser;
    final target = _targetUser;
    if (source == null || target == null) return;

    final selectedKeys = _selectedFields.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toSet();
    if (selectedKeys.isEmpty) return;

    setState(() {
      _isMerging = true;
      _mergeStatus = "Iniciando proceso de consolidación selectiva...";
      _mergeProgress = 0.05;
    });

    try {
      int copiedCount = 0;
      int deletedCount = 0;
      final List<String> appliedFieldsSummary = [];

      // 1. History copy & orphan replacement
      if (selectedKeys.contains('turnos')) {
        if (mounted) {
          setState(() {
            _mergeStatus = "Descargando historial de turnos de origen...";
            _mergeProgress = 0.10;
          });
        }

        final sourceHistorySnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(source.uid)
            .collection('history')
            .get();

        // Exact replacement: delete orphans in target
        if (_exactReplacement) {
          if (mounted) {
            setState(() {
              _mergeStatus =
                  "Analizando turnos huérfanos en cuenta destino...";
              _mergeProgress = 0.20;
            });
          }

          final targetHistorySnap = await FirebaseFirestore.instance
              .collection('users')
              .doc(target.uid)
              .collection('history')
              .get();

          final sourceIds = sourceHistorySnap.docs.map((d) => d.id).toSet();
          final orphanDocs = targetHistorySnap.docs
              .where((d) => !sourceIds.contains(d.id))
              .toList();

          if (orphanDocs.isNotEmpty) {
            for (int i = 0; i < orphanDocs.length; i += 400) {
              final end = math.min(i + 400, orphanDocs.length);
              final chunk = orphanDocs.sublist(i, end);
              final batch = FirebaseFirestore.instance.batch();
              for (var doc in chunk) {
                batch.delete(doc.reference);
                deletedCount++;
              }
              if (mounted) {
                setState(() {
                  _mergeStatus =
                      "Eliminando turnos huérfanos ($deletedCount de ${orphanDocs.length})...";
                  _mergeProgress =
                      0.20 + (0.15 * (deletedCount / orphanDocs.length));
                });
              }
              await batch.commit();
            }
          }
        }

        // Copy source history docs into target with deep copy
        final totalDocs = sourceHistorySnap.docs.length;
        if (totalDocs > 0) {
          for (int i = 0; i < totalDocs; i += 400) {
            final end = math.min(i + 400, totalDocs);
            final chunk = sourceHistorySnap.docs.sublist(i, end);
            final batch = FirebaseFirestore.instance.batch();

            for (var doc in chunk) {
              final targetDocRef = FirebaseFirestore.instance
                  .collection('users')
                  .doc(target.uid)
                  .collection('history')
                  .doc(doc.id);
              final Map<String, dynamic> docData =
                  Map<String, dynamic>.from(doc.data());
              batch.set(targetDocRef, docData,
                  SetOptions(merge: !_exactReplacement));
              copiedCount++;
            }

            if (mounted) {
              setState(() {
                _mergeStatus =
                    "Copiando turnos ($copiedCount de $totalDocs)...";
                _mergeProgress =
                    0.35 + (0.45 * (copiedCount / totalDocs));
              });
            }

            await batch.commit();
          }
        }

        appliedFieldsSummary.add(
            "Turnos en historial: $copiedCount transferidos${_exactReplacement ? ' ($deletedCount huérfanos eliminados)' : ''}");
      }

      // 2. Profile and Payroll updates
      final Map<String, dynamic> targetProfileUpdates = {
        'merged_from': source.uid,
        'last_merged_at': FieldValue.serverTimestamp(),
      };

      final srcData = source.rawData;

      if (selectedKeys.contains('sueldo')) {
        targetProfileUpdates['salary'] = srcData['salary'] ?? source.salary;
        appliedFieldsSummary.add("Sueldo diario: \$${source.salary}");
      }

      if (selectedKeys.contains('jornada')) {
        targetProfileUpdates['base_hours'] =
            srcData['base_hours'] ?? source.baseHours;
        appliedFieldsSummary.add("Jornada laboral: ${source.baseHours} hrs");
      }

      if (selectedKeys.contains('descansos')) {
        targetProfileUpdates['rest_days'] =
            srcData['rest_days'] ?? source.restDays;
        if (srcData['rest_days_history'] != null) {
          targetProfileUpdates['rest_days_history'] =
              List<dynamic>.from(srcData['rest_days_history']);
        }
        appliedFieldsSummary.add(
            "Días de descanso: ${source.restDays.isNotEmpty ? source.restDays.join(', ') : 'Ninguno'}");
      }

      if (selectedKeys.contains('retencion')) {
        final ret = (srcData['retention'] ?? '').toString();
        targetProfileUpdates['retention'] = ret;
        if (srcData['retention_history'] != null) {
          targetProfileUpdates['retention_history'] =
              List<dynamic>.from(srcData['retention_history']);
        }
        appliedFieldsSummary
            .add("Retención ISR: ${ret.isNotEmpty ? ret : 'Sin asignar'}");
      }

      if (selectedKeys.contains('fomento')) {
        final fom = (srcData['fomento'] ?? '').toString();
        targetProfileUpdates['fomento'] = fom;
        if (srcData['fomento_history'] != null) {
          targetProfileUpdates['fomento_history'] =
              List<dynamic>.from(srcData['fomento_history']);
        }
        appliedFieldsSummary
            .add("Fomento al ahorro: ${fom.isNotEmpty ? fom : 'Sin asignar'}");
      }

      if (selectedKeys.contains('cuota')) {
        final cuo = (srcData['cuota'] ?? '').toString();
        targetProfileUpdates['cuota'] = cuo;
        if (srcData['cuota_history'] != null) {
          targetProfileUpdates['cuota_history'] =
              List<dynamic>.from(srcData['cuota_history']);
        }
        appliedFieldsSummary
            .add("Cuota sindical: ${cuo.isNotEmpty ? cuo : 'Sin asignar'}");
      }

      if (selectedKeys.contains('historial_aumentos')) {
        targetProfileUpdates['salary_history'] =
            List<dynamic>.from(srcData['salary_history'] ?? []);
        targetProfileUpdates['jornada_history'] =
            List<dynamic>.from(srcData['jornada_history'] ?? []);
        appliedFieldsSummary.add(
            "Historial de aumentos/vigencias: ${((srcData['salary_history'] as List?) ?? []).length} registros");
      }

      if (selectedKeys.contains('nombre')) {
        final fn =
            (srcData['first_name'] ?? source.firstName).toString().trim();
        targetProfileUpdates['first_name'] = fn;
        appliedFieldsSummary.add("Nombre: $fn");
      }

      if (selectedKeys.contains('apellido')) {
        final ln = (srcData['last_name'] ?? source.lastName).toString().trim();
        targetProfileUpdates['last_name'] = ln;
        appliedFieldsSummary.add("Apellido: $ln");
      }

      final empNo = (srcData['user_emp'] ??
              srcData['employee_number'] ??
              source.employeeNumber)
          .toString()
          .trim();

      if (selectedKeys.contains('no_empleado')) {
        if (empNo.isNotEmpty) {
          targetProfileUpdates['user_emp'] = empNo;
          targetProfileUpdates['employee_number'] = empNo;
          appliedFieldsSummary.add("No. Empleado: $empNo");
        }
      }

      if (mounted) {
        setState(() {
          _mergeStatus =
              "Actualizando datos seleccionados en cuenta destino...";
          _mergeProgress = 0.88;
        });
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(target.uid)
          .set(targetProfileUpdates, SetOptions(merge: true));

      // 3. Update employee_directory if No. Empleado was selected
      if (selectedKeys.contains('no_empleado') && empNo.isNotEmpty) {
        if (mounted) {
          setState(() {
            _mergeStatus = "Sincronizando directorio para No. $empNo...";
            _mergeProgress = 0.94;
          });
        }
        final realEmail = (target.email.isNotEmpty &&
                !target.email.endsWith('@televisa.com'))
            ? target.email
            : (target.recoveryEmail.isNotEmpty
                ? target.recoveryEmail
                : source.recoveryEmail);

        await FirebaseFirestore.instance
            .collection('employee_directory')
            .doc(empNo)
            .set({
          'uid': target.uid,
          'email': realEmail,
          'employee_number': empNo,
          'legacy_email': "$empNo@televisa.com",
          'last_merged_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        appliedFieldsSummary.add("Directorio: No. $empNo vinculado a $realEmail");
      }

      // 4. Overhaul donor handling: recursively delete all docs in users/{source.uid}/history, settings, and delete users/{source.uid} (hard purge, no ghost accounts)
      if (mounted) {
        setState(() {
          _mergeStatus = "Eliminando historial de cuenta origen...";
          _mergeProgress = 0.94;
        });
      }

      final sourceHistoryDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(source.uid)
          .collection('history')
          .get();

      if (sourceHistoryDocs.docs.isNotEmpty) {
        for (int i = 0; i < sourceHistoryDocs.docs.length; i += 400) {
          final end = math.min(i + 400, sourceHistoryDocs.docs.length);
          final chunk = sourceHistoryDocs.docs.sublist(i, end);
          final batch = FirebaseFirestore.instance.batch();
          for (final doc in chunk) {
            batch.delete(doc.reference);
          }
          await batch.commit();
        }
      }

      if (mounted) {
        setState(() {
          _mergeStatus = "Eliminando configuración de cuenta origen...";
          _mergeProgress = 0.96;
        });
      }

      final sourceSettingsDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(source.uid)
          .collection('settings')
          .get();

      if (sourceSettingsDocs.docs.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (final doc in sourceSettingsDocs.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      // Also clean up unit_managers if source was registered
      await FirebaseFirestore.instance
          .collection('unit_managers')
          .doc(source.uid)
          .delete()
          .catchError((_) {});

      if (mounted) {
        setState(() {
          _mergeStatus = "Eliminando cuenta origen de Firestore...";
          _mergeProgress = 0.98;
        });
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(source.uid)
          .delete();
      appliedFieldsSummary.add(
          "Cuenta origen (${source.uid}): Eliminada por completo de Firestore (hard purge, sin cuentas fantasma)");

      // 5. Post-merge password handling
      if (_sendPasswordResetPostMerge) {
        final targetRecipientEmail = (target.email.isNotEmpty &&
                !target.email.endsWith('@televisa.com'))
            ? target.email
            : (target.recoveryEmail.isNotEmpty
                ? target.recoveryEmail
                : target.email);

        if (targetRecipientEmail.isNotEmpty &&
            !targetRecipientEmail.endsWith('@televisa.com')) {
          if (mounted) {
            setState(() {
              _mergeStatus =
                  "Enviando restablecimiento de contraseña a $targetRecipientEmail...";
              _mergeProgress = 0.99;
            });
          }
          try {
            await FirebaseAuth.instance
                .sendPasswordResetEmail(email: targetRecipientEmail.trim());
            appliedFieldsSummary.add(
                "Contraseña: Enlace de restablecimiento enviado a $targetRecipientEmail");
          } catch (e) {
            appliedFieldsSummary.add(
                "Contraseña: No se pudo enviar el correo de restablecimiento ($e)");
          }
        } else {
          appliedFieldsSummary.add(
              "Contraseña: No se envió correo (la cuenta destino no cuenta con un correo externo válido)");
        }
      } else {
        appliedFieldsSummary.add(
            "Contraseña: Se conservó la contraseña actual de la cuenta destino");
      }

      if (mounted) {
        setState(() {
          _mergeProgress = 1.0;
          _isMerging = false;
        });
      }

      // Refresh previews
      final refreshedSource = await _lookupUser(source.uid);
      final refreshedTarget = await _lookupUser(target.uid);
      if (mounted) {
        setState(() {
          _sourceUser = refreshedSource;
          _targetUser = refreshedTarget;
          if (_sourceUser == null) {
            _sourceController.clear();
          }
          _initFieldSelections();
        });
      }

      // Notify external listener (e.g. AdminPortalScaffold to reload metrics)
      widget.onMergeComplete?.call();

      // Show success modal
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: _border),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(40),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: Colors.greenAccent, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "¡Fusión Completada con Éxito!",
                  style: TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Se aplicaron los siguientes campos seleccionados en ${target.fullName}:",
                  style: TextStyle(color: _textPrimary, fontSize: 14),
                ),
                const SizedBox(height: 14),
                ...appliedFieldsSummary.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _buildBulletItem("✅", item,
                          highlightColor: Colors.greenAccent),
                    )),
                const SizedBox(height: 8),
                _buildBulletItem("🗑️ Depuración de Origen:",
                    "Cuenta origen eliminada por completo de Firestore (sin cuentas fantasma).",
                    highlightColor: Colors.orangeAccent),
                _buildBulletItem("🔑 Acceso Post-Fusión:",
                    _sendPasswordResetPostMerge
                        ? "Enlace de restablecimiento enviado a la cuenta destino."
                        : "Contraseña actual de la cuenta destino conservada."),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text("ENTENDIDO",
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } on FirebaseException catch (fe) {
      if (!mounted) return;
      setState(() => _isMerging = false);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: _surface,
          title: const Row(
            children: [
              Icon(Icons.error_outline_rounded,
                  color: Colors.redAccent, size: 28),
              SizedBox(width: 10),
              Text("Error de Firebase",
                  style: TextStyle(color: Colors.redAccent)),
            ],
          ),
          content: Text(
            fe.code == 'permission-denied'
                ? "Permiso Denegado en Firestore (permission-denied).\n\nAsegúrate de actualizar las Reglas de Seguridad en la Consola de Firebase para que el administrador tenga permisos de lectura y escritura sobre todas las cuentas de usuario."
                : "Error (${fe.code}): ${fe.message}",
            style: TextStyle(color: _textPrimary, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("CERRAR"),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isMerging = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error durante la fusión: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildSelectiveCopyMatrix() {
    final comparisons = _getComparisons();
    final selectedCount = _selectedFields.values.where((v) => v).length;

    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withAlpha(120), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(widget.isDarkMode ? 30 : 10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Title & Quick Select buttons
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.table_chart_rounded,
                    color: Colors.amber, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "MATRIZ DE COPIA SELECTIVA",
                      style: TextStyle(
                        color: _textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      "$selectedCount de ${comparisons.length} campos seleccionados para transferir",
                      style: TextStyle(color: _textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 4,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: _isMerging
                        ? null
                        : () {
                            setState(() {
                              for (var k in _selectedFields.keys) {
                                _selectedFields[k] = true;
                              }
                            });
                          },
                    child: const Text("Todos",
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber)),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: _isMerging
                        ? null
                        : () {
                            setState(() {
                              for (var k in _selectedFields.keys) {
                                _selectedFields[k] = false;
                              }
                            });
                          },
                    child: Text("Ninguno",
                        style: TextStyle(fontSize: 12, color: _textSecondary)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: _border, height: 1),
          const SizedBox(height: 12),

          // Column labels for comparison
          LayoutBuilder(
            builder: (context, headerConstraints) {
              final bool isNarrow = headerConstraints.maxWidth < 460;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.isDarkMode
                      ? Colors.white.withAlpha(8)
                      : Colors.grey.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 38),
                    Expanded(
                      flex: 3,
                      child: Text(
                        "CAMPO",
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Colors.amber,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              isNarrow ? "DONANTE" : "DONANTE (ORIGEN)",
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Colors.blueAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              isNarrow ? "RECEPTORA" : "RECEPTORA (DESTINO)",
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          // List of matrix rows
          ...comparisons.map((item) => _buildMatrixRow(item)),
        ],
      ),
    );
  }

  Widget _buildMatrixRow(MergeFieldComparison item) {
    final isChecked = _selectedFields[item.key] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isChecked
            ? (widget.isDarkMode
                ? Colors.amber.withAlpha(12)
                : Colors.amber.withAlpha(15))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isChecked
              ? Colors.amber.withAlpha(widget.isDarkMode ? 80 : 100)
              : _border,
          width: isChecked ? 1.2 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Checkbox
              SizedBox(
                width: 28,
                height: 28,
                child: Checkbox(
                  value: isChecked,
                  onChanged: _isMerging
                      ? null
                      : (val) {
                          setState(() {
                            _selectedFields[item.key] = val ?? false;
                          });
                        },
                  activeColor: Colors.amber,
                  checkColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Icon & Title
              Icon(item.icon,
                  size: 18, color: isChecked ? Colors.amber : _textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        color: _textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (item.isDifferent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withAlpha(35),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "Difiere",
                          style: TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else if (item.hasSourceData)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(30),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "Idéntico",
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Values comparison box: Donante vs Receptora
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 420;
                if (isCompact) {
                  return Column(
                    children: [
                      _buildValueBox(
                        label: "Donante",
                        value: item.sourceValue,
                        color: Colors.amber,
                        isCompact: true,
                      ),
                      const SizedBox(height: 6),
                      _buildValueBox(
                        label: "Receptora",
                        value: item.targetValue,
                        color: Colors.blueAccent,
                        isCompact: true,
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: _buildValueBox(
                        label: "Donante",
                        value: item.sourceValue,
                        color: Colors.amber,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_forward_rounded,
                          size: 16, color: Colors.white38),
                    ),
                    Expanded(
                      child: _buildValueBox(
                        label: "Receptora",
                        value: item.targetValue,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // If turnos and checked, render Reemplazo Exacto toggle
          if (item.key == 'turnos' && isChecked) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _exactReplacement
                      ? Colors.amber.withAlpha(widget.isDarkMode ? 25 : 20)
                      : Colors.white.withAlpha(widget.isDarkMode ? 10 : 25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _exactReplacement
                        ? Colors.amber.withAlpha(100)
                        : _border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _exactReplacement
                          ? Icons.delete_sweep_rounded
                          : Icons.library_add_check_rounded,
                      size: 16,
                      color: _exactReplacement
                          ? Colors.amber
                          : _textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Reemplazo exacto: eliminar turnos huérfanos en destino",
                            style: TextStyle(
                              color: _exactReplacement
                                  ? Colors.amber
                                  : _textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            "Borra los turnos de destino que no existen en origen para que queden idénticos.",
                            style: TextStyle(
                                color: _textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _exactReplacement,
                      onChanged: _isMerging
                          ? null
                          : (val) =>
                              setState(() => _exactReplacement = val),
                      activeColor: Colors.amber,
                      activeTrackColor: Colors.amber.withAlpha(80),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPostMergePasswordSelection() {
    final targetEmail = _targetUser != null
        ? ((_targetUser!.email.isNotEmpty &&
                !_targetUser!.email.endsWith('@televisa.com'))
            ? _targetUser!.email
            : (_targetUser!.recoveryEmail.isNotEmpty
                ? _targetUser!.recoveryEmail
                : _targetUser!.email))
        : '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(widget.isDarkMode ? 40 : 25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.password_rounded,
                    color: Colors.amber, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Acceso y Contraseña Post-Fusión",
                      style: TextStyle(
                        color: _textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      "Selecciona cómo accederá el usuario a la cuenta receptora al terminar.",
                      style: TextStyle(color: _textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Option 1: Send Password Reset
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: _isMerging
                ? null
                : () => setState(() => _sendPasswordResetPostMerge = true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _sendPasswordResetPostMerge
                    ? Colors.amber.withAlpha(widget.isDarkMode ? 25 : 20)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _sendPasswordResetPostMerge
                      ? Colors.amber.withAlpha(120)
                      : _border,
                ),
              ),
              child: Row(
                children: [
                  Radio<bool>(
                    value: true,
                    groupValue: _sendPasswordResetPostMerge,
                    onChanged: _isMerging
                        ? null
                        : (val) =>
                            setState(() => _sendPasswordResetPostMerge = val!),
                    activeColor: Colors.amber,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Enviar restablecimiento de contraseña",
                          style: TextStyle(
                            color: _sendPasswordResetPostMerge
                                ? Colors.amber
                                : _textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          targetEmail.isNotEmpty
                              ? "Enviará un correo de restablecimiento a $targetEmail."
                              : "Enviará un correo a la dirección de la cuenta destino para configurar contraseña nueva.",
                          style: TextStyle(
                            color: _textSecondary,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Option 2: Keep current password
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: _isMerging
                ? null
                : () => setState(() => _sendPasswordResetPostMerge = false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: !_sendPasswordResetPostMerge
                    ? Colors.amber.withAlpha(widget.isDarkMode ? 25 : 20)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: !_sendPasswordResetPostMerge
                      ? Colors.amber.withAlpha(120)
                      : _border,
                ),
              ),
              child: Row(
                children: [
                  Radio<bool>(
                    value: false,
                    groupValue: _sendPasswordResetPostMerge,
                    onChanged: _isMerging
                        ? null
                        : (val) =>
                            setState(() => _sendPasswordResetPostMerge = val!),
                    activeColor: Colors.amber,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Conservar contraseña actual de la cuenta destino",
                          style: TextStyle(
                            color: !_sendPasswordResetPostMerge
                                ? Colors.amber
                                : _textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          "No se enviará ningún correo. El usuario mantendrá la contraseña que ya tiene configurada.",
                          style: TextStyle(
                            color: _textSecondary,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueBox({
    required String label,
    required String value,
    required Color color,
    bool isCompact = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(widget.isDarkMode ? 20 : 15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: color.withAlpha(35),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: _textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(AdminUserSummary? user, {required bool isSource}) {
    if (user == null) return const SizedBox.shrink();

    final cardBorder = isSource ? Colors.amber : Colors.blueAccent;
    final cardBadgeColor = isSource ? Colors.amber : Colors.blueAccent;

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder.withAlpha(120), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(widget.isDarkMode ? 30 : 10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cardBadgeColor.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isSource ? "ORIGEN (DONANTE)" : "DESTINO (RECEPTORA)",
                  style: TextStyle(
                    color: cardBadgeColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (user.isUnitManager) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.cyan.withAlpha(35),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.cyan.withAlpha(100)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shield_rounded,
                              size: 13, color: Colors.cyanAccent),
                          const SizedBox(width: 4),
                          Text("Ing. Unidad",
                              style: TextStyle(
                                  color: widget.isDarkMode
                                      ? Colors.cyanAccent
                                      : const Color(0xFF0284C7),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (user.isMerged)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.orange.withAlpha(35),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.orange.withAlpha(100)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              color: Colors.orange, size: 14),
                          SizedBox(width: 4),
                          Text("Archivada",
                              style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(35),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text("Activa",
                          style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            user.fullName,
            style: TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "UID: ${user.uid}",
            style: TextStyle(
              color: _textSecondary,
              fontSize: 11.5,
              fontFamily: 'monospace',
            ),
          ),
          Divider(color: _border, height: 20),
          Row(
            children: [
              Expanded(
                child: _buildDetailTile(
                  icon: Icons.badge_outlined,
                  label: "No. Empleado",
                  value: user.employeeNumber.isNotEmpty
                      ? user.employeeNumber
                      : "Sin número",
                ),
              ),
              Expanded(
                child: _buildDetailTile(
                  icon: Icons.calendar_month_outlined,
                  label: "Turnos en Historial",
                  value: "${user.shiftCount} turnos",
                  highlight: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildDetailTile(
                  icon: Icons.email_outlined,
                  label: "Correo",
                  value: user.email.isNotEmpty
                      ? user.email
                      : (user.recoveryEmail.isNotEmpty
                          ? user.recoveryEmail
                          : "Sin correo"),
                ),
              ),
              Expanded(
                child: _buildDetailTile(
                  icon: Icons.attach_money_rounded,
                  label: "Sueldo Base",
                  value: "\$ ${user.salary}",
                ),
              ),
            ],
          ),
          if (user.isMerged && user.mergedInto != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Nota: Esta cuenta ya fue fusionada previamente hacia: ${user.mergedInto}",
                style: const TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailTile({
    required IconData icon,
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: _textSecondary),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(color: _textSecondary, fontSize: 11.5)),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: highlight ? Colors.amber : _textPrimary,
            fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
            fontSize: 13.5,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final canMerge = _sourceUser != null &&
        _targetUser != null &&
        _sourceUser!.uid != _targetUser!.uid &&
        !_isMerging &&
        _selectedFields.values.any((selected) => selected);

    return Scaffold(
      backgroundColor: _bg,
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              backgroundColor:
                  widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Panel de Administración",
              style: TextStyle(
                color: _textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  "Fusión de Cuentas de Usuario",
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.withAlpha(widget.isDarkMode ? 30 : 25),
                    Colors.orange.withAlpha(widget.isDarkMode ? 15 : 10),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.amber.withAlpha(widget.isDarkMode ? 90 : 120),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.merge_type_rounded,
                      color: Colors.amber, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Consolidación de Cuentas",
                          style: TextStyle(
                            color: _textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Transfiere el historial de turnos y ajustes de una cuenta creada con número de empleado hacia la cuenta definitiva con correo personal.",
                          style: TextStyle(
                            color: _textSecondary,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // -------------------------------------------------------------
            // SECTION 1: CUENTA ORIGEN
            // -------------------------------------------------------------
            const Text(
              "1. CUENTA ORIGEN (HISTORIAL)",
              style: TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sourceController,
                    style: TextStyle(color: _textPrimary, fontSize: 14),
                    onSubmitted: (_) {
                      _sourceDebounceTimer?.cancel();
                      setState(() => _isDebouncingSource = false);
                      _searchSource();
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: _surface,
                      hintText: "No. empleado o correo (ej. 12345)",
                      hintStyle: TextStyle(color: _textSecondary, fontSize: 13),
                      prefixIcon: const Icon(Icons.person_search_outlined,
                          color: Colors.amber, size: 20),
                      suffixIcon: _buildSourceSuffixIcon(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Colors.amber, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 13),
                  ),
                  onPressed: (_isSearchingSource || _isDebouncingSource)
                      ? null
                      : () {
                          _sourceDebounceTimer?.cancel();
                          setState(() => _isDebouncingSource = false);
                          _searchSource();
                        },
                  child: (_isSearchingSource || _isDebouncingSource)
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : const Text(
                          "BUSCAR",
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
            if (_sourceError != null) ...[
              const SizedBox(height: 8),
              Text(
                _sourceError!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12.5),
              ),
            ],
            _buildAccountCard(_sourceUser, isSource: true),

            const SizedBox(height: 28),

            // -------------------------------------------------------------
            // SECTION 2: CUENTA DESTINO
            // -------------------------------------------------------------
            const Text(
              "2. CUENTA DESTINO (RECEPTORA)",
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _targetController,
                    style: TextStyle(color: _textPrimary, fontSize: 14),
                    onSubmitted: (_) {
                      _targetDebounceTimer?.cancel();
                      setState(() => _isDebouncingTarget = false);
                      _searchTarget();
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: _surface,
                      hintText: "Correo personal (ej. nombre@gmail.com)",
                      hintStyle: TextStyle(color: _textSecondary, fontSize: 13),
                      prefixIcon: const Icon(Icons.person_add_alt_outlined,
                          color: Colors.blueAccent, size: 20),
                      suffixIcon: _buildTargetSuffixIcon(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Colors.blueAccent, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 13),
                  ),
                  onPressed: (_isSearchingTarget || _isDebouncingTarget)
                      ? null
                      : () {
                          _targetDebounceTimer?.cancel();
                          setState(() => _isDebouncingTarget = false);
                          _searchTarget();
                        },
                  child: (_isSearchingTarget || _isDebouncingTarget)
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          "BUSCAR",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
            if (_targetError != null) ...[
              const SizedBox(height: 8),
              Text(
                _targetError!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12.5),
              ),
            ],
            _buildAccountCard(_targetUser, isSource: false),

            const SizedBox(height: 32),

            // -------------------------------------------------------------
            // SECTION 3: COMPARACIÓN Y ACCIÓN
            // -------------------------------------------------------------
            if (_sourceUser != null && _targetUser != null) ...[
              if (_sourceUser!.uid == _targetUser!.uid)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent.withAlpha(120)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.redAccent),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "La cuenta origen y destino son la misma. Selecciona dos cuentas diferentes.",
                          style:
                              TextStyle(color: Colors.redAccent, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                // Selective Copy Matrix Card
                _buildSelectiveCopyMatrix(),

                const SizedBox(height: 20),

                // Post-merge Password Selection Card
                _buildPostMergePasswordSelection(),

                const SizedBox(height: 20),

                // Transfer Progress
                if (_isMerging) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.amber),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _mergeStatus,
                                style: TextStyle(
                                  color: _textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: _mergeProgress,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.amber),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                ElevatedButton.icon(
                  icon: const Icon(Icons.merge_type_rounded,
                      color: Colors.black, size: 24),
                  label: Text(
                    _isMerging
                        ? "FUSIONANDO CUENTAS..."
                        : "EJECUTAR FUSIÓN DE CUENTAS",
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    disabledBackgroundColor: Colors.amber.withAlpha(120),
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                  ),
                  onPressed: canMerge ? _confirmAndExecuteMerge : null,
                ),
              ],
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ADMIN PORTAL SCAFFOLD (EXCLUSIVE CONSOLE FOR ADMIN USERS)
// ---------------------------------------------------------------------------
class AdminPortalScaffold extends StatefulWidget {
  const AdminPortalScaffold({super.key});

  @override
  State<AdminPortalScaffold> createState() => _AdminPortalScaffoldState();
}

class _AdminPortalScaffoldState extends State<AdminPortalScaffold> {
  int _currentTab = 0;
  bool _isDarkMode = true;

  // Metric variables
  bool _isLoadingMetrics = true;
  String? _metricsError;
  int _totalUsers = 0;
  int _activeUsers = 0;
  int _mergedUsers = 0;
  int _realEmailUsers = 0;
  int _directoryCount = 0;
  int _unitManagerCount = 0;

  List<Map<String, dynamic>> _userList = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _loadAdminMetrics();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredUsers = List.from(_userList);
      });
      return;
    }

    setState(() {
      _filteredUsers = _userList.where((u) {
        final name = (u['name'] ?? '').toString().toLowerCase();
        final emp = (u['emp'] ?? '').toString().toLowerCase();
        final email = (u['email'] ?? '').toString().toLowerCase();
        final rec = (u['recEmail'] ?? '').toString().toLowerCase();
        final uid = (u['uid'] ?? '').toString().toLowerCase();
        final role = (u['role'] ?? '').toString().toLowerCase();
        final isUnitMgr = u['isUnitManager'] == true;
        final matchesRole = (query == 'ing' ||
                query == 'unidad' ||
                query == 'ingeniero' ||
                query == 'manager') &&
            isUnitMgr;

        return name.contains(query) ||
            emp.contains(query) ||
            email.contains(query) ||
            rec.contains(query) ||
            uid.contains(query) ||
            role.contains(query) ||
            matchesRole;
      }).toList();
    });
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isDarkMode = prefs.getBool('app_is_dark_mode') ?? true;
      });
    }
  }

  Future<void> _toggleTheme() async {
    setState(() => _isDarkMode = !_isDarkMode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_is_dark_mode', _isDarkMode);
  }

  Future<void> _loadAdminMetrics() async {
    if (!mounted) return;
    setState(() {
      _isLoadingMetrics = true;
      _metricsError = null;
    });

    try {
      final usersSnap =
          await FirebaseFirestore.instance.collection('users').get();
      final dirSnap = await FirebaseFirestore.instance
          .collection('employee_directory')
          .get();

      int active = 0;
      int merged = 0;
      int realEmail = 0;
      int unitManagers = 0;
      final List<Map<String, dynamic>> list = [];

      for (final doc in usersSnap.docs) {
        final d = doc.data();
        final isMerged = d['is_merged'] == true;
        if (isMerged) {
          merged++;
        } else {
          active++;
        }

        final bool isUnitMgr = d['is_unit_manager'] == true ||
            d['role'] == 'ingeniero_de_unidad';
        final String role =
            (d['role'] ?? (isUnitMgr ? 'ingeniero_de_unidad' : 'empleado'))
                .toString();

        if (isUnitMgr) unitManagers++;

        final email = (d['email'] ?? '').toString().trim().toLowerCase();
        final rec =
            (d['recovery_email'] ?? '').toString().trim().toLowerCase();
        final isReal = (email.isNotEmpty && !email.endsWith('@televisa.com')) ||
            (rec.isNotEmpty && !rec.endsWith('@televisa.com')) ||
            d['is_new_style_user'] == true;

        if (isReal) realEmail++;

        final fName =
            (d['first_name'] ?? d['firstName'] ?? '').toString().trim();
        final lName =
            (d['last_name'] ?? d['lastName'] ?? '').toString().trim();
        final fullName = (fName.isNotEmpty || lName.isNotEmpty)
            ? "$fName $lName".trim()
            : (d['name'] ?? 'Sin nombre').toString().trim();

        final emp =
            (d['employee_number'] ?? d['user_emp'] ?? '').toString().trim();

        list.add({
          'uid': doc.id,
          'name': fullName.isEmpty ? 'Sin nombre' : fullName,
          'emp': emp,
          'email': email,
          'recEmail': rec,
          'isMerged': isMerged,
          'mergedInto': d['merged_into']?.toString() ?? '',
          'isRealEmail': isReal,
          'isUnitManager': isUnitMgr,
          'role': role,
        });
      }

      // Sort: active accounts first, then by employee number
      list.sort((a, b) {
        if (a['isMerged'] != b['isMerged']) {
          return a['isMerged'] ? 1 : -1;
        }
        return (a['emp'] as String).compareTo(b['emp'] as String);
      });

      // Sync unit_managers directory for quick cross-user manager search
      try {
        final existingMgrsSnap =
            await FirebaseFirestore.instance.collection('unit_managers').get();
        final existingMgrIds = existingMgrsSnap.docs.map((d) => d.id).toSet();
        final currentMgrs = list
            .where((u) => u['isUnitManager'] == true && u['isMerged'] != true)
            .toList();
        final currentMgrIds = currentMgrs.map((u) => u['uid'] as String).toSet();

        final syncBatch = FirebaseFirestore.instance.batch();
        bool hasSyncOps = false;

        for (final mgr in currentMgrs) {
          final mUid = mgr['uid'] as String;
          syncBatch.set(
            FirebaseFirestore.instance.collection('unit_managers').doc(mUid),
            {
              'uid': mUid,
              'name': mgr['name'],
              'employee_number': mgr['emp'],
              'role': 'ingeniero_de_unidad',
              'is_unit_manager': true,
              'synced_at': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
          hasSyncOps = true;
        }

        for (final oldId in existingMgrIds) {
          if (!currentMgrIds.contains(oldId)) {
            syncBatch.delete(
                FirebaseFirestore.instance.collection('unit_managers').doc(oldId));
            hasSyncOps = true;
          }
        }

        if (hasSyncOps) {
          await syncBatch.commit();
        }
      } catch (e) {
        debugPrint("Notice: could not sync unit_managers during admin metrics load: $e");
      }

      if (mounted) {
        setState(() {
          _totalUsers = usersSnap.docs.length;
          _activeUsers = active;
          _mergedUsers = merged;
          _realEmailUsers = realEmail;
          _directoryCount = dirSnap.docs.length;
          _unitManagerCount = unitManagers;
          _userList = list;
          _filteredUsers = List.from(list);
          _isLoadingMetrics = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _metricsError = e.toString();
          _isLoadingMetrics = false;
        });
      }
    }
  }

  Future<void> _promptToggleUnitManager({
    required String uid,
    required String userName,
    required String employeeNumber,
    required bool currentIsUnitManager,
  }) async {
    final bool newStatus = !currentIsUnitManager;
    final String actionText = newStatus ? "Asignar" : "Revocar";
    final Color actionColor = newStatus
        ? (_isDarkMode ? Colors.cyanAccent : const Color(0xFF0284C7))
        : Colors.amber.shade800;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            _isDarkMode ? const Color(0xFF1E1E26) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              newStatus ? Icons.shield_rounded : Icons.shield_outlined,
              color: actionColor,
              size: 26,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "$actionText Ingeniero de Unidad",
                style: TextStyle(
                  color: _textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Usuario objetivo:",
              style: TextStyle(color: _textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              userName,
              style: TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (employeeNumber.isNotEmpty)
              Text(
                "No. Empleado: $employeeNumber",
                style: TextStyle(color: _textSecondary, fontSize: 13),
              ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: actionColor.withAlpha(_isDarkMode ? 35 : 25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: actionColor.withAlpha(80)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: actionColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      newStatus
                          ? "El usuario recibirá el rol de 'Ingeniero de Unidad' y acceso a herramientas de gestión de personal y supervisión."
                          : "Se revocarán los permisos de 'Ingeniero de Unidad' y el usuario volverá al rol estándar de empleado.",
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              "CANCELAR",
              style: TextStyle(
                color: _isDarkMode ? Colors.white60 : Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: actionColor,
              foregroundColor:
                  newStatus && _isDarkMode ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              newStatus ? "ASIGNAR ROL" : "REVOCAR ROL",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      batch.set(userRef, {
        'is_unit_manager': newStatus,
        'role': newStatus ? 'ingeniero_de_unidad' : 'empleado',
        'role_updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final mgrRef =
          FirebaseFirestore.instance.collection('unit_managers').doc(uid);
      if (newStatus) {
        batch.set(mgrRef, {
          'uid': uid,
          'name': userName,
          'employee_number': employeeNumber,
          'role': 'ingeniero_de_unidad',
          'is_unit_manager': true,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        batch.delete(mgrRef);
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus
                  ? "Rol 'Ingeniero de Unidad' asignado con éxito a $userName"
                  : "Rol 'Ingeniero de Unidad' revocado a $userName",
            ),
            backgroundColor: newStatus ? Colors.teal : Colors.amber.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      await _loadAdminMetrics();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al actualizar rol: $e"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _promptSendPasswordReset({
    required String userName,
    required String displayEmail,
    required String employeeNumber,
  }) async {
    final cleanEmail = displayEmail.trim();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Este usuario no cuenta con un correo electrónico válido registrado."),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _border),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.cyan.withAlpha(_isDarkMode ? 40 : 25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_reset_rounded,
                color: Colors.cyanAccent,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Restablecer Contraseña",
                style: TextStyle(
                  color: _textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "¿Deseas enviar un enlace de restablecimiento de contraseña para este usuario?",
              style: TextStyle(color: _textSecondary, fontSize: 13.5),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: TextStyle(
                      color: _textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (employeeNumber.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      "No. Empleado: $employeeNumber",
                      style: TextStyle(color: _textSecondary, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        color: _isDarkMode
                            ? Colors.cyanAccent
                            : const Color(0xFF0284C7),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          cleanEmail,
                          style: TextStyle(
                            color: _isDarkMode
                                ? Colors.cyanAccent
                                : const Color(0xFF0284C7),
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              "CANCELAR",
              style: TextStyle(
                color: _textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isDarkMode
                  ? Colors.cyanAccent
                  : const Color(0xFF0284C7),
              foregroundColor: _isDarkMode ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "SÍ, ENVIAR CORREO",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: cleanEmail);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Correo de restablecimiento enviado exitosamente a $cleanEmail",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al enviar correo: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _showChangeEmailDialog({
    required String uid,
    required String userName,
    required String currentEmail,
    required String employeeNumber,
  }) async {
    final emailController = TextEditingController(text: currentEmail);
    final formKey = GlobalKey<FormState>();
    bool isUpdating = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: _border),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.withAlpha(_isDarkMode ? 40 : 25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.alternate_email_rounded,
                  color: _isDarkMode
                      ? Colors.tealAccent
                      : const Color(0xFF0D9488),
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Cambiar Correo",
                  style: TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Actualiza el correo principal y de recuperación de la cuenta.",
                    style: TextStyle(color: _textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: TextStyle(
                            color: _textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                        if (employeeNumber.isNotEmpty)
                          Text(
                            "No. Empleado: $employeeNumber",
                            style:
                                TextStyle(color: _textSecondary, fontSize: 12),
                          ),
                        Text(
                          "UID: $uid",
                          style: TextStyle(
                            color: _textSecondary.withAlpha(180),
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Nuevo correo electrónico:",
                    style: TextStyle(
                      color: _textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: emailController,
                    enabled: !isUpdating,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: _textPrimary),
                    decoration: InputDecoration(
                      hintText: "ejemplo@correo.com",
                      hintStyle: TextStyle(color: _textSecondary),
                      prefixIcon: Icon(Icons.email_outlined,
                          color: _textSecondary, size: 20),
                      filled: true,
                      fillColor: _cardBg,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: _border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: _border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: _isDarkMode
                              ? Colors.tealAccent
                              : const Color(0xFF0D9488),
                          width: 1.5,
                        ),
                      ),
                    ),
                    validator: (val) {
                      final str = val?.trim() ?? '';
                      if (str.isEmpty) {
                        return "Por favor ingresa un correo.";
                      }
                      if (!str.contains('@') || !str.contains('.')) {
                        return "Ingresa un formato de correo válido.";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Se actualizarán los campos email y recovery_email en users/$uid, y se sincronizará con employee_directory${employeeNumber.isNotEmpty ? '/$employeeNumber' : ''}.",
                    style: TextStyle(color: _textSecondary, fontSize: 11.5),
                  ),
                  if (isUpdating) ...[
                    const SizedBox(height: 14),
                    const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isUpdating ? null : () => Navigator.pop(dialogCtx),
              child: Text(
                "CANCELAR",
                style: TextStyle(
                  color: _textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isDarkMode
                    ? Colors.tealAccent
                    : const Color(0xFF0D9488),
                foregroundColor: _isDarkMode ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: isUpdating
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      final newEmail = emailController.text.trim();
                      final nav = Navigator.of(dialogCtx);
                      final messenger = ScaffoldMessenger.of(this.context);
                      setDialogState(() => isUpdating = true);

                      try {
                        final batch = FirebaseFirestore.instance.batch();
                        final userRef = FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid);

                        batch.set(
                          userRef,
                          {
                            'email': newEmail,
                            'recovery_email': newEmail,
                            'updated_at': FieldValue.serverTimestamp(),
                          },
                          SetOptions(merge: true),
                        );

                        if (employeeNumber.isNotEmpty) {
                          final dirRef = FirebaseFirestore.instance
                              .collection('employee_directory')
                              .doc(employeeNumber);
                          batch.set(
                            dirRef,
                            {
                              'email': newEmail,
                              'uid': uid,
                              'employee_number': employeeNumber,
                              'updated_at': FieldValue.serverTimestamp(),
                            },
                            SetOptions(merge: true),
                          );
                        }

                        await batch.commit();

                        if (mounted) {
                          setState(() {
                            // Update locally in user lists
                            for (var userMap in _userList) {
                              if (userMap['uid'] == uid) {
                                userMap['email'] = newEmail;
                                userMap['recEmail'] = newEmail;
                                userMap['isRealEmail'] =
                                    !newEmail.endsWith('@televisa.com');
                              }
                            }
                            _onSearchChanged();
                          });

                          nav.pop();

                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                "Correo actualizado correctamente a $newEmail",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: Colors.teal.shade700,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isUpdating = false);
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text("Error al actualizar correo: $e"),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    },
              child: const Text(
                "GUARDAR CORREO",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            _isDarkMode ? const Color(0xFF1E1E26) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 26),
            const SizedBox(width: 10),
            Text(
              "Cerrar Sesión",
              style: TextStyle(
                color: _isDarkMode ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          "¿Estás seguro de que deseas salir del Panel de Administración?",
          style: TextStyle(
            color: _isDarkMode ? Colors.white70 : const Color(0xFF475569),
            fontSize: 15,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              "CANCELAR",
              style: TextStyle(
                color: _isDarkMode ? Colors.white60 : Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "SALIR",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Copiado $label al portapapeles: $text"),
        backgroundColor: Colors.amber.shade800,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color get _bg =>
      _isDarkMode ? const Color(0xFF0F0F12) : const Color(0xFFF8FAFC);
  Color get _surface =>
      _isDarkMode ? const Color(0xFF16161D) : Colors.white;
  Color get _cardBg =>
      _isDarkMode ? const Color(0xFF1C1C24) : Colors.white;
  Color get _border =>
      _isDarkMode ? Colors.white12 : const Color(0xFFE2E8F0);
  Color get _textPrimary =>
      _isDarkMode ? Colors.white : const Color(0xFF0F172A);
  Color get _textSecondary =>
      _isDarkMode ? Colors.white70 : const Color(0xFF64748B);

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              Text(
                title,
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              color: _textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: _textSecondary,
              fontSize: 11,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildResumenTab() {
    if (_isLoadingMetrics) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              "Cargando métricas de usuarios...",
              style: TextStyle(color: _textSecondary, fontSize: 15),
            ),
          ],
        ),
      );
    }

    if (_metricsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              Text(
                "Error al cargar métricas",
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _metricsError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: _textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh, color: Colors.black),
                label: const Text("REINTENTAR",
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                onPressed: _loadAdminMetrics,
              ),
            ],
          ),
        ),
      );
    }

    final double adoptionPercent =
        _totalUsers > 0 ? (_realEmailUsers / _totalUsers * 100) : 0.0;

    return RefreshIndicator(
      onRefresh: _loadAdminMetrics,
      color: Colors.amber,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Welcome / Overview Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Resumen del Sistema",
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Cuentas, directorio y estado de migración",
                      style: TextStyle(color: _textSecondary, fontSize: 14),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.amber),
                  tooltip: "Actualizar métricas",
                  onPressed: _loadAdminMetrics,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 4 Metrics Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 700;
                final crossAxisCount = isWide ? 4 : 2;
                final aspectRatio = isWide ? 1.6 : 1.35;

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: aspectRatio,
                  children: [
                    _buildMetricCard(
                      title: "TOTAL CUENTAS",
                      value: "$_totalUsers",
                      subtitle: "Colección users",
                      icon: Icons.groups_rounded,
                      gradient: const [Color(0xFF4F46E5), Color(0xFF6366F1)],
                    ),
                    _buildMetricCard(
                      title: "ACTIVAS",
                      value: "$_activeUsers",
                      subtitle: "Sin fusionar",
                      icon: Icons.verified_user_rounded,
                      gradient: const [Color(0xFF059669), Color(0xFF10B981)],
                    ),
                    _buildMetricCard(
                      title: "FUSIONADAS",
                      value: "$_mergedUsers",
                      subtitle: "Cuentas archivadas",
                      icon: Icons.archive_rounded,
                      gradient: const [Color(0xFFD97706), Color(0xFFF59E0B)],
                    ),
                    _buildMetricCard(
                      title: "DIRECTORIO",
                      value: "$_directoryCount",
                      subtitle: "Mapeos emp_dir",
                      icon: Icons.badge_rounded,
                      gradient: const [Color(0xFF0284C7), Color(0xFF38BDF8)],
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // Adoption Progress Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.mark_email_read_rounded,
                              color: Colors.amber, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            "Adopción de Correo Real",
                            style: TextStyle(
                              color: _textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withAlpha(_isDarkMode ? 35 : 25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.amber.withAlpha(90)),
                        ),
                        child: Text(
                          "${adoptionPercent.toStringAsFixed(1)}%",
                          style: const TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _totalUsers > 0
                          ? (_realEmailUsers / _totalUsers).clamp(0.0, 1.0)
                          : 0.0,
                      minHeight: 10,
                      backgroundColor:
                          _isDarkMode ? Colors.white12 : const Color(0xFFE2E8F0),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.amber),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "$_realEmailUsers de $_totalUsers cuentas registradas usan correo personal/institucional (@gmail, @outlook, etc.).",
                    style: TextStyle(color: _textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Search Header
            Row(
              children: [
                const Icon(Icons.person_search_rounded,
                    color: Colors.amber, size: 24),
                const SizedBox(width: 10),
                Text(
                  "Explorador de Usuarios",
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  _unitManagerCount > 0
                      ? "Mostrando ${_filteredUsers.length} de $_totalUsers ($_unitManagerCount Ing. Unidad)"
                      : "Mostrando ${_filteredUsers.length} de $_totalUsers",
                  style: TextStyle(color: _textSecondary, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Search TextField
            TextField(
              controller: _searchController,
              style: TextStyle(color: _textPrimary),
              decoration: InputDecoration(
                hintText:
                    "Buscar por No. Empleado, nombre, correo o UID...",
                hintStyle: TextStyle(color: _textSecondary),
                prefixIcon:
                    Icon(Icons.search_rounded, color: _textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon:
                            Icon(Icons.clear_rounded, color: _textSecondary),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: _cardBg,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.amber, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Users List
            if (_filteredUsers.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(Icons.search_off_rounded,
                        color: _textSecondary, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      "No se encontraron cuentas con ese criterio",
                      style: TextStyle(color: _textSecondary, fontSize: 15),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredUsers.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final u = _filteredUsers[index];
                  final bool isMerged = u['isMerged'] == true;
                  final bool isUnitManager = u['isUnitManager'] == true;
                  final String emp = u['emp'] ?? '';
                  final String name = u['name'] ?? 'Sin nombre';
                  final String email = u['email'] ?? '';
                  final String rec = u['recEmail'] ?? '';
                  final String uid = u['uid'] ?? '';
                  final String displayEmail =
                      (email.isNotEmpty && !email.endsWith('@televisa.com'))
                          ? email
                          : (rec.isNotEmpty ? rec : email);

                  final Color unitManagerColor = _isDarkMode
                      ? Colors.cyanAccent
                      : const Color(0xFF0284C7);

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isMerged
                            ? Colors.orange.withAlpha(_isDarkMode ? 80 : 100)
                            : (isUnitManager
                                ? unitManagerColor.withAlpha(_isDarkMode ? 90 : 110)
                                : _border),
                        width: isUnitManager && !isMerged ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar Circle
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: isMerged
                              ? Colors.orange.withAlpha(40)
                              : (isUnitManager
                                  ? unitManagerColor.withAlpha(_isDarkMode ? 40 : 30)
                                  : Colors.amber.withAlpha(40)),
                          child: Text(
                            emp.isNotEmpty
                                ? emp.substring(0, 1)
                                : (name.isNotEmpty ? name.substring(0, 1) : '?'),
                            style: TextStyle(
                              color: isMerged
                                  ? Colors.orange
                                  : (isUnitManager
                                      ? unitManagerColor
                                      : Colors.amber),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Details Column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                        color: _textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (isMerged)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withAlpha(40),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        "FUSIONADO",
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withAlpha(40),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        "ACTIVO",
                                        style: TextStyle(
                                          color: Colors.greenAccent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  if (isUnitManager) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: unitManagerColor.withAlpha(_isDarkMode ? 35 : 25),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: unitManagerColor.withAlpha(120),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.shield_rounded,
                                            size: 11,
                                            color: unitManagerColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "ING. DE UNIDAD",
                                            style: TextStyle(
                                              color: unitManagerColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (emp.isNotEmpty) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: _border,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        "No. $emp",
                                        style: TextStyle(
                                          color: _textPrimary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Flexible(
                                    child: Text(
                                      displayEmail.isNotEmpty
                                          ? displayEmail
                                          : uid,
                                      style: TextStyle(
                                        color: _textSecondary,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              if (isMerged && u['mergedInto'] != '')
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    "Destino UID: ${u['mergedInto']}",
                                    style: TextStyle(
                                      color: Colors.orange.shade300,
                                      fontSize: 11,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Actions
                        IconButton(
                          icon: Icon(
                            isUnitManager
                                ? Icons.shield_rounded
                                : Icons.shield_outlined,
                            color: isUnitManager
                                ? unitManagerColor
                                : _textSecondary,
                            size: 22,
                          ),
                          tooltip: isUnitManager
                              ? "Revocar Ingeniero de Unidad"
                              : "Asignar Ingeniero de Unidad",
                          onPressed: () => _promptToggleUnitManager(
                            uid: uid,
                            userName: name,
                            employeeNumber: emp,
                            currentIsUnitManager: isUnitManager,
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert_rounded,
                              color: _textSecondary, size: 20),
                          tooltip: "Más opciones",
                          color: _cardBg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: _border),
                          ),
                          onSelected: (val) {
                            if (val == 'toggle_unit_manager') {
                              _promptToggleUnitManager(
                                uid: uid,
                                userName: name,
                                employeeNumber: emp,
                                currentIsUnitManager: isUnitManager,
                              );
                            } else if (val == 'send_reset') {
                              _promptSendPasswordReset(
                                userName: name,
                                displayEmail: displayEmail,
                                employeeNumber: emp,
                              );
                            } else if (val == 'change_email') {
                              _showChangeEmailDialog(
                                uid: uid,
                                userName: name,
                                currentEmail: displayEmail,
                                employeeNumber: emp,
                              );
                            } else if (val == 'copy_uid') {
                              _copyToClipboard(uid, "UID");
                            } else if (val == 'migrate') {
                              final targetQuery =
                                  emp.isNotEmpty ? emp : displayEmail;
                              _copyToClipboard(targetQuery, "identificador");
                              setState(() => _currentTab = 1);
                            }
                          },
                          itemBuilder: (ctx) => [
                            PopupMenuItem(
                              value: 'toggle_unit_manager',
                              child: Row(
                                children: [
                                  Icon(
                                    isUnitManager
                                        ? Icons.shield_outlined
                                        : Icons.shield_rounded,
                                    color: isUnitManager
                                        ? Colors.amber.shade800
                                        : unitManagerColor,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    isUnitManager
                                        ? "Revocar Ingeniero de Unidad"
                                        : "Asignar Ingeniero de Unidad",
                                    style: TextStyle(
                                      color: _textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'send_reset',
                              child: Row(
                                children: [
                                  Icon(Icons.lock_reset_rounded,
                                      color: _isDarkMode
                                          ? Colors.cyanAccent
                                          : const Color(0xFF0284C7),
                                      size: 18),
                                  const SizedBox(width: 10),
                                  Text(
                                    "Enviar Restablecimiento",
                                    style: TextStyle(
                                        color: _textPrimary, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'change_email',
                              child: Row(
                                children: [
                                  Icon(Icons.alternate_email_rounded,
                                      color: _isDarkMode
                                          ? Colors.tealAccent
                                          : const Color(0xFF0D9488),
                                      size: 18),
                                  const SizedBox(width: 10),
                                  Text(
                                    "Cambiar Correo",
                                    style: TextStyle(
                                        color: _textPrimary, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'copy_uid',
                              child: Row(
                                children: [
                                  Icon(Icons.copy_rounded,
                                      color: _textSecondary, size: 18),
                                  const SizedBox(width: 10),
                                  Text(
                                    "Copiar UID",
                                    style: TextStyle(
                                        color: _textPrimary, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'migrate',
                              child: Row(
                                children: [
                                  const Icon(Icons.merge_type_rounded,
                                      color: Colors.amber, size: 18),
                                  const SizedBox(width: 10),
                                  Text(
                                    "Migrar cuenta",
                                    style: TextStyle(
                                        color: _textPrimary, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMigracionTab() {
    return AdminAccountMergeScreen(
      isDarkMode: _isDarkMode,
      isEmbedded: true,
      onMergeComplete: _loadAdminMetrics,
    );
  }

  Widget _buildAjustesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Ajustes de Administración",
            style: TextStyle(
              color: _textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Configuración del portal e identidad administrativa",
            style: TextStyle(color: _textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 20),

          // Admin Identity Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.withAlpha(_isDarkMode ? 30 : 25),
                  Colors.orange.withAlpha(_isDarkMode ? 15 : 10),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.amber.withAlpha(_isDarkMode ? 90 : 120),
              ),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.amber,
                  child: Icon(Icons.admin_panel_settings_rounded,
                      color: Colors.black, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            "Super Administrador",
                            style: TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withAlpha(40),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              "ROOT",
                              style: TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        kAdminEmail,
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "UID: $kAdminUid",
                        style: TextStyle(color: _textSecondary, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, color: Colors.amber),
                  tooltip: "Copiar UID del Administrador",
                  onPressed: () =>
                      _copyToClipboard(kAdminUid, "UID Administrador"),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Appearance Card
          Container(
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: SwitchListTile(
              secondary: Icon(
                _isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: Colors.amber,
              ),
              title: Text(
                _isDarkMode ? "Modo Oscuro" : "Modo Luz de Día",
                style: TextStyle(
                  color: _textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                _isDarkMode
                    ? "Tema de alto contraste nocturno"
                    : "Tema luminoso para luz natural",
                style: TextStyle(color: _textSecondary, fontSize: 13),
              ),
              value: _isDarkMode,
              activeColor: Colors.amber,
              onChanged: (_) => _toggleTheme(),
            ),
          ),

          const SizedBox(height: 20),

          // System Info Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Información del Sistema",
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow("Versión Aplicación", "v.23.17.0 04/11/26"),
                const Divider(height: 20),
                _buildInfoRow("Entorno", "Firebase Production (Hosting & Firestore)"),
                const Divider(height: 20),
                _buildInfoRow("Reglas de Seguridad",
                    "Bypass Superadmin Activo (minominapro@gmail.com)"),
                const Divider(height: 20),
                _buildInfoRow("Modo Operativo", "Consola Administrativa Exclusiva"),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Logout Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.shade700,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: const Text(
              "CERRAR SESIÓN DE ADMINISTRADOR",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            onPressed: _confirmSignOut,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: _textSecondary, fontSize: 13)),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.amber.withAlpha(_isDarkMode ? 35 : 25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withAlpha(90)),
              ),
              child: const Icon(Icons.shield_rounded,
                  color: Colors.amber, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Mi Nómina Pro",
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  "PORTAL DE ADMINISTRACIÓN",
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              color: Colors.amber,
            ),
            tooltip: _isDarkMode ? "Modo Luz de Día" : "Modo Oscuro",
            onPressed: _toggleTheme,
          ),
          IconButton(
            icon: Icon(Icons.logout_rounded, color: Colors.redAccent.shade100),
            tooltip: "Cerrar sesión",
            onPressed: _confirmSignOut,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentTab,
        children: [
          _buildResumenTab(),
          _buildMigracionTab(),
          _buildAjustesTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _surface,
          border: Border(top: BorderSide(color: _border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTab,
          onTap: (index) {
            setState(() => _currentTab = index);
            if (index == 0) {
              _loadAdminMetrics();
            }
          },
          backgroundColor: _surface,
          selectedItemColor: Colors.amber,
          unselectedItemColor: _textSecondary,
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics_rounded),
              label: "Resumen",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.merge_type_outlined),
              activeIcon: Icon(Icons.merge_type_rounded),
              label: "Migración",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings_outlined),
              activeIcon: Icon(Icons.admin_panel_settings_rounded),
              label: "Ajustes Admin",
            ),
          ],
        ),
      ),
    );
  }
}



