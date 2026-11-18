part of '../main.dart';

class _EditWorkDayResult {
  final DateTime entrada;
  final DateTime salida;
  final DateTime? entradaReal;
  final String notas;
  final bool share;
  final bool isInProgress;
  final bool timesModified;
  final Map<String, bool>? perManagerShare;
  final bool esMantenimiento;
  final bool esVacaciones;
  final bool esFestivo;
  final bool festivoTrabajado;
  final bool esFalta;
  final bool salidaAutorizada;

  const _EditWorkDayResult({
    required this.entrada,
    required this.salida,
    this.entradaReal,
    required this.notas,
    required this.share,
    required this.isInProgress,
    required this.timesModified,
    this.perManagerShare,
    this.esMantenimiento = false,
    this.esVacaciones = false,
    this.esFestivo = false,
    this.festivoTrabajado = false,
    this.esFalta = false,
    this.salidaAutorizada = false,
  });
}

enum _TipoJornada {
  regular,
  mantenimiento,
  vacaciones,
  festivoNoLaborado,
  festivoLaborado,
  falta,
}

class _TipoJornadaInfo {
  final _TipoJornada type;
  final String label;
  final String shortDescription;
  final IconData icon;
  final Color color;

  const _TipoJornadaInfo({
    required this.type,
    required this.label,
    required this.shortDescription,
    required this.icon,
    required this.color,
  });
}




class _EditWorkDayDialog extends StatefulWidget {
  final WorkDay day;
  final bool isDarkMode;
  final bool canShare;
  final bool initialShare;
  final String managerName;
  final Map<String, Map<String, dynamic>>? activeGrants;
  final Map<String, bool>? initialShareMap;
  final Future<TimeOfDay?> Function(
    BuildContext context, {
    required TimeOfDay initialTime,
    String? title,
  }) onPickTime;

  const _EditWorkDayDialog({
    required this.day,
    required this.isDarkMode,
    required this.canShare,
    required this.initialShare,
    required this.managerName,
    this.activeGrants,
    this.initialShareMap,
    required this.onPickTime,
  });

  @override
  State<_EditWorkDayDialog> createState() => _EditWorkDayDialogState();
}

class _EditWorkDayDialogState extends State<_EditWorkDayDialog> {
  late DateTime _entrada;
  late DateTime _salida;
  DateTime? _entradaReal;
  late TextEditingController _notesController;
  late bool _share;
  late bool _isInProgress;
  late bool _salidaAutorizada;
  late Map<String, bool> _managerShares;
  late _TipoJornada _tipoJornada;

  static _TipoJornada _getInitialJornadaType(WorkDay day) {
    if (day.esMantenimiento) return _TipoJornada.mantenimiento;
    if (day.esVacaciones) return _TipoJornada.vacaciones;
    if (day.esFestivo && !day.festivoTrabajado) {
      return _TipoJornada.festivoNoLaborado;
    }
    if (day.esFestivo && day.festivoTrabajado) {
      return _TipoJornada.festivoLaborado;
    }
    if (day.esFalta) return _TipoJornada.falta;
    return _TipoJornada.regular;
  }

  List<_TipoJornadaInfo> get _jornadaOptions => [
        const _TipoJornadaInfo(
          type: _TipoJornada.regular,
          label: "JORNADA REGULAR",
          shortDescription:
              "Jornada habitual con cálculo de horas y horas extra",
          icon: Icons.work_history_rounded,
          color: Colors.green,
        ),
        const _TipoJornadaInfo(
          type: _TipoJornada.mantenimiento,
          label: "DÍA DE MANTENIMIENTO",
          shortDescription:
              "Horario regular con pago base sin horas extra",
          icon: Icons.build_rounded,
          color: Colors.blue,
        ),
        _TipoJornadaInfo(
          type: _TipoJornada.vacaciones,
          label: "VACACIONES",
          shortDescription: "Día completo de vacaciones con pago base",
          icon: Icons.beach_access_rounded,
          color: Colors.lightGreen.shade700,
        ),
        _TipoJornadaInfo(
          type: _TipoJornada.festivoNoLaborado,
          label: "FESTIVO NO LABORADO",
          shortDescription:
              "Día feriado descansado con pago base completo",
          icon: Icons.celebration_rounded,
          color: Colors.purple.shade400,
        ),
        _TipoJornadaInfo(
          type: _TipoJornada.festivoLaborado,
          label: "FESTIVO LABORADO",
          shortDescription:
              "Feriado trabajado con pago doble y horas extra",
          icon: Icons.stars_rounded,
          color: Colors.purple.shade700,
        ),
        const _TipoJornadaInfo(
          type: _TipoJornada.falta,
          label: "NO LABORÉ HOY",
          shortDescription: "Día no trabajado (falta) sin compensación",
          icon: Icons.cancel_rounded,
          color: Colors.red,
        ),
      ];

