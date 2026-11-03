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

  const _EditWorkDayResult({
    required this.entrada,
    required this.salida,
    this.entradaReal,
    required this.notas,
    required this.share,
    required this.isInProgress,
    required this.timesModified,
    this.perManagerShare,
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
  late Map<String, bool> _managerShares;

  @override
  void initState() {
    super.initState();
    _entrada = widget.day.entrada;
    _salida = widget.day.salida;
    _entradaReal = widget.day.entradaReal;
    _notesController = TextEditingController(text: widget.day.notas);
    _share = widget.initialShare;
    _isInProgress = widget.day.isInProgress;
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
    if (_entrada != widget.day.entrada) return true;
    if (!_isInProgress && _salida != widget.day.salida) return true;
    if (_entradaReal != widget.day.entradaReal) return true;
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

  void _handleSave() {
    DateTime fEntrada = _entrada;
    DateTime fSalida = _salida;
    if (!_isInProgress && fSalida.isBefore(fEntrada)) {
      fSalida = fSalida.add(const Duration(days: 1));
    }
    Navigator.of(context).pop(_EditWorkDayResult(
      entrada: fEntrada,
      salida: fSalida,
      entradaReal: _entradaReal,
      notas: _notesController.text.trim(),
      share: _share,
      isInProgress: _isInProgress,
      timesModified: _timesModified,
      perManagerShare: _managerShares.isNotEmpty ? _managerShares : null,
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
                    if (_isInProgress)
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

                // Special day banner if applicable
                if (widget.day.esVacaciones ||
                    widget.day.esFalta ||
                    (widget.day.esFestivo && !widget.day.festivoTrabajado))
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: widget.day.esFalta
                          ? Colors.red.withAlpha(25)
                          : (widget.day.esVacaciones
                              ? Colors.teal.withAlpha(25)
                              : Colors.amber.withAlpha(25)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: widget.day.esFalta
                            ? Colors.red.withAlpha(70)
                            : (widget.day.esVacaciones
                                ? Colors.teal.withAlpha(70)
                                : Colors.amber.withAlpha(70)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          widget.day.esFalta
                              ? Icons.cancel_outlined
                              : (widget.day.esVacaciones
                                  ? Icons.beach_access
                                  : Icons.celebration),
                          color: widget.day.esFalta
                              ? Colors.redAccent
                              : (widget.day.esVacaciones
                                  ? Colors.tealAccent
                                  : Colors.amberAccent),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.day.esFalta
                              ? "Día registrado como FALTA"
                              : (widget.day.esVacaciones
                                  ? "Día registrado como VACACIONES"
                                  : "FESTIVO NO LABORADO"),
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

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
                const SizedBox(height: 12),

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

