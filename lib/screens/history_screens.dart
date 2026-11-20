part of '../main.dart';

class ParameterHistoryResult {
  final List<Map<String, dynamic>> history;
  final double? baseValue;

  ParameterHistoryResult({required this.history, this.baseValue});
}

class ParameterHistoryScreen extends StatefulWidget {
  final String title;
  final String unitPrefix;
  final String unitSuffix;
  final double currentValue;
  final List<Map<String, dynamic>> history;
  final bool isDarkMode;
  final IconData icon;
  final bool isSalary;
  final Future<void> Function(List<Map<String, dynamic>> updatedHistory, double newActiveValue)? onCommit;

  const ParameterHistoryScreen({
    super.key,
    required this.title,
    required this.unitPrefix,
    required this.unitSuffix,
    required this.currentValue,
    required this.history,
    required this.isDarkMode,
    required this.icon,
    this.isSalary = false,
    this.onCommit,
  });

  @override
  State<ParameterHistoryScreen> createState() => _ParameterHistoryScreenState();
}

class _ParameterHistoryScreenState extends State<ParameterHistoryScreen> {
  late List<Map<String, dynamic>> _localHistory;
  late double _localBaseValue;

  @override
  void initState() {
    super.initState();
    _localHistory =
        widget.history.map((e) => Map<String, dynamic>.from(e)).toList();
    _sortHistory();
    _localBaseValue = widget.currentValue;
    final bool healed = _ensureTimelineActiveContinuity();
    if (healed && widget.onCommit != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onCommit?.call(_localHistory, _todayActiveValue);
      });
    }
  }

  void _sortHistory() {
    _localHistory.sort((a, b) {
      final sA = _parseEntryDate(a['start_date'] ?? a['effective_date']) ??
          DateTime(1970);
      final sB = _parseEntryDate(b['start_date'] ?? b['effective_date']) ??
          DateTime(1970);
      return sB.compareTo(sA);
    });
  }

  bool _ensureTimelineActiveContinuity() {
    if (_localHistory.isEmpty) {
      _localBaseValue = widget.currentValue;
      return false;
    }

    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);

    final int? activeIdx = _todayActivePeriodIndex;
    final bool hasActiveOpenEnded = activeIdx != null &&
        _parseEntryDate(_localHistory[activeIdx]['end_date']) == null;

    final bool hasFutureOpenEnded = _localHistory.any((entry) {
      final s = _parseEntryDate(entry['start_date'] ?? entry['effective_date']);
      final e = _parseEntryDate(entry['end_date']);
      return s != null && s.isAfter(todayMidnight) && e == null;
    });

    final bool needsReopen =
        !hasActiveOpenEnded && (!hasFutureOpenEnded || activeIdx == null);

    if (needsReopen) {
      Map<String, dynamic>? candidate;
      for (final entry in _localHistory) {
        final s =
            _parseEntryDate(entry['start_date'] ?? entry['effective_date']);
        if (s != null && !todayMidnight.isBefore(s)) {
          candidate = entry;
          break;
        }
      }
      candidate ??= _localHistory.first;

      candidate['end_date'] = null;
      _sortHistory();

      final reopenedVal =
          (candidate['value'] ?? candidate['salary'] as num?)?.toDouble();
      if (reopenedVal != null) {
        _localBaseValue = reopenedVal;
      } else {
        _localBaseValue = _todayActiveValue;
      }
      return true;
    } else {
      _localBaseValue = _todayActiveValue;
      return false;
    }
  }

  String _formatValue(double val) {
    String numStr = val.toStringAsFixed(
        val.truncateToDouble() == val ? (widget.unitSuffix.contains('%') ? 2 : 1) : 2);
    return "${widget.unitPrefix}$numStr${widget.unitSuffix}";
  }

  DateTime _normalizeDate(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime? _parseEntryDate(dynamic val) {
    if (val == null) return null;
    final str = val.toString().trim();
    if (str.isEmpty || str == 'null') return null;
    final parsed = DateTime.tryParse(str);
    if (parsed == null) return null;
    return _normalizeDate(parsed);
  }

  DateTime _getAccountCreationDate() {
    final user = FirebaseAuth.instance.currentUser;
    return _normalizeDate(user?.metadata.creationTime ?? DateTime(2026, 1, 1));
  }

  int? get _todayActivePeriodIndex {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    for (int i = 0; i < _localHistory.length; i++) {
      final entry = _localHistory[i];
      final startDate = _parseEntryDate(entry['start_date'] ?? entry['effective_date']);
      if (startDate == null) continue;

      final endDate = _parseEntryDate(entry['end_date']);

      if (!todayMidnight.isBefore(startDate)) {
        if (endDate == null || !todayMidnight.isAfter(endDate)) {
          return i;
        }
      }
    }
    return null;
  }

  Map<String, dynamic>? get _todayActivePeriod {
    final idx = _todayActivePeriodIndex;
    if (idx != null && idx >= 0 && idx < _localHistory.length) {
      return _localHistory[idx];
    }
    return null;
  }

  String get _activePeriodSubtitle {
    final active = _todayActivePeriod;
    if (active != null) {
      final sStr =
          (active['start_date'] ?? active['effective_date'] ?? '').toString();
      final dt = DateTime.tryParse(sStr);
      final formatted = dt != null ? DateFormat('dd/MM/yyyy').format(dt) : sStr;
      return "Vigente desde: $formatted";
    }
    return "Sin periodo asignado";
  }

  double get _todayActiveValue =>
      getNumericParamForDate(DateTime.now(), _localHistory, _localBaseValue);

  Future<void> _showAddOrEditPeriodDialog({
    int? editIndex,
    bool isFromTopPencil = false,
  }) async {
    final isEditing = editIndex != null;
    final Map<String, dynamic>? existing =
        isEditing ? _localHistory[editIndex] : null;

    final double initialVal = existing != null
        ? ((existing['value'] ?? existing['salary'] as num?)?.toDouble() ??
            _localBaseValue)
        : (_localHistory.isEmpty ? _localBaseValue : _todayActiveValue);

    final TextEditingController valController = TextEditingController(
      text: initialVal > 0
          ? (initialVal % 1 == 0
              ? initialVal.toInt().toString()
              : initialVal.toString())
          : "",
    );

    DateTime startDate = isFromTopPencil
        ? DateTime.now()
        : (existing != null
            ? (_parseEntryDate(existing['start_date'] ??
                    existing['effective_date']) ??
                DateTime.now())
            : (_localHistory.isEmpty
                ? _getAccountCreationDate()
                : DateTime.now()));

    DateTime? endDate = existing != null
        ? _parseEntryDate(existing['end_date'])
        : null;

    bool hasEndDate = endDate != null;
    String? errorMessage;

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final Color accentColor =
              widget.isDarkMode ? Colors.orange : const Color(0xFFC2410C);
          final Color dialogBg =
              widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white;
          final Color textColor =
              widget.isDarkMode ? Colors.white : Colors.black87;

          return AlertDialog(
            backgroundColor: dialogBg,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(isEditing ? Icons.edit_calendar : Icons.add_circle_outline,
                    color: accentColor, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isEditing ? "Editar Periodo" : "Nuevo Periodo",
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Valor del parámetro:",
                    style: TextStyle(
                      color:
                          widget.isDarkMode ? Colors.white70 : Colors.black54,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: valController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      prefixText: widget.unitPrefix.isNotEmpty
                          ? widget.unitPrefix
                          : null,
                      suffixText: widget.unitSuffix.isNotEmpty
                          ? widget.unitSuffix
                          : null,
                      hintText: "Ej. 1250.00",
                      hintStyle: TextStyle(
                          color: widget.isDarkMode
                              ? Colors.white30
                              : Colors.black38),
                      filled: true,
                      fillColor: widget.isDarkMode
                          ? Colors.black26
                          : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Fecha de inicio (Vigencia desde):",
                    style: TextStyle(
                      color:
                          widget.isDarkMode ? Colors.white70 : Colors.black54,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          startDate = picked;
                          if (endDate != null && endDate!.isBefore(startDate)) {
                            endDate = startDate;
                          }
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: widget.isDarkMode
                            ? Colors.black26
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 18, color: accentColor),
                          const SizedBox(width: 10),
                          Text(
                            DateFormat('dd / MM / yyyy').format(startDate),
                            style: TextStyle(
                                color: textColor,
                                fontSize: 15,
                                fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Text("Cambiar",
                              style:
                                  TextStyle(color: accentColor, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "¿Tiene fecha de término?",
                        style: TextStyle(
                          color: widget.isDarkMode
                              ? Colors.white70
                              : Colors.black54,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Switch(
                        value: hasEndDate,
                        activeColor: accentColor,
                        onChanged: (val) {
                          setDialogState(() {
                            hasEndDate = val;
                            if (hasEndDate && endDate == null) {
                              endDate = startDate.add(const Duration(days: 30));
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  if (hasEndDate) ...[
                    const SizedBox(height: 6),
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: endDate ?? startDate,
                          firstDate: startDate,
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            endDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: widget.isDarkMode
                              ? Colors.black26
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.event_busy,
                                size: 18, color: accentColor),
                            const SizedBox(width: 10),
                            Text(
                              endDate != null
                                  ? DateFormat('dd / MM / yyyy')
                                      .format(endDate!)
                                  : "Seleccionar fecha fin",
                              style: TextStyle(
                                  color: textColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Text("Cambiar",
                                style: TextStyle(
                                    color: accentColor, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        "Vigencia abierta e indefinida hasta que se registre un nuevo periodo.",
                        style: TextStyle(
                          color: widget.isDarkMode
                              ? Colors.white38
                              : const Color(0xFF94A3B8),
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text("CANCELAR",
                    style: TextStyle(
                        color: widget.isDarkMode
                            ? Colors.white54
                            : Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  final val = double.tryParse(valController.text.trim());
                  if (val == null || val < 0) {
                    setDialogState(() {
                      errorMessage =
                          "Ingresa un valor numérico válido mayor o igual a 0.";
                    });
                    return;
                  }

                  final normStart = _normalizeDate(startDate);
                  final normEnd = (hasEndDate && endDate != null)
                      ? _normalizeDate(endDate!)
                      : null;

                  if (normEnd != null && normEnd.isBefore(normStart)) {
                    setDialogState(() {
                      errorMessage =
                          "La fecha de fin no puede ser anterior a la de inicio.";
                    });
                    return;
                  }

                  final existingStart = existing != null
                      ? _parseEntryDate(
                          existing['start_date'] ?? existing['effective_date'])
                      : null;
                  final existingEnd = existing != null
                      ? _parseEntryDate(existing['end_date'])
                      : null;

                  // Check if we are editing an active open-ended period
                  final bool isActiveOpenEnded = isEditing &&
                      existing != null &&
                      (existingEnd == null ||
                          editIndex == _todayActivePeriodIndex);

                  // If the user selected a start date strictly after the existing active period's start date,
                  // treat it as a rate transition/raise rather than an in-place overwrite.
                  final bool isNewRateTransition = isActiveOpenEnded &&
                      existingStart != null &&
                      normStart.isAfter(existingStart);

                  // Smart auto-adjustment for open-ended periods:
                  // 1) For new rate transitions: auto-close the existing period to (newStartDate - 1 day).
                  // 2) For any open-ended period save: auto-close any prior open-ended periods.
                  final Map<int, String> autoAdjustEndDates = {};

                  if (isNewRateTransition) {
                    final autoEnd = normStart.subtract(const Duration(days: 1));
                    autoAdjustEndDates[editIndex] =
                        DateFormat('yyyy-MM-dd').format(autoEnd);
                  }

                  if (normEnd == null || isNewRateTransition) {
                    for (int i = 0; i < _localHistory.length; i++) {
                      if (i == editIndex) continue;
                      final other = _localHistory[i];
                      final otherStart = _parseEntryDate(
                          other['start_date'] ?? other['effective_date']);
                      final otherEnd = _parseEntryDate(other['end_date']);

                      if (otherStart != null &&
                          otherEnd == null &&
                          otherStart.isBefore(normStart)) {
                        final autoEnd =
                            normStart.subtract(const Duration(days: 1));
                        autoAdjustEndDates[i] =
                            DateFormat('yyyy-MM-dd').format(autoEnd);
                      }
                    }
                  }

                  // Validate overlap: StartA <= EndB && StartB <= EndA
                  for (int i = 0; i < _localHistory.length; i++) {
                    if (i == editIndex) continue;
                    final other = _localHistory[i];
                    final otherStart = _parseEntryDate(
                        other['start_date'] ?? other['effective_date']);
                    if (otherStart == null) continue;

                    DateTime? otherEnd;
                    if (autoAdjustEndDates.containsKey(i)) {
                      otherEnd = _parseEntryDate(autoAdjustEndDates[i]);
                    } else {
                      otherEnd = _parseEntryDate(other['end_date']);
                    }

                    final startA = normStart;
                    final endA = (isNewRateTransition ? null : normEnd) ??
                        DateTime(2099, 12, 31);
                    final startB = otherStart;
                    final endB = otherEnd ?? DateTime(2099, 12, 31);

                    final bool overlaps =
                        !startA.isAfter(endB) && !startB.isAfter(endA);
                    if (overlaps) {
                      final String otherRangeStr = otherEnd != null
                          ? "del ${DateFormat('dd/MM/yyyy').format(startB)} al ${DateFormat('dd/MM/yyyy').format(otherEnd)}"
                          : "a partir del ${DateFormat('dd/MM/yyyy').format(startB)}";
                      setDialogState(() {
                        errorMessage =
                            "El rango seleccionado se empalma con un periodo existente ($otherRangeStr).";
                      });
                      return;
                    }
                  }

                  // Apply any auto-adjustments
                  autoAdjustEndDates.forEach((idx, newEnd) {
                    _localHistory[idx]['end_date'] = newEnd;
                  });

                  final Map<String, dynamic> newEntry = {
                    'value': val,
                    'start_date': DateFormat('yyyy-MM-dd').format(normStart),
                    'end_date': (isNewRateTransition || normEnd == null)
                        ? null
                        : DateFormat('yyyy-MM-dd').format(normEnd),
                  };
                  if (widget.isSalary) {
                    newEntry['salary'] = val;
                  }

                  setState(() {
                    if (isNewRateTransition) {
                      _localHistory.add(newEntry);
                    } else if (isEditing) {
                      _localHistory[editIndex] = newEntry;
                    } else {
                      _localHistory.add(newEntry);
                    }
                    _sortHistory();
                    _localBaseValue = _todayActiveValue;
                  });

                  Navigator.pop(dialogCtx);
                  await widget.onCommit?.call(_localHistory, _todayActiveValue);
                },
                child: const Text("GUARDAR",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showDeletePeriodDialog(int index) async {
    final entry = _localHistory[index];
    final dateStr =
        (entry['start_date'] ?? entry['effective_date'] ?? '').toString();
    final val =
        (entry['value'] ?? entry['salary'] as num?)?.toDouble() ?? 0.0;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor:
            widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        title: const Text("Eliminar Periodo",
            style: TextStyle(
                color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: Text(
          "¿Deseas eliminar el periodo que inicia el $dateStr (${_formatValue(val)})?\n\nLos cálculos para fechas en este rango volverán a usar el periodo adyacente o el valor vigente.",
          style: TextStyle(
              color: widget.isDarkMode ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text("CANCELAR",
                style: TextStyle(
                    color:
                        widget.isDarkMode ? Colors.white54 : Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text("ELIMINAR",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _localHistory.removeAt(index);
        _sortHistory();
        _ensureTimelineActiveContinuity();
      });
      await widget.onCommit?.call(_localHistory, _todayActiveValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color accentColor =
        widget.isDarkMode ? Colors.orange : const Color(0xFFC2410C);
    final Color bgColor =
        widget.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final Color cardBg =
        widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final Color borderColor =
        widget.isDarkMode ? Colors.white12 : const Color(0xFFE2E8F0);
    final Color textColor = widget.isDarkMode ? Colors.white : Colors.black87;
    final Color subtextColor =
        widget.isDarkMode ? Colors.white60 : const Color(0xFF64748B);
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor:
              widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          foregroundColor: textColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.title,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          onPressed: () => _showAddOrEditPeriodDialog(),
          icon: const Icon(Icons.add),
          label: const Text("AGREGAR PERIODO",
              style:
                  TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            // Current Active Value Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.isDarkMode
                      ? [accentColor.withAlpha(40), const Color(0xFF1E293B)]
                      : [const Color(0xFFFFF7ED), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color:
                        accentColor.withAlpha(widget.isDarkMode ? 80 : 120),
                    width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accentColor.withAlpha(35),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(widget.icon,
                            color: accentColor, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "VALOR VIGENTE HOY",
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.edit,
                            color: accentColor, size: 20),
                        tooltip: "Editar periodo vigente",
                        onPressed: () {
                          if (_todayActivePeriodIndex != null) {
                            _showAddOrEditPeriodDialog(
                                editIndex: _todayActivePeriodIndex,
                                isFromTopPencil: true);
                          } else {
                            _showAddOrEditPeriodDialog(isFromTopPencil: true);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _formatValue(_todayActiveValue),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _activePeriodSubtitle,
                    style: TextStyle(
                      color: subtextColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Header for registered periods
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "PERIODOS REGISTRADOS",
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:
                        accentColor.withAlpha(widget.isDarkMode ? 35 : 25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${_localHistory.length}",
                    style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_localHistory.isEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 36, horizontal: 20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Icon(Icons.history_toggle_off,
                        size: 48, color: subtextColor.withAlpha(120)),
                    const SizedBox(height: 12),
                    Text(
                      "Sin periodos específicos",
                      style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Actualmente se aplica ${_formatValue(_todayActiveValue)} a todas las fechas. Registra periodos para definir cambios históricos o futuros.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: subtextColor, fontSize: 13),
                    ),
                    const SizedBox(height: 18),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accentColor,
                        side: BorderSide(color: accentColor),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _showAddOrEditPeriodDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text("REGISTRAR UN PERIODO",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ..._localHistory.asMap().entries.map((entry) {
                final int index = entry.key;
                final Map<String, dynamic> item = entry.value;

                final double val =
                    ((item['value'] ?? item['salary']) as num?)?.toDouble() ??
                        0.0;
                final String sDateStr =
                    (item['start_date'] ?? item['effective_date'] ?? '')
                        .toString();
                final String? eDateStr = (item['end_date'] != null &&
                        item['end_date'].toString().isNotEmpty &&
                        item['end_date'] != 'null')
                    ? item['end_date'].toString()
                    : null;

                final DateTime? sDate = DateTime.tryParse(sDateStr);
                final DateTime? eDate =
                    eDateStr != null ? DateTime.tryParse(eDateStr) : null;

                // Status calculation
                bool isActive = false;
                bool isFuture = false;

                if (sDate != null) {
                  final sMidnight =
                      DateTime(sDate.year, sDate.month, sDate.day);
                  final eMidnight = eDate != null
                      ? DateTime(eDate.year, eDate.month, eDate.day)
                      : null;

                  if (todayMidnight.isBefore(sMidnight)) {
                    isFuture = true;
                  } else if (eMidnight != null &&
                      todayMidnight.isAfter(eMidnight)) {
                    // Past
                  } else {
                    isActive = true;
                  }
                }

                Color badgeBg;
                Color badgeText;
                String badgeLabel;

                if (isActive) {
                  badgeBg = widget.isDarkMode
                      ? Colors.green.withAlpha(35)
                      : const Color(0xFFDCFCE7);
                  badgeText = widget.isDarkMode
                      ? Colors.greenAccent
                      : const Color(0xFF15803D);
                  badgeLabel = "VIGENTE";
                } else if (isFuture) {
                  badgeBg = widget.isDarkMode
                      ? Colors.blue.withAlpha(35)
                      : const Color(0xFFDBEAFE);
                  badgeText = widget.isDarkMode
                      ? Colors.blueAccent
                      : const Color(0xFF1D4ED8);
                  badgeLabel = "FUTURO";
                } else {
                  badgeBg = widget.isDarkMode
                      ? Colors.white10
                      : const Color(0xFFF1F5F9);
                  badgeText = widget.isDarkMode
                      ? Colors.white54
                      : const Color(0xFF64748B);
                  badgeLabel = "HISTÓRICO";
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isActive
                          ? accentColor.withAlpha(
                              widget.isDarkMode ? 90 : 140)
                          : borderColor,
                      width: isActive ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _formatValue(val),
                                  style: TextStyle(
                                    color: isActive ? accentColor : textColor,
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: badgeBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    badgeLabel,
                                    style: TextStyle(
                                      color: badgeText,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.date_range,
                                    size: 14, color: subtextColor),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    sDate != null
                                        ? "Desde ${DateFormat('dd/MM/yyyy').format(sDate)}${eDate != null ? ' hasta ${DateFormat('dd/MM/yyyy').format(eDate)}' : ' (Indefinido)'}"
                                        : sDateStr,
                                    style: TextStyle(
                                      color: subtextColor,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit_outlined,
                            color: subtextColor, size: 20),
                        tooltip: "Editar periodo",
                        onPressed: () =>
                            _showAddOrEditPeriodDialog(editIndex: index),
                      ),
                      if (_localHistory.length > 1)
                        IconButton(
                          icon: Icon(Icons.delete_outline,
                              color: widget.isDarkMode
                                  ? Colors.redAccent
                                  : const Color(0xFFDC2626),
                              size: 20),
                          tooltip: "Eliminar periodo",
                          onPressed: () => _showDeletePeriodDialog(index),
                        ),
                    ],
                  ),
                );
              }),
              if (_localHistory.length == 1) ...[
                Container(
                  margin: const EdgeInsets.only(top: 4, bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.isDarkMode
                        ? accentColor.withAlpha(18)
                        : const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color:
                          accentColor.withAlpha(widget.isDarkMode ? 60 : 90),
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 18, color: accentColor),
                          const SizedBox(width: 8),
                          Text(
                            "VALOR BASE PREDETERMINADO",
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Este valor se aplica a todos los cálculos pasados y presentes. Si necesitas registrar un aumento de sueldo, cambio de jornada o fecha especial, agrega un nuevo periodo.",
                        style: TextStyle(
                          color: subtextColor,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: accentColor,
                            side: BorderSide(color: accentColor),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                          onPressed: () => _showAddOrEditPeriodDialog(),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text("REGISTRAR UN PERIODO",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class RestDaysHistoryResult {
  final List<Map<String, dynamic>> history;
  final List<int> baseRestDays;

  RestDaysHistoryResult({required this.history, required this.baseRestDays});
}

class RestDaysHistoryScreen extends StatefulWidget {
  final List<Map<String, dynamic>> history;
  final List<int> baseRestDays;
  final bool isDarkMode;
  final Future<void> Function(List<Map<String, dynamic>> updatedHistory, List<int> newBaseRestDays)? onCommit;

  const RestDaysHistoryScreen({
    super.key,
    required this.history,
    required this.baseRestDays,
    required this.isDarkMode,
    this.onCommit,
  });

  @override
  State<RestDaysHistoryScreen> createState() => _RestDaysHistoryScreenState();
}

class _RestDaysHistoryScreenState extends State<RestDaysHistoryScreen> {
  late List<Map<String, dynamic>> _localHistory;
  late List<int> _localBaseRestDays;

  static const List<String> _dialNames = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
  static const List<String> _fullNames = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo'
  ];
  static const Map<int, String> _shortNames = {
    1: 'Lun',
    2: 'Mar',
    3: 'Mié',
    4: 'Jue',
    5: 'Vie',
    6: 'Sáb',
    7: 'Dom',
  };

  @override
  void initState() {
    super.initState();
    _localHistory =
        widget.history.map((e) => Map<String, dynamic>.from(e)).toList();
    _localBaseRestDays = List<int>.from(widget.baseRestDays);
    if (_localBaseRestDays.isEmpty) {
      _localBaseRestDays = [DateTime.saturday, DateTime.sunday];
    }
    _sortHistory();
    final bool healed = _ensureTimelineActiveContinuity();
    if (healed && widget.onCommit != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onCommit?.call(_localHistory, _todayActiveRestDays);
      });
    }
  }

  DateTime? _parseEntryDate(dynamic val) {
    if (val == null) return null;
    final str = val.toString().trim();
    if (str.isEmpty || str == 'null') return null;
    final parsed = DateTime.tryParse(str);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  void _sortHistory() {
    _localHistory.sort((a, b) {
      final sA = _parseEntryDate(a['start_date'] ?? a['effective_date']) ??
          DateTime(1970);
      final sB = _parseEntryDate(b['start_date'] ?? b['effective_date']) ??
          DateTime(1970);
      return sB.compareTo(sA); // Descending (latest first)
    });
  }

  int? get _todayActivePeriodIndex {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    for (int i = 0; i < _localHistory.length; i++) {
      final entry = _localHistory[i];
      final startDate =
          _parseEntryDate(entry['start_date'] ?? entry['effective_date']);
      if (startDate == null) continue;

      final endDate = _parseEntryDate(entry['end_date']);

      if (!todayMidnight.isBefore(startDate)) {
        if (endDate == null || !todayMidnight.isAfter(endDate)) {
          return i;
        }
      }
    }
    return null;
  }

  bool _ensureTimelineActiveContinuity() {
    if (_localHistory.isEmpty) {
      return false;
    }

    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);

    final int? activeIdx = _todayActivePeriodIndex;
    final bool hasActiveOpenEnded = activeIdx != null &&
        _parseEntryDate(_localHistory[activeIdx]['end_date']) == null;

    final bool hasFutureOpenEnded = _localHistory.any((entry) {
      final s = _parseEntryDate(entry['start_date'] ?? entry['effective_date']);
      final e = _parseEntryDate(entry['end_date']);
      return s != null && s.isAfter(todayMidnight) && e == null;
    });

    final bool needsReopen =
        !hasActiveOpenEnded && (!hasFutureOpenEnded || activeIdx == null);

    if (needsReopen) {
      Map<String, dynamic>? candidate;
      for (final entry in _localHistory) {
        final s =
            _parseEntryDate(entry['start_date'] ?? entry['effective_date']);
        if (s != null && !todayMidnight.isBefore(s)) {
          candidate = entry;
          break;
        }
      }
      candidate ??= _localHistory.first;

      candidate['end_date'] = null;
      _sortHistory();

      final rawDays = candidate['rest_days'];
      if (rawDays is List) {
        final days = rawDays
            .map((e) => int.tryParse(e.toString()) ?? (e is int ? e : null))
            .whereType<int>()
            .toList();
        if (days.isNotEmpty) {
          _localBaseRestDays = days;
        }
      }
      return true;
    }
    return false;
  }

  String _formatDaysDisplay(List<int> days, {bool short = false}) {
    if (days.isEmpty) return "Ninguno";
    final sorted = List<int>.from(days)..sort();
    if (short) {
      return sorted.map((d) => _shortNames[d] ?? d.toString()).join(", ");
    }
    return sorted.map((d) => _fullNames[d - 1]).join(", ");
  }

  List<int> get _todayActiveRestDays {
    return getRestDaysForDate(
        DateTime.now(), _localHistory, _localBaseRestDays);
  }

  Widget _build7DayToggleRow({
    required List<int> selectedDays,
    required void Function(int dayNum) onToggle,
    required bool isDarkMode,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final int dayNum = index + 1;
        final bool isSelected = selectedDays.contains(dayNum);
        final bg = isSelected
            ? (isDarkMode ? Colors.orange : const Color(0xFFEA580C))
            : (isDarkMode
                ? Colors.white.withAlpha(15)
                : const Color(0xFFF1F5F9));
        final textCol = isSelected
            ? (isDarkMode ? Colors.black : Colors.white)
            : (isDarkMode ? Colors.white70 : const Color(0xFF334155));
        final border = Border.all(
          color: isSelected
              ? (isDarkMode ? Colors.orangeAccent : const Color(0xFFC2410C))
              : (isDarkMode ? Colors.white24 : const Color(0xFFCBD5E1)),
          width: isSelected ? 2 : 1,
        );

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: Tooltip(
              message: _fullNames[index],
              child: InkWell(
                onTap: () => onToggle(dayNum),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                    border: border,
                  ),
                  child: Text(
                    _dialNames[index],
                    style: TextStyle(
                      color: textCol,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Future<void> _showAddOrEditPeriodDialog({int? editIndex}) async {
    final bool isEditing = editIndex != null;
    final Map<String, dynamic>? existing =
        isEditing ? _localHistory[editIndex] : null;

    DateTime startDate;
    DateTime? endDate;
    bool hasEndDate = false;
    List<int> dialogRestDays = [];

    if (existing != null) {
      final sStr =
          (existing['start_date'] ?? existing['effective_date'] ?? '').toString();
      startDate = DateTime.tryParse(sStr) ?? DateTime.now();

      final eStr = (existing['end_date'] ?? '').toString();
      if (eStr.isNotEmpty && eStr != 'null') {
        endDate = DateTime.tryParse(eStr);
        hasEndDate = endDate != null;
      }

      final rawDays = existing['rest_days'];
      if (rawDays is List) {
        dialogRestDays = rawDays
            .map((e) => int.tryParse(e.toString()) ?? (e is int ? e : null))
            .whereType<int>()
            .where((d) => d >= 1 && d <= 7)
            .toList();
        dialogRestDays.sort();
      }
    } else {
      startDate = DateTime.now();
      dialogRestDays = List<int>.from(_todayActiveRestDays);
    }
    if (dialogRestDays.isEmpty) {
      dialogRestDays = [DateTime.saturday, DateTime.sunday];
    }

    String? errorMessage;

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final Color accentColor =
              widget.isDarkMode ? Colors.orange : const Color(0xFFC2410C);
          final Color cardBg =
              widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white;
          final Color textColor =
              widget.isDarkMode ? Colors.white : Colors.black87;

          return AlertDialog(
            scrollable: true,
            backgroundColor: cardBg,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              isEditing ? "Editar Periodo de Descanso" : "Nuevo Periodo de Descanso",
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            content: SizedBox(
              width: 340,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Días de Descanso para este periodo:",
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _build7DayToggleRow(
                    selectedDays: dialogRestDays,
                    isDarkMode: widget.isDarkMode,
                    onToggle: (dayNum) {
                      setDialogState(() {
                        if (dialogRestDays.contains(dayNum)) {
                          dialogRestDays.remove(dayNum);
                        } else {
                          dialogRestDays.add(dayNum);
                          dialogRestDays.sort();
                        }
                        errorMessage = null;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Seleccionados: ${_formatDaysDisplay(dialogRestDays, short: true)}",
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Start Date Picker
                  Text(
                    "Fecha de Inicio (Vigencia desde):",
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          startDate = picked;
                          errorMessage = null;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 11),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: widget.isDarkMode
                                ? Colors.white24
                                : Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 18, color: accentColor),
                          const SizedBox(width: 10),
                          Text(
                            DateFormat('dd/MM/yyyy').format(startDate),
                            style: TextStyle(
                              color: textColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Has End Date Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: hasEndDate,
                        activeColor: accentColor,
                        onChanged: (val) {
                          setDialogState(() {
                            hasEndDate = val ?? false;
                            if (hasEndDate && endDate == null) {
                              endDate = startDate.add(const Duration(days: 30));
                            }
                            errorMessage = null;
                          });
                        },
                      ),
                      Expanded(
                        child: Text(
                          "Periodo con fecha de fin",
                          style: TextStyle(color: textColor, fontSize: 13),
                        ),
                      ),
                    ],
                  ),

                  // End Date Picker
                  if (hasEndDate) ...[
                    const SizedBox(height: 6),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: endDate ??
                              startDate.add(const Duration(days: 30)),
                          firstDate: startDate,
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            endDate = picked;
                            errorMessage = null;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 11),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: widget.isDarkMode
                                  ? Colors.white24
                                  : Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.event_busy,
                                size: 18, color: accentColor),
                            const SizedBox(width: 10),
                            Text(
                              endDate != null
                                  ? DateFormat('dd/MM/yyyy').format(endDate!)
                                  : "Selecciona fecha de fin",
                              style: TextStyle(
                                color: textColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                      child: Text(
                        "Sin fecha de fin: Este horario de descanso aplicará indefinidamente a partir de la fecha de inicio.",
                        style: TextStyle(
                          color: widget.isDarkMode
                              ? Colors.white38
                              : const Color(0xFF94A3B8),
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text("CANCELAR",
                    style: TextStyle(
                        color: widget.isDarkMode
                            ? Colors.white54
                            : Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  if (dialogRestDays.isEmpty) {
                    setDialogState(() {
                      errorMessage =
                          "Selecciona al menos un día de descanso para este periodo.";
                    });
                    return;
                  }
                  if (hasEndDate &&
                      endDate != null &&
                      endDate!.isBefore(startDate)) {
                    setDialogState(() {
                      errorMessage =
                          "La fecha de fin no puede ser anterior a la de inicio.";
                    });
                    return;
                  }

                  final Map<String, dynamic> newEntry = {
                    'rest_days': List<int>.from(dialogRestDays)..sort(),
                    'start_date': DateFormat('yyyy-MM-dd').format(startDate),
                    'end_date': (hasEndDate && endDate != null)
                        ? DateFormat('yyyy-MM-dd').format(endDate!)
                        : null,
                  };

                  setState(() {
                    if (isEditing) {
                      _localHistory[editIndex] = newEntry;
                    } else {
                      _localHistory.add(newEntry);
                    }
                    _sortHistory();
                  });

                  Navigator.pop(dialogCtx);
                  await widget.onCommit?.call(_localHistory, _todayActiveRestDays);
                },
                child: const Text("GUARDAR",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showDeletePeriodDialog(int index) async {
    final entry = _localHistory[index];
    final dateStr =
        (entry['start_date'] ?? entry['effective_date'] ?? '').toString();
    final rawDays = entry['rest_days'];
    List<int> days = [];
    if (rawDays is List) {
      days = rawDays
          .map((e) => int.tryParse(e.toString()) ?? (e is int ? e : null))
          .whereType<int>()
          .toList();
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor:
            widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        title: const Text("Eliminar Periodo",
            style: TextStyle(
                color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: Text(
          "¿Deseas eliminar el periodo de descanso que inicia el $dateStr (${_formatDaysDisplay(days, short: true)})?\n\nLos cálculos para turnos en ese rango volverán a usar el periodo adyacente o los días base predeterminados.",
          style: TextStyle(
              color: widget.isDarkMode ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text("CANCELAR",
                style: TextStyle(
                    color:
                        widget.isDarkMode ? Colors.white54 : Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text("ELIMINAR",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _localHistory.removeAt(index);
        _sortHistory();
        _ensureTimelineActiveContinuity();
      });
      await widget.onCommit?.call(_localHistory, _todayActiveRestDays);
    }
  }

  Future<void> _showEditBaseRestDaysDialog() async {
    List<int> tempDays = List<int>.from(_localBaseRestDays);

    final updated = await showDialog<List<int>>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final Color accentColor =
              widget.isDarkMode ? Colors.orange : const Color(0xFFC2410C);
          final Color cardBg =
              widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white;

          return AlertDialog(
            backgroundColor: cardBg,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text("Editar Días Base Predeterminados",
                style: TextStyle(
                    color: accentColor, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Estos días de descanso se utilizan como respaldo para cualquier fecha que no tenga un periodo específico asignado.",
                  style: TextStyle(
                      color:
                          widget.isDarkMode ? Colors.white70 : Colors.black54,
                      fontSize: 13),
                ),
                const SizedBox(height: 16),
                _build7DayToggleRow(
                  selectedDays: tempDays,
                  isDarkMode: widget.isDarkMode,
                  onToggle: (dayNum) {
                    setDialogState(() {
                      if (tempDays.contains(dayNum)) {
                        tempDays.remove(dayNum);
                      } else {
                        tempDays.add(dayNum);
                        tempDays.sort();
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  "Días: ${_formatDaysDisplay(tempDays, short: false)}",
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, null),
                child: Text("CANCELAR",
                    style: TextStyle(
                        color:
                            widget.isDarkMode ? Colors.white54 : Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  if (tempDays.isEmpty) {
                    tempDays = [DateTime.saturday, DateTime.sunday];
                  }
                  tempDays.sort();
                  Navigator.pop(dialogCtx, tempDays);
                },
                child: const Text("ACTUALIZAR",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );

    if (updated != null) {
      setState(() {
        _localBaseRestDays = updated;
      });
      await widget.onCommit?.call(_localHistory, _todayActiveRestDays);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color accentColor =
        widget.isDarkMode ? Colors.orange : const Color(0xFFC2410C);
    final Color bgColor =
        widget.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final Color cardBg =
        widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final Color borderColor =
        widget.isDarkMode ? Colors.white12 : const Color(0xFFE2E8F0);
    final Color textColor = widget.isDarkMode ? Colors.white : Colors.black87;
    final Color subtextColor =
        widget.isDarkMode ? Colors.white60 : const Color(0xFF64748B);
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor:
              widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          foregroundColor: textColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            "Días de Descanso",
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          onPressed: () => _showAddOrEditPeriodDialog(),
          icon: const Icon(Icons.add),
          label: const Text("AGREGAR PERIODO",
              style:
                  TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            // Current Active Rest Days Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.isDarkMode
                      ? [accentColor.withAlpha(40), const Color(0xFF1E293B)]
                      : [const Color(0xFFFFF7ED), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color:
                        accentColor.withAlpha(widget.isDarkMode ? 80 : 120),
                    width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accentColor.withAlpha(35),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.calendar_month_rounded,
                            color: accentColor, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "DÍAS DE DESCANSO VIGENTES HOY",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.tune, color: accentColor, size: 20),
                        tooltip: "Editar días base predeterminados",
                        onPressed: _showEditBaseRestDaysDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _formatDaysDisplay(_todayActiveRestDays, short: false),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Días base predeterminados: ${_formatDaysDisplay(_localBaseRestDays, short: true)}",
                    style: TextStyle(
                      color: subtextColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Header for registered periods
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "PERIODOS REGISTRADOS",
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:
                        accentColor.withAlpha(widget.isDarkMode ? 35 : 25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${_localHistory.length}",
                    style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_localHistory.isEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 36, horizontal: 20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Icon(Icons.history_toggle_off,
                        size: 48, color: subtextColor.withAlpha(120)),
                    const SizedBox(height: 12),
                    Text(
                      "Sin periodos específicos",
                      style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Se aplicarán los días base predeterminados (${_formatDaysDisplay(_localBaseRestDays, short: true)}) a todas las fechas pasadas y futuras.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: subtextColor, fontSize: 13),
                    ),
                    const SizedBox(height: 18),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accentColor,
                        side: BorderSide(color: accentColor),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _showAddOrEditPeriodDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text("REGISTRAR UN PERIODO",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ..._localHistory.asMap().entries.map((entry) {
                final int index = entry.key;
                final Map<String, dynamic> item = entry.value;

                final rawDays = item['rest_days'];
                List<int> days = [];
                if (rawDays is List) {
                  days = rawDays
                      .map((e) =>
                          int.tryParse(e.toString()) ?? (e is int ? e : null))
                      .whereType<int>()
                      .toList();
                  days.sort();
                }

                final String sDateStr =
                    (item['start_date'] ?? item['effective_date'] ?? '')
                        .toString();
                final String? eDateStr = (item['end_date'] != null &&
                        item['end_date'].toString().isNotEmpty &&
                        item['end_date'] != 'null')
                    ? item['end_date'].toString()
                    : null;

                final DateTime? sDate = DateTime.tryParse(sDateStr);
                final DateTime? eDate =
                    eDateStr != null ? DateTime.tryParse(eDateStr) : null;

                // Status calculation
                bool isActive = false;
                bool isFuture = false;

                if (sDate != null) {
                  final sMidnight =
                      DateTime(sDate.year, sDate.month, sDate.day);
                  final eMidnight = eDate != null
                      ? DateTime(eDate.year, eDate.month, eDate.day)
                      : null;

                  if (todayMidnight.isBefore(sMidnight)) {
                    isFuture = true;
                  } else if (eMidnight != null &&
                      todayMidnight.isAfter(eMidnight)) {
                    // Past
                  } else {
                    isActive = true;
                  }
                }

                Color badgeBg;
                Color badgeText;
                String badgeLabel;

                if (isActive) {
                  badgeBg = widget.isDarkMode
                      ? Colors.green.withAlpha(35)
                      : const Color(0xFFDCFCE7);
                  badgeText = widget.isDarkMode
                      ? Colors.greenAccent
                      : const Color(0xFF15803D);
                  badgeLabel = "VIGENTE";
                } else if (isFuture) {
                  badgeBg = widget.isDarkMode
                      ? Colors.blue.withAlpha(35)
                      : const Color(0xFFDBEAFE);
                  badgeText = widget.isDarkMode
                      ? Colors.blueAccent
                      : const Color(0xFF1D4ED8);
                  badgeLabel = "FUTURO";
                } else {
                  badgeBg = widget.isDarkMode
                      ? Colors.white10
                      : const Color(0xFFF1F5F9);
                  badgeText = widget.isDarkMode
                      ? Colors.white54
                      : const Color(0xFF64748B);
                  badgeLabel = "HISTÓRICO";
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isActive
                          ? accentColor.withAlpha(
                              widget.isDarkMode ? 90 : 140)
                          : borderColor,
                      width: isActive ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _formatDaysDisplay(days, short: true),
                                  style: TextStyle(
                                    color: isActive ? accentColor : textColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: badgeBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    badgeLabel,
                                    style: TextStyle(
                                      color: badgeText,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.date_range,
                                    size: 14, color: subtextColor),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    sDate != null
                                        ? "Desde ${DateFormat('dd/MM/yyyy').format(sDate)}${eDate != null ? ' hasta ${DateFormat('dd/MM/yyyy').format(eDate)}' : ' (Indefinido)'}"
                                        : sDateStr,
                                    style: TextStyle(
                                      color: subtextColor,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit_outlined,
                            color: subtextColor, size: 20),
                        tooltip: "Editar periodo",
                        onPressed: () =>
                            _showAddOrEditPeriodDialog(editIndex: index),
                      ),
                      if (_localHistory.length > 1)
                        IconButton(
                          icon: Icon(Icons.delete_outline,
                              color: widget.isDarkMode
                                  ? Colors.redAccent
                                  : const Color(0xFFDC2626),
                              size: 20),
                          tooltip: "Eliminar periodo",
                          onPressed: () => _showDeletePeriodDialog(index),
                        ),
                    ],
                  ),
                );
              }),
              if (_localHistory.length == 1) ...[
                Container(
                  margin: const EdgeInsets.only(top: 4, bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.isDarkMode
                        ? accentColor.withAlpha(18)
                        : const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color:
                          accentColor.withAlpha(widget.isDarkMode ? 60 : 90),
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 18, color: accentColor),
                          const SizedBox(width: 8),
                          Text(
                            "DÍAS DE DESCANSO BASE",
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Estos días de descanso se aplican indefinidamente a todos los turnos. Si cambias de horario o rol de descansos en una fecha específica, agrega un nuevo periodo.",
                        style: TextStyle(
                          color: subtextColor,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: accentColor,
                            side: BorderSide(color: accentColor),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                          onPressed: () => _showAddOrEditPeriodDialog(),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text("REGISTRAR UN PERIODO",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// ADMIN ACCOUNT MERGING TOOL
// ===========================================================================