  bool get _isNonWorkingType =>
      _tipoJornada == _TipoJornada.vacaciones ||
      _tipoJornada == _TipoJornada.festivoNoLaborado ||
      _tipoJornada == _TipoJornada.falta;

  @override
  void initState() {
    super.initState();
    _tipoJornada = _getInitialJornadaType(widget.day);
    _entrada = widget.day.entrada;
    _salida = widget.day.salida;
    _entradaReal = widget.day.entradaReal;
    _notesController = TextEditingController(text: widget.day.notas);
    _share = widget.initialShare;
    _isInProgress = widget.day.isInProgress;
    _salidaAutorizada = widget.day.salidaAutorizada;
    _managerShares = widget.initialShareMap != null
        ? Map<String, bool>.from(widget.initialShareMap!)
        : {};
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  bool get _hasChanges {
    final initialType = _getInitialJornadaType(widget.day);
    if (_tipoJornada != initialType) return true;
    if (!_isNonWorkingType) {
      if (_entrada != widget.day.entrada) return true;
      if (!_isInProgress && _salida != widget.day.salida) return true;
      if (_entradaReal != widget.day.entradaReal) return true;
      if (_salidaAutorizada != widget.day.salidaAutorizada) return true;
    }
    if (_notesController.text.trim() != widget.day.notas.trim()) return true;
    if (widget.canShare) {
      if (_share != widget.initialShare) return true;
      if (widget.initialShareMap != null) {
        for (final entry in _managerShares.entries) {
          if (widget.initialShareMap![entry.key] != entry.value) return true;
        }
      }
    }
    if (_isInProgress != widget.day.isInProgress) return true;
    return false;
  }

  bool get _timesModified =>
      _tipoJornada != _getInitialJornadaType(widget.day) ||
      _entrada != widget.day.entrada ||
      (!_isInProgress && _salida != widget.day.salida) ||
      _entradaReal != widget.day.entradaReal;

  Future<void> _handleCancel() async {
    if (!_hasChanges) {
      Navigator.of(context).pop();
      return;
    }
    final shouldDiscard = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (confirmCtx) => AlertDialog(
        backgroundColor:
            widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.amber, size: 24),
            const SizedBox(width: 8),
            Text(
              "¿Descartar cambios?",
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : Colors.black87,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          "Tienes modificaciones sin guardar. ¿Deseas descartar los cambios realizados?",
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white70 : Colors.black54,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(confirmCtx).pop(false),
            child: Text(
              "Seguir editando",
              style: TextStyle(
                color: widget.isDarkMode
                    ? Colors.cyanAccent
                    : const Color(0xFF0284C7),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(confirmCtx).pop(true),
            child: const Text("Descartar"),
          ),
        ],
      ),
    );

    if (shouldDiscard == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _onTipoJornadaChanged(_TipoJornada newType) {
    if (_tipoJornada == newType) return;
    setState(() {
      _tipoJornada = newType;
      if (newType == _TipoJornada.vacaciones ||
          newType == _TipoJornada.festivoNoLaborado ||
          newType == _TipoJornada.falta) {
        _isInProgress = false;
      } else {
        // If transitioning from an off-day where entrada == salida (e.g. 12:00 - 12:00)
        if (_salida.isAtSameMomentAs(_entrada)) {
          final double baseHrs =
              widget.day.baseHours > 0 ? widget.day.baseHours : 9.5;
          final int baseMins = (baseHrs * 60).round();
          _entrada = DateTime(
              _entrada.year, _entrada.month, _entrada.day, 8, 0);
          _salida = _entrada.add(Duration(minutes: baseMins));
          _entradaReal = _entrada;
        }
      }
    });
  }

  Future<void> _showTipoJornadaPicker() async {
    final isDark = widget.isDarkMode;
    final sheetBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? Colors.white60 : const Color(0xFF64748B);
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);

    final selected = await showModalBottomSheet<_TipoJornada>(
      context: context,
      useRootNavigator: true,
      backgroundColor: sheetBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color:
                            isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isDark
                                  ? Colors.cyanAccent
                                  : const Color(0xFF0284C7))
                              .withAlpha(isDark ? 35 : 25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.category_rounded,
                          color: isDark
                              ? Colors.cyanAccent
                              : const Color(0xFF0284C7),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Tipo de Jornada",
                              style: TextStyle(
                                color: textColor,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Selecciona cómo registrar este día",
                              style: TextStyle(
                                color: subtextColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        color: subtextColor,
                        onPressed: () => Navigator.of(sheetCtx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: borderColor),
                  const SizedBox(height: 8),
                  ..._jornadaOptions.map((opt) {
                    final isSelected = opt.type == _tipoJornada;
                    final optColor = opt.color;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.of(sheetCtx).pop(opt.type),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? optColor.withAlpha(isDark ? 35 : 20)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? optColor.withAlpha(isDark ? 100 : 70)
                                  : borderColor,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: optColor.withAlpha(isDark ? 40 : 25),
                                  shape: BoxShape.circle,
                                ),
                                child:
                                    Icon(opt.icon, color: optColor, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      opt.label,
                                      style: TextStyle(
                                        color: isSelected
                                            ? _getJornadaBadgeColor(opt.type, isDark)
                                            : textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      opt.shortDescription,
                                      style: TextStyle(
                                        color: subtextColor,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: optColor,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (selected != null && mounted) {
      _onTipoJornadaChanged(selected);
    }
  }

  void _handleSave() {
    DateTime fEntrada = _entrada;
    DateTime fSalida = _salida;
    DateTime? fEntradaReal = _entradaReal;
    bool inProgress = _isInProgress;

    if (_isNonWorkingType) {
      fEntrada = DateTime(_entrada.year, _entrada.month, _entrada.day, 12, 0);
      fSalida = fEntrada;
      fEntradaReal = null;
      inProgress = false;
    } else {
      if (!inProgress && fSalida.isBefore(fEntrada)) {
        fSalida = fSalida.add(const Duration(days: 1));
      }
    }

    Navigator.of(context).pop(_EditWorkDayResult(
      entrada: fEntrada,
      salida: fSalida,
      entradaReal: fEntradaReal,
      notas: _notesController.text.trim(),
      share: _share,
      isInProgress: inProgress,
      timesModified: _timesModified,
      perManagerShare: _managerShares.isNotEmpty ? _managerShares : null,
      esMantenimiento: _tipoJornada == _TipoJornada.mantenimiento,
      esVacaciones: _tipoJornada == _TipoJornada.vacaciones,
      esFestivo: _tipoJornada == _TipoJornada.festivoNoLaborado ||
          _tipoJornada == _TipoJornada.festivoLaborado,
      festivoTrabajado: _tipoJornada == _TipoJornada.festivoLaborado,
      esFalta: _tipoJornada == _TipoJornada.falta,
      salidaAutorizada: _salidaAutorizada,
    ));
  }

  Future<void> _pickEntradaTime() async {
    final picked = await widget.onPickTime(
      context,
      initialTime: TimeOfDay.fromDateTime(_entrada),
      title: "EDITAR HORA ENTRADA",
    );
    if (picked != null && mounted) {
      setState(() {
        _entrada = DateTime(
          _entrada.year,
          _entrada.month,
          _entrada.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _pickSalidaTime() async {
    final picked = await widget.onPickTime(
      context,
      initialTime: TimeOfDay.fromDateTime(_salida),
      title: "EDITAR HORA SALIDA",
    );
    if (picked != null && mounted) {
      setState(() {
        _salida = DateTime(
          _entrada.year,
          _entrada.month,
          _entrada.day,
          picked.hour,
          picked.minute,
        );
        _isInProgress = false;
      });
    }
  }

  Future<void> _pickEntradaRealTime() async {
    final initial = _entradaReal ?? _entrada;
    final picked = await widget.onPickTime(
      context,
      initialTime: TimeOfDay.fromDateTime(initial),
      title: "EDITAR ENTRADA REAL",
    );
    if (picked != null && mounted) {
      setState(() {
        _entradaReal = DateTime(
          _entrada.year,
          _entrada.month,
          _entrada.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final primaryColor = isDark ? Colors.cyanAccent : const Color(0xFF0284C7);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final fieldBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    final String dayTitle =
        DateFormat('EEEE, d \'de\' MMMM', 'es').format(_entrada);
    final String capitalizedDayTitle = dayTitle.isNotEmpty
        ? '${dayTitle[0].toUpperCase()}${dayTitle.substring(1)}'
        : dayTitle;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleCancel();
      },
      child: Dialog(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: borderColor),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryColor.withAlpha(isDark ? 35 : 25),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.edit_calendar_rounded,
                        color: primaryColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Editar Turno",
                            style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            capitalizedDayTitle,
                            style: TextStyle(
                              color: subtextColor,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isInProgress && !_isNonWorkingType)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amber.withAlpha(isDark ? 40 : 30),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.amber.withAlpha(isDark ? 100 : 70),
                          ),
                        ),
                        child: Text(
                          "EN CURSO",
                          style: TextStyle(
                            color: isDark
                                ? Colors.amberAccent
                                : const Color(0xFFD97706),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),

                // Tipo de Jornada Card (Tappable selector)
                _buildTipoJornadaCard(
                  isDark: isDark,
                  fieldBg: fieldBg,
                  borderColor: borderColor,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  onTap: _showTipoJornadaPicker,
                ),
                const SizedBox(height: 12),

                // Non-working notice banner OR Working time pickers
                if (_isNonWorkingType) ...[
                  _buildNonWorkingBanner(isDark, textColor, subtextColor),
                ] else ...[
                  // Entrance Field Tile (Tappable)
                  _buildFieldCard(
                    isDark: isDark,
                    fieldBg: fieldBg,
                    borderColor: borderColor,
                    textColor: textColor,
                    subtextColor: subtextColor,
                    icon: Icons.login_rounded,
                    iconColor:
                        isDark ? Colors.tealAccent : const Color(0xFF0D9488),
                    label: "HORA ENTRADA",
                    value: DateFormat('hh:mm a').format(_entrada),
                    onTap: _pickEntradaTime,
                  ),
                  const SizedBox(height: 10),

                  // Exit Field Tile (Tappable)
                  _buildFieldCard(
                    isDark: isDark,
                    fieldBg: fieldBg,
                    borderColor: borderColor,
                    textColor: textColor,
                    subtextColor: subtextColor,
                    icon: Icons.logout_rounded,
                    iconColor:
                        isDark ? Colors.orangeAccent : const Color(0xFFEA580C),
                    label: "HORA SALIDA",
                    value: _isInProgress
                        ? "En curso (Toca para marcar salida)"
                        : DateFormat('hh:mm a').format(_salida),
                    isSpecialValue: _isInProgress,
                    onTap: _pickSalidaTime,
                  ),
                  const SizedBox(height: 10),

                  // Entrada Real Field Tile (Tappable + Optional Clear)
                  _buildFieldCard(
                    isDark: isDark,
                    fieldBg: fieldBg,
                    borderColor: borderColor,
                    textColor: textColor,
                    subtextColor: subtextColor,
                    icon: Icons.access_time_filled_rounded,
                    iconColor:
                        isDark ? Colors.indigoAccent : const Color(0xFF4F46E5),
                    label: "ENTRADA REAL",
                    value: _entradaReal != null
                        ? DateFormat('hh:mm a').format(_entradaReal!)
                        : "Sin registrar (Opcional)",
                    isSpecialValue: _entradaReal == null,
                    onTap: _pickEntradaRealTime,
                    trailingAction: _entradaReal != null
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            color: subtextColor,
                            tooltip: "Eliminar entrada real",
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() {
                                _entradaReal = null;
                              });
                            },
                          )
                        : null,
                  ),
                  const SizedBox(height: 10),

                  // Early departure authorized switch (if early clock out)
                  Builder(
                    builder: (context) {
                      final DateTime effStart = (_entradaReal != null &&
                              _entradaReal!.isAfter(_entrada))
                          ? _entradaReal!
                          : _entrada;
                      final DateTime effSalida = _salida.isBefore(_entrada)
                          ? _salida.add(const Duration(days: 1))
                          : _salida;
                      final int actualWorkedMinutes =
                          effSalida.isAfter(effStart)
                              ? effSalida.difference(effStart).inMinutes
                              : 0;
                      final int requiredShiftMinutes =
                          (widget.day.baseHours * 60).round();
                      final bool isEarlyDeparture = !_isInProgress &&
                          actualWorkedMinutes < requiredShiftMinutes;

                      if (!isEarlyDeparture) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: fieldBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _salidaAutorizada
                                  ? (isDark
                                      ? Colors.greenAccent.withAlpha(100)
                                      : const Color(0xFF16A34A).withAlpha(120))
                                  : borderColor,
                              width: _salidaAutorizada ? 1.4 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: _salidaAutorizada
                                      ? (isDark
                                          ? Colors.green.withAlpha(45)
                                          : const Color(0xFFDCFCE7))
                                      : (isDark
                                          ? Colors.white12
                                          : const Color(0xFFF1F5F9)),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _salidaAutorizada
                                      ? Icons.verified_user_rounded
                                      : Icons.access_time_rounded,
                                  color: _salidaAutorizada
                                      ? (isDark
                                          ? Colors.greenAccent
                                          : const Color(0xFF16A34A))
                                      : subtextColor,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Salida autorizada (Sin descuento)",
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _salidaAutorizada
                                          ? "Día completo pagado sin deducción"
                                          : "Se descontará el tiempo no laborado",
                                      style: TextStyle(
                                        color: subtextColor,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                value: _salidaAutorizada,
                                activeColor: isDark
                                    ? Colors.greenAccent
                                    : const Color(0xFF16A34A),
                                onChanged: (val) {
                                  setState(() {
                                    _salidaAutorizada = val;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 2),
                ],

                // Notes Field
                Text(
                  "NOTAS",
                  style: TextStyle(
                    color: subtextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  style: TextStyle(color: textColor, fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: "Escribe notas u observaciones...",
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: fieldBg,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor, width: 1.4),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Manager Share Toggle (if canShare is true)
                if (widget.canShare) ...[
                  if (widget.activeGrants != null &&
                      widget.activeGrants!.length > 1) ...[
                    Text(
                      "COMPARTIR CON SUPERVISORES",
                      style: TextStyle(
                        color: subtextColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: fieldBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: widget.activeGrants!.entries.map((entry) {
                          final mgrKey = entry.key;
                          final grant = entry.value;
                          final mgrName = (grant['manager_name'] ?? 'Ingeniero')
                              .toString();
                          final mgrEmp =
                              (grant['manager_emp'] ?? '').toString();
                          final bool isMgrShared =
                              _managerShares[mgrKey] ?? false;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 13,
                                  backgroundColor: isMgrShared
                                      ? primaryColor.withAlpha(isDark ? 45 : 30)
                                      : (isDark
                                          ? Colors.white12
                                          : const Color(0xFFE2E8F0)),
                                  child: Text(
                                    mgrName.isNotEmpty
                                        ? mgrName.substring(0, 1).toUpperCase()
                                        : 'I',
                                    style: TextStyle(
                                      color: isMgrShared
                                          ? primaryColor
                                          : subtextColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              mgrName,
                                              style: TextStyle(
                                                color: textColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: isMgrShared
                                                  ? Colors.green.withAlpha(
                                                      isDark ? 40 : 30)
                                                  : Colors.grey.withAlpha(
                                                      isDark ? 40 : 30),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              isMgrShared
                                                  ? "COMPARTIDO"
                                                  : "NO COMPARTIDO",
                                              style: TextStyle(
                                                color: isMgrShared
                                                    ? (isDark
                                                        ? Colors.greenAccent
                                                        : const Color(
                                                            0xFF16A34A))
                                                    : subtextColor,
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (mgrEmp.isNotEmpty)
                                        Text(
                                          "No. Emp: $mgrEmp",
                                          style: TextStyle(
                                            color: subtextColor,
                                            fontSize: 10,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Switch.adaptive(
                                  value: isMgrShared,
                                  activeColor: primaryColor,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  onChanged: (val) {
                                    setState(() {
                                      _managerShares[mgrKey] = val;
                                      _share =
                                          _managerShares.values.any((v) => v);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: fieldBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _share
                              ? (isDark
                                  ? Colors.cyanAccent.withAlpha(90)
                                  : const Color(0xFF0284C7).withAlpha(120))
                              : borderColor,
                          width: _share ? 1.4 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: _share
                                  ? primaryColor.withAlpha(isDark ? 40 : 25)
                                  : (isDark ? Colors.white12 : Colors.white),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _share
                                  ? Icons.share_rounded
                                  : Icons.visibility_off_outlined,
                              color: _share ? primaryColor : subtextColor,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      "Compartir con ${widget.managerName}",
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: _share
                                            ? Colors.green
                                                .withAlpha(isDark ? 40 : 30)
                                            : Colors.grey
                                                .withAlpha(isDark ? 40 : 30),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        _share ? "COMPARTIDO" : "NO COMPARTIDO",
                                        style: TextStyle(
                                          color: _share
                                              ? (isDark
                                                  ? Colors.greenAccent
                                                  : const Color(0xFF16A34A))
                                              : subtextColor,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _share
                                      ? "Visible en reporte de unidad"
                                      : "Oculto para el reporte",
                                  style: TextStyle(
                                    color: subtextColor,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _share,
                            activeColor: primaryColor,
                            onChanged: (val) {
                              setState(() {
                                _share = val;
                                if (_managerShares.isNotEmpty) {
                                  for (final k
                                      in _managerShares.keys.toList()) {
                                    _managerShares[k] = val;
                                  }
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                ],

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(
                            color: isDark
                                ? Colors.white24
                                : const Color(0xFFCBD5E1),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _handleCancel,
                        child: Text(
                          "CANCELAR",
                          style: TextStyle(
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF475569),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: primaryColor,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 1,
                        ),
                        onPressed: _handleSave,
                        child: const Text(
                          "GUARDAR",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getJornadaBadgeColor(_TipoJornada type, bool isDark) {
    if (isDark) {
      switch (type) {
        case _TipoJornada.regular:
          return Colors.greenAccent;
        case _TipoJornada.mantenimiento:
          return Colors.blueAccent;
        case _TipoJornada.vacaciones:
          return Colors.lightGreenAccent;
        case _TipoJornada.festivoNoLaborado:
        case _TipoJornada.festivoLaborado:
          return Colors.purpleAccent;
        case _TipoJornada.falta:
          return Colors.redAccent;
      }
    } else {
      switch (type) {
        case _TipoJornada.regular:
          return const Color(0xFF166534); // rich forest green
        case _TipoJornada.mantenimiento:
          return const Color(0xFF1E40AF); // bold navy
        case _TipoJornada.vacaciones:
          return const Color(0xFF15803D); // emerald green
        case _TipoJornada.festivoNoLaborado:
        case _TipoJornada.festivoLaborado:
          return const Color(0xFF6B21A8); // rich purple
        case _TipoJornada.falta:
          return const Color(0xFF991B1B); // dark crimson
      }
    }
  }

  Widget _buildTipoJornadaCard({
    required bool isDark,
    required Color fieldBg,
    required Color borderColor,
    required Color textColor,
    required Color subtextColor,
    required VoidCallback onTap,
  }) {
    final info = _jornadaOptions.firstWhere((opt) => opt.type == _tipoJornada);
    final badgeTextColor = _getJornadaBadgeColor(info.type, isDark);
    final badgeColor = isDark ? info.color : badgeTextColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: fieldBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isDark
                    ? badgeColor.withAlpha(35)
                    : badgeTextColor.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(info.icon,
                  color: isDark ? badgeColor : badgeTextColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "TIPO DE JORNADA",
                    style: TextStyle(
                      color: subtextColor,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark
                              ? badgeColor.withAlpha(45)
                              : badgeTextColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDark
                                ? badgeColor.withAlpha(100)
                                : badgeTextColor.withAlpha(80),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          info.label,
                          style: TextStyle(
                            color: badgeTextColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.edit_rounded,
                color: subtextColor,
                size: 16,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              color: subtextColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNonWorkingBanner(
      bool isDark, Color textColor, Color subtextColor) {
    final info = _jornadaOptions.firstWhere((opt) => opt.type == _tipoJornada);
    final badgeTextColor = _getJornadaBadgeColor(info.type, isDark);
    final bannerColor = isDark ? info.color : badgeTextColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark
            ? bannerColor.withAlpha(30)
            : badgeTextColor.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? bannerColor.withAlpha(90)
              : badgeTextColor.withAlpha(70),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? bannerColor.withAlpha(45)
                  : badgeTextColor.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(info.icon,
                color: isDark ? bannerColor : badgeTextColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.label,
                  style: TextStyle(
                    color: badgeTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "Jornada de día completo • No requiere registro de horas",
                  style: TextStyle(
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldCard({
    required bool isDark,
    required Color fieldBg,
    required Color borderColor,
    required Color textColor,
    required Color subtextColor,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool isSpecialValue = false,
    required VoidCallback onTap,
    Widget? trailingAction,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: fieldBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: iconColor.withAlpha(isDark ? 35 : 20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: subtextColor,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      color: isSpecialValue
                          ? (isDark
                              ? Colors.amberAccent
                              : const Color(0xFFD97706))
                          : textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (trailingAction != null) ...[
              trailingAction,
              const SizedBox(width: 6),
            ],
            Icon(
              Icons.chevron_right_rounded,
              color: subtextColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

