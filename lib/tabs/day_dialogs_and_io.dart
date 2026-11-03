part of '../main.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _DayDialogsAndIoExt on _TelevisaAppState {
  Future<void> _exportData() async {
    try {
      Map<String, dynamic> exportData = {
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

                _rebuild(() {
                  _salaryController.text = data['salary'] ?? "";

                  // Import history lists
                  if (data['salary_history'] != null) {
                    _salaryHistory =
                        _normalizeHistoryList(data['salary_history']);
                  }
                  if (data['jornada_history'] != null) {
                    _jornadaHistory =
                        _normalizeHistoryList(data['jornada_history']);
                  }
                  if (data['retention_history'] != null) {
                    _retentionHistory =
                        _normalizeHistoryList(data['retention_history']);
                  }
                  if (data['fomento_history'] != null) {
                    _fomentoHistory =
                        _normalizeHistoryList(data['fomento_history']);
                  }
                  if (data['cuota_history'] != null) {
                    _cuotaHistory =
                        _normalizeHistoryList(data['cuota_history']);
                  }
                  if (data['rest_days_history'] != null) {
                    _restDaysHistory =
                        _normalizeRestDaysHistoryList(data['rest_days_history']);
                  }

                  if (data['rest_days'] != null) {
                    _restDays = List<int>.from(
                        (data['rest_days'] as List).map((x) => (x as num).toInt()));
                    WorkDay.restDays = _restDays;
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
                  _syncWorkDayStatics();
                });
                await _saveData(checkSalaryChange: false);

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
      _rebuild(() {
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
      _rebuild(() {
        controller.text = originalVal;
        _editingFieldLabels.remove(label);
        _originalFieldValues.remove(label);
      });
    } else if (action == "save" && mounted) {
      _rebuild(() {
        _editingFieldLabels.remove(label);
        _originalFieldValues.remove(label);
      });
      await _saveData();
    }
  }

  Future<void> _navigateToRestDaysHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RestDaysHistoryScreen(
          history: _restDaysHistory,
          baseRestDays: _restDays,
          isDarkMode: _isDarkMode,
          onCommit: (updatedHistory, newBaseRestDays) async {
            _rebuild(() {
              _restDaysHistory = updatedHistory;
              _restDays = newBaseRestDays;
              _syncWorkDayStatics();
            });
            await _saveData(checkSalaryChange: false);
          },
        ),
      ),
    );
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
                      _rebuild(() {
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
                _rebuild(() {
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

  Future<String?> _promptForNotes(
    BuildContext context, {
    String initialNotes = "",
    bool showShareToggle = false,
    bool initialShareValue = true,
    String managerName = "",
    void Function(bool)? onShareToggleChanged,
  }) async {
    TextEditingController notesController =
        TextEditingController(text: initialNotes);
    bool shareValue = initialShareValue;

    return await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              scrollable: true,
              backgroundColor:
                  _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
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
                  if (showShareToggle) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _isDarkMode
                            ? (shareValue
                                ? Colors.cyanAccent.withAlpha(20)
                                : Colors.white.withAlpha(10))
                            : (shareValue
                                ? const Color(0xFFF0F9FF)
                                : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: shareValue
                              ? (_isDarkMode
                                  ? Colors.cyanAccent.withAlpha(60)
                                  : const Color(0xFFBAE6FD))
                              : (_isDarkMode
                                  ? Colors.white12
                                  : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            shareValue
                                ? Icons.share_rounded
                                : Icons.visibility_off_outlined,
                            color: shareValue
                                ? (_isDarkMode
                                    ? Colors.cyanAccent
                                    : const Color(0xFF0284C7))
                                : (_isDarkMode
                                    ? Colors.white38
                                    : const Color(0xFF94A3B8)),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Compartir con $managerName",
                                  style: TextStyle(
                                    color: _isDarkMode
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.5,
                                  ),
                                ),
                                Text(
                                  shareValue
                                      ? "Visible para el Ingeniero"
                                      : "Oculto para el Ingeniero",
                                  style: TextStyle(
                                    color: _isDarkMode
                                        ? Colors.white54
                                        : const Color(0xFF64748B),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: shareValue,
                            activeColor: _isDarkMode
                                ? Colors.cyanAccent
                                : const Color(0xFF0284C7),
                            onChanged: (val) {
                              setDialogState(() => shareValue = val);
                              onShareToggleChanged?.call(val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
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

          bool startedOnWeekend = day.isRestDay;
          double normalHrs =
              day.totalHours > day.baseHours ? day.baseHours : day.totalHours;

          return AlertDialog(
            scrollable: true,
            backgroundColor:
                _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateStringES,
                      style: TextStyle(
                        color: startedOnWeekend
                            ? (_isDarkMode
                                ? Colors.yellowAccent
                                : const Color(0xFFB45309))
                            : (_isDarkMode
                                ? Colors.orange
                                : const Color(0xFFC2410C)),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                if (_isUnitShareActive && _activeUnitShareData != null) ...[
                  const SizedBox(height: 6),
                  StatefulBuilder(
                    builder: (modalCtx, setModalState) {
                      final activeGrants = _getActiveShareGrants();
                      if (activeGrants.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: activeGrants.entries.map((entry) {
                          final mgrKey = entry.key;
                          final grant = entry.value;
                          final bool isShared = _isDateSharedWithSpecificManager(
                            mgrKey,
                            grant,
                            day.entrada,
                            shiftId: day.id,
                          );
                          final String mgrName = (grant['manager_name'] ??
                                  grant['name'] ??
                                  'Ingeniero de Unidad')
                              .toString()
                              .trim();

                          final Color badgeColor = isShared
                              ? (_isDarkMode
                                  ? Colors.cyanAccent
                                  : const Color(0xFF0284C7))
                              : (_isDarkMode
                                  ? Colors.white60
                                  : const Color(0xFF64748B));
                          final Color badgeBg = isShared
                              ? (_isDarkMode
                                  ? Colors.cyanAccent.withAlpha(35)
                                  : const Color(0xFFE0F2FE))
                              : (_isDarkMode
                                  ? Colors.white10
                                  : const Color(0xFFF1F5F9));
                          final Color badgeBorder = isShared
                              ? (_isDarkMode
                                  ? Colors.cyanAccent.withAlpha(90)
                                  : const Color(0xFF7DD3FC))
                              : (_isDarkMode
                                  ? Colors.white12
                                  : const Color(0xFFCBD5E1));

                          return Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: badgeBorder),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isShared
                                      ? Icons.share_rounded
                                      : Icons.visibility_off_rounded,
                                  size: 14,
                                  color: badgeColor,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    isShared
                                        ? "Compartido con $mgrName"
                                        : "No compartido con $mgrName",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: badgeColor,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 24,
                                  child: Switch.adaptive(
                                    value: isShared,
                                    activeColor: badgeColor,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    onChanged: (val) async {
                                      await _toggleUnitShareForDate(
                                        date: day.entrada,
                                        shiftId: day.id,
                                        managerKey: mgrKey,
                                        share: val,
                                      );
                                      if (mounted) {
                                        setModalState(() {});
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
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
                            "DESGLOSE DE HORAS",
                            "${normalHrs.toStringAsFixed(1)}h Base\n${day.holidayExtraHours.toStringAsFixed(2)}h Extra",
                            "${day.totalHours.toStringAsFixed(2)} hrs totales",
                          )
                        else
                          _statDetail(
                            "DESGLOSE DE HORAS",
                            "${normalHrs.toStringAsFixed(1)}h Base\n${day.extraHoursCount.toStringAsFixed(2)}h Extra",
                            "${day.totalHours.toStringAsFixed(2)} hrs totales",
                          ),
                        if (day.esFestivo && day.festivoTrabajado)
                          _statDetail(
                            "DESGLOSE DE PAGO",
                            "\$${day.sueldoBase.toStringAsFixed(2)} × 2 (Base)\n\$${day.holidayExtrasPay.toStringAsFixed(2)} (Extras 3×)",
                            "\$${day.totalPay.toStringAsFixed(2)}",
                            isMoney: true,
                          )
                        else
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
                child: Text("CERRAR",
                    style: TextStyle(
                        color: _isDarkMode
                            ? Colors.white70
                            : const Color(0xFF475569))),
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
                double baseHrs = _getJornadaForDate(date);
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
                    baseHours: _getJornadaForDate(noon),
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
                    baseHours: _getJornadaForDate(noon),
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
                    baseHours: _getJornadaForDate(fEntrada),
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
                    baseHours: _getJornadaForDate(noon),
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

    final bool canShare = _isUnitShareActive && _activeUnitShareData != null;
    final activeGrants =
        canShare ? _getActiveShareGrants() : <String, Map<String, dynamic>>{};
    final String managerName =
        (_activeUnitShareData?['manager_name'] ?? 'Ingeniero de Unidad')
            .toString();
    final bool initialShare =
        canShare ? _isDateSharedWithManager(day.entrada, shiftId: day.id) : true;

    final Map<String, bool> initialShareMap = {};
    if (canShare && activeGrants.isNotEmpty) {
      for (final entry in activeGrants.entries) {
        initialShareMap[entry.key] = _isDateSharedWithSpecificManager(
          entry.key,
          entry.value,
          day.entrada,
          shiftId: day.id,
        );
      }
    }

    final _EditWorkDayResult? result = await showDialog<_EditWorkDayResult>(
      context: context,
      barrierDismissible: false,
      builder: (modalCtx) => _EditWorkDayDialog(
        day: day,
        isDarkMode: _isDarkMode,
        canShare: canShare,
        initialShare: initialShare,
        managerName: managerName,
        activeGrants: activeGrants,
        initialShareMap: initialShareMap,
        onPickTime: (ctx, {required initialTime, title}) =>
            _showScrollTimePicker(ctx, initialTime: initialTime, title: title),
      ),
    );

    if (result == null || !mounted) return;

    _rebuild(() {
      day.entrada = result.entrada;
      if (!result.isInProgress) {
        day.salida = result.salida;
      }
      day.entradaReal = result.entradaReal;
      day.notas = result.notas;
      day.isInProgress = result.isInProgress;
      if (result.timesModified && !result.isInProgress) {
        day.esFalta = false;
      }
    });

    await _userHistory.doc(day.id).set(day.toJson());
    await _saveData();
    _syncTodayStateFromHistory();

    if (canShare) {
      if (result.perManagerShare != null) {
        bool changed = false;
        for (final entry in result.perManagerShare!.entries) {
          if (initialShareMap[entry.key] != entry.value) {
            changed = true;
            break;
          }
        }
        if (changed) {
          await _toggleUnitShareForDate(
            date: day.entrada,
            shiftId: day.id,
            perManagerShare: result.perManagerShare,
          );
        } else {
          await _syncShiftsToUnitManager();
        }
      } else if (result.share != initialShare) {
        await _toggleUnitShareForDate(
          date: day.entrada,
          shiftId: day.id,
          share: result.share,
        );
      } else {
        await _syncShiftsToUnitManager();
      }
    }

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
        baseHours: _getJornadaForDate(fEntrada),
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

                      _rebuild(() {
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
