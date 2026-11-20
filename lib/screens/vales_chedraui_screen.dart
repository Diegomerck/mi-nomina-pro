part of '../main.dart';

class _ValesChedrauiScreen extends StatefulWidget {
  final _TelevisaAppState appState;

  const _ValesChedrauiScreen({
    required this.appState,
  });

  @override
  State<_ValesChedrauiScreen> createState() => _ValesChedrauiScreenState();
}

typedef ValesChedrauiScreen = _ValesChedrauiScreen;

class _ValesChedrauiScreenState extends State<_ValesChedrauiScreen> {
  _TelevisaAppState get _appState => widget.appState;
  bool get _isDarkMode => _appState._isDarkMode;

  String _formatQuincenaItem(int q, int currentQuincena, int currentYear) {
    const List<String> monthNames = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    final int monthIndex = ((q - 1) ~/ 2).clamp(0, 11);
    final String monthName = monthNames[monthIndex];
    final bool isFirstHalf = (q % 2 != 0);
    final int startDay = isFirstHalf ? 1 : 16;
    final int endDay = isFirstHalf
        ? 15
        : DateTime(currentYear, monthIndex + 2, 0).day;

    final String qStr = "Quincena ${q.toString().padLeft(2, '0')}";
    final String startDayStr = startDay.toString().padLeft(2, '0');
    final String endDayStr = endDay.toString().padLeft(2, '0');
    String label = "$qStr • $startDayStr - $endDayStr $monthName";
    if (q == currentQuincena) {
      label += " (Actual 🟢)";
    }
    return label;
  }

  Future<void> _showEditReceiptAmountDialog() async {
    final TextEditingController amountController = TextEditingController(
      text: _appState._valesFomentoCulturalAmount > 0
          ? _appState._valesFomentoCulturalAmount.toStringAsFixed(2)
          : "",
    );

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor:
                  _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(
                    Icons.receipt_rounded,
                    color: _isDarkMode ? Colors.orange : const Color(0xFFC2410C),
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Monto del Recibo",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: _isDarkMode ? Colors.white : Colors.black,
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
                    "Ingresa el importe que aparece en tu recibo de la 2da quincena de cada mes por concepto de Vales de Fomento Cultural (ej. \$373.33):",
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white70 : const Color(0xFF475569),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.auto_awesome, size: 16),
                      label: const Text("Usar sugerido (\$373.33)"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            _isDarkMode ? Colors.orange : const Color(0xFFC2410C),
                        side: BorderSide(
                          color: _isDarkMode
                              ? Colors.orange.withAlpha(120)
                              : const Color(0xFFFDBA74),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          amountController.text = "373.33";
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: amountController,
                    autofocus: _appState._valesFomentoCulturalAmount <= 0,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      prefixText: "\$ ",
                      suffixText: "MXN",
                      hintText: "373.33",
                      labelText: "Monto mensual en recibo",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: _isDarkMode
                              ? Colors.white24
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor:
                        _isDarkMode ? Colors.white70 : const Color(0xFF64748B),
                  ),
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text("CANCELAR"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isDarkMode ? Colors.orange : const Color(0xFFC2410C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    final double? parsed =
                        double.tryParse(amountController.text.trim());
                    if (parsed != null && parsed >= 0) {
                      setState(() {
                        _appState._valesFomentoCulturalAmount = parsed;
                        _appState._valesFomentoCulturalAmountController.text =
                            parsed > 0 ? parsed.toStringAsFixed(2) : "";
                      });
                      await _appState._saveData(checkSalaryChange: false);
                      if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                    }
                  },
                  child: const Text("GUARDAR"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _showConfirmInitialAmountDialog() async {
    final TextEditingController amountController =
        TextEditingController(text: "373.33");
    String? errorMessage;

    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor:
                  _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (_isDarkMode
                              ? Colors.orange
                              : const Color(0xFFC2410C))
                          .withAlpha(35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.card_giftcard_rounded,
                      color: _isDarkMode
                          ? Colors.orange
                          : const Color(0xFFC2410C),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Activar Vales Chedraui",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: _isDarkMode ? Colors.white : Colors.black,
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
                    "El monto sugerido para el personal de Televisa es de \$373.33 mensuales (depositados en la 2da quincena de cada mes).\n\nConfirma o ingresa el importe exacto que aparece en tu recibo de nómina:",
                    style: TextStyle(
                      color: _isDarkMode
                          ? Colors.white70
                          : const Color(0xFF475569),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.auto_awesome, size: 16),
                      label: const Text("Usar sugerido (\$373.33)"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _isDarkMode
                            ? Colors.orange
                            : const Color(0xFFC2410C),
                        side: BorderSide(
                          color: _isDarkMode
                              ? Colors.orange.withAlpha(120)
                              : const Color(0xFFFDBA74),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          amountController.text = "373.33";
                          errorMessage = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    onChanged: (_) {
                      if (errorMessage != null) {
                        setDialogState(() {
                          errorMessage = null;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      prefixText: "\$ ",
                      suffixText: "MXN",
                      hintText: "373.33",
                      labelText: "Monto mensual en recibo",
                      errorText: errorMessage,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: _isDarkMode
                              ? Colors.white24
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor:
                        _isDarkMode ? Colors.white70 : const Color(0xFF64748B),
                  ),
                  onPressed: () => Navigator.pop(dialogCtx, false),
                  child: const Text("CANCELAR"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isDarkMode ? Colors.orange : const Color(0xFFC2410C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    final double? parsed =
                        double.tryParse(amountController.text.trim());
                    if (parsed == null || parsed <= 0) {
                      setDialogState(() {
                        errorMessage = "Ingresa un monto mayor a \$0.00";
                      });
                      return;
                    }
                    setState(() {
                      _appState._valesFomentoCulturalAmount = parsed;
                      _appState._valesFomentoCulturalAmountController.text =
                          parsed.toStringAsFixed(2);
                      _appState._valesFomentoCulturalEnabled = true;
                    });
                    await _appState._saveData(checkSalaryChange: false);
                    if (dialogCtx.mounted) {
                      Navigator.pop(dialogCtx, true);
                    }
                  },
                  child: const Text("CONFIRMAR"),
                ),
              ],
            );
          },
        );
      },
    );

    return result ?? false;
  }

  Future<void> _showOverrideDialog({
    required String pid,
    required int qNum,
    required double initialAmount,
  }) async {
    final TextEditingController amountController = TextEditingController(
      text: initialAmount.toStringAsFixed(2),
    );
    final String qLabel = "Quincena ${qNum.toString().padLeft(2, '0')}";

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor:
              _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Row(
            children: [
              Icon(
                Icons.edit_note_rounded,
                color: _isDarkMode
                    ? Colors.orangeAccent
                    : const Color(0xFFEA580C),
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Conciliar ($qLabel)",
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
                "Ingresa el importe exacto acreditado en tu tarjeta de vales para esta quincena:",
                style: TextStyle(
                  color:
                      _isDarkMode ? Colors.white70 : const Color(0xFF475569),
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: amountController,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(
                  color: _isDarkMode ? Colors.white : Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  prefixText: "\$ ",
                  suffixText: "MXN",
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: _isDarkMode
                          ? Colors.white24
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            if (_appState._valesPayStubOverrides.containsKey(pid))
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                ),
                onPressed: () async {
                  setState(() {
                    _appState._valesPayStubOverrides.remove(pid);
                  });
                  await _appState._saveData(checkSalaryChange: false);
                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                },
                child: const Text("Restablecer"),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(
                "Cancelar",
                style: TextStyle(
                  color:
                      _isDarkMode ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isDarkMode ? Colors.orange : const Color(0xFFEA580C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                final double? parsed =
                    double.tryParse(amountController.text.trim());
                if (parsed != null && parsed >= 0) {
                  setState(() {
                    _appState._valesPayStubOverrides[pid] = parsed;
                  });
                  await _appState._saveData(checkSalaryChange: false);
                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            "$qLabel conciliada con éxito: \$${parsed.toStringAsFixed(2)}"),
                        duration: const Duration(seconds: 2),
                        backgroundColor: const Color(0xFF15803D),
                      ),
                    );
                  }
                }
              },
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showExpenseDialog({Map<String, dynamic>? expenseToEdit}) async {
    final bool isEditing = expenseToEdit != null;
    final TextEditingController amountController = TextEditingController(
      text: isEditing
          ? ((expenseToEdit['monto'] as num?)?.toDouble() ?? 0.0)
              .toStringAsFixed(2)
          : "",
    );
    final TextEditingController conceptController = TextEditingController(
      text: isEditing ? (expenseToEdit['concepto']?.toString() ?? "") : "",
    );

    DateTime selectedDate = isEditing && expenseToEdit['fecha'] != null
        ? (DateTime.tryParse(expenseToEdit['fecha'].toString()) ??
            DateTime.now())
        : DateTime.now();

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final String dateDisplay = DateFormat('dd/MM/yyyy').format(selectedDate);

            return AlertDialog(
              backgroundColor:
                  _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit_rounded : Icons.add_shopping_cart_rounded,
                    color: _isDarkMode ? Colors.orange : const Color(0xFFC2410C),
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isEditing ? "Editar Gasto" : "Registrar Gasto de Vales",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: _isDarkMode ? Colors.white : Colors.black,
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
                      "Registra las compras realizadas con tu Monedero Chedraui para descontarlas de tu saldo disponible:",
                      style: TextStyle(
                        color: _isDarkMode
                            ? Colors.white70
                            : const Color(0xFF475569),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      autofocus: !isEditing,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        prefixText: "\$ ",
                        suffixText: "MXN",
                        labelText: "Monto gastado",
                        hintText: "0.00",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: _isDarkMode
                                ? Colors.white24
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: conceptController,
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        labelText: "Concepto / Tienda",
                        hintText: "Ej. Despensa Chedraui, Súper, Farmacia",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: _isDarkMode
                                ? Colors.white24
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2025, 1, 1),
                          lastDate: DateTime(2027, 12, 31),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _isDarkMode
                                ? Colors.white24
                                : const Color(0xFFCBD5E1),
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 18,
                                  color: _isDarkMode
                                      ? Colors.orange
                                      : const Color(0xFFC2410C),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  "Fecha del gasto:",
                                  style: TextStyle(
                                    color: _isDarkMode
                                        ? Colors.white70
                                        : const Color(0xFF64748B),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              dateDisplay,
                              style: TextStyle(
                                color:
                                    _isDarkMode ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: _isDarkMode
                        ? Colors.white70
                        : const Color(0xFF64748B),
                  ),
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text("CANCELAR"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isDarkMode ? Colors.orange : const Color(0xFFC2410C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    final double? parsedAmount =
                        double.tryParse(amountController.text.trim());
                    if (parsedAmount == null || parsedAmount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Ingresa un monto válido mayor a \$0"),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final String concepto = conceptController.text.trim().isEmpty
                        ? "Compra Chedraui"
                        : conceptController.text.trim();

                    setState(() {
                      if (isEditing) {
                        expenseToEdit['monto'] = parsedAmount;
                        expenseToEdit['concepto'] = concepto;
                        expenseToEdit['fecha'] =
                            selectedDate.toIso8601String().split('T').first;
                      } else {
                        _appState._valesExpenses.insert(0, {
                          'id': 'exp_${DateTime.now().millisecondsSinceEpoch}',
                          'monto': parsedAmount,
                          'concepto': concepto,
                          'fecha':
                              selectedDate.toIso8601String().split('T').first,
                        });
                      }
                    });

                    await _appState._saveData(checkSalaryChange: false);
                    if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  },
                  child: Text(isEditing ? "ACTUALIZAR" : "GUARDAR"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteExpense(Map<String, dynamic> expense) async {
    final Color textColor = _isDarkMode ? Colors.white : Colors.black;
    final Color subtextColor =
        _isDarkMode ? Colors.white70 : const Color(0xFF475569);
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return Theme(
          data: (_isDarkMode ? ThemeData.dark() : ThemeData.light()).copyWith(
            colorScheme: (_isDarkMode
                    ? const ColorScheme.dark()
                    : const ColorScheme.light())
                .copyWith(
              surface: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
            ),
          ),
          child: AlertDialog(
            backgroundColor:
                _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              "¿Eliminar gasto?",
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              "¿Estás seguro de que deseas eliminar este registro de gasto de \$${((expense['monto'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}? Esta acción restaurará el monto a tu saldo disponible.",
              style: TextStyle(
                color: subtextColor,
              ),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: _isDarkMode
                      ? Colors.white70
                      : const Color(0xFF64748B),
                ),
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("CANCELAR"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("ELIMINAR"),
              ),
            ],
          ),
        );
      },
    );

    if (confirm == true) {
      setState(() {
        _appState._valesExpenses.remove(expense);
      });
      await _appState._saveData(checkSalaryChange: false);
    }
  }

  Widget _buildSummaryCards({
    required double saldoDisponible,
    required double totalDepositado,
    required double totalGastado,
    required double proyeccionAnual,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color subtextColor,
    required Color accentColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF0F241D) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isDarkMode
              ? Colors.greenAccent.withAlpha(100)
              : const Color(0xFF86EFAC),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(_isDarkMode ? 30 : 10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _isDarkMode
                          ? Colors.green.withAlpha(40)
                          : const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: _isDarkMode
                          ? Colors.greenAccent
                          : const Color(0xFF15803D),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "MONEDERO CHEDRAUI",
                    style: TextStyle(
                      color: _isDarkMode
                          ? Colors.greenAccent
                          : const Color(0xFF15803D),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _isDarkMode
                      ? Colors.green.withAlpha(30)
                      : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _isDarkMode
                        ? Colors.greenAccent.withAlpha(70)
                        : const Color(0xFF86EFAC),
                  ),
                ),
                child: Text(
                  "2DA QUINCENA",
                  style: TextStyle(
                    color: _isDarkMode
                        ? Colors.greenAccent
                        : const Color(0xFF15803D),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Main Highlight: Saldo Restante Disponible
          Text(
            "SALDO DISPONIBLE ESTIMADO",
            style: TextStyle(
              color: subtextColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "\$${saldoDisponible.toStringAsFixed(2)}",
            style: TextStyle(
              color: _isDarkMode
                  ? Colors.greenAccent
                  : const Color(0xFF15803D),
              fontWeight: FontWeight.w900,
              fontSize: 32,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Divider(
            color: _isDarkMode
                ? Colors.greenAccent.withAlpha(50)
                : const Color(0xFFBBF7D0),
            thickness: 1,
            height: 1,
          ),
          const SizedBox(height: 14),

          // 3 Metric Rows
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Total Percibido",
                      style: TextStyle(color: subtextColor, fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "\$${totalDepositado.toStringAsFixed(2)}",
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Total Gastado",
                      style: TextStyle(color: subtextColor, fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "-\$${totalGastado.toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Proyección Anual",
                      style: TextStyle(color: subtextColor, fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "\$${proyeccionAnual.toStringAsFixed(2)}",
                      style: TextStyle(
                        color: _isDarkMode
                            ? Colors.orangeAccent
                            : const Color(0xFFC2410C),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfigCard({
    required int currentQuincena,
    required int currentYear,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color subtextColor,
    required Color accentColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(_isDarkMode ? 30 : 10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, color: accentColor, size: 20),
              const SizedBox(width: 8),
              Text(
                "Configuración de Recibo",
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Monto del recibo row
          InkWell(
            onTap: _showEditReceiptAmountDialog,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _isDarkMode
                    ? Colors.white.withAlpha(8)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isDarkMode
                      ? Colors.white12
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Monto del recibo (2da Quincena)",
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _appState._valesFomentoCulturalAmount > 0
                              ? "Se aplica automáticamente en Nómina a 2das quincenas"
                              : "Toca para configurar el monto de tu recibo",
                          style: TextStyle(color: subtextColor, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: _appState._valesFomentoCulturalAmount <= 0
                            ? const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4)
                            : EdgeInsets.zero,
                        decoration: _appState._valesFomentoCulturalAmount <= 0
                            ? BoxDecoration(
                                color: (_isDarkMode
                                        ? Colors.orange
                                        : const Color(0xFFC2410C))
                                    .withAlpha(30),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: (_isDarkMode
                                          ? Colors.orange
                                          : const Color(0xFFC2410C))
                                      .withAlpha(80),
                                ),
                              )
                            : null,
                        child: Text(
                          _appState._valesFomentoCulturalAmount > 0
                              ? "\$${_appState._valesFomentoCulturalAmount.toStringAsFixed(2)}"
                              : "Sin confirmar • Configurar",
                          style: TextStyle(
                            color: _appState._valesFomentoCulturalAmount > 0
                                ? accentColor
                                : (_isDarkMode
                                    ? Colors.orangeAccent
                                    : const Color(0xFFC2410C)),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        _appState._valesFomentoCulturalAmount > 0
                            ? Icons.edit_outlined
                            : Icons.tune_rounded,
                        size: 16,
                        color: accentColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Quincena de inicio dropdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Quincena de inicio en el ciclo:",
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _isDarkMode
                      ? Colors.white.withAlpha(8)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _isDarkMode
                        ? Colors.white12
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: _appState._valesStartQuincena.clamp(1, 24),
                    dropdownColor:
                        _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    items: List.generate(24, (index) {
                      final int q = index + 1;
                      return DropdownMenuItem<int>(
                        value: q,
                        child: Text(
                          _formatQuincenaItem(q, currentQuincena, currentYear),
                        ),
                      );
                    }),
                    onChanged: (newQ) async {
                      if (newQ != null) {
                        setState(() {
                          _appState._valesStartQuincena = newQ;
                        });
                        await _appState._saveData(checkSalaryChange: false);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesSection({
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color subtextColor,
    required Color accentColor,
  }) {
    final expenses = _appState._valesExpenses;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(_isDarkMode ? 30 : 10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Add Button
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accentColor.withAlpha(_isDarkMode ? 35 : 25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.shopping_bag_rounded,
                        color: accentColor, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Control de Gastos",
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                onPressed: () => _showExpenseDialog(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text(
                  "Registrar Gasto",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Registra tus compras en Chedraui para llevar el saldo neto restante disponible:",
            style: TextStyle(color: subtextColor, fontSize: 12),
          ),
          const SizedBox(height: 14),

          if (expenses.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: _isDarkMode
                    ? Colors.white.withAlpha(5)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isDarkMode
                      ? Colors.white12
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 36,
                    color: subtextColor.withAlpha(120),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "No has registrado gastos aún",
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Toca en 'Registrar Gasto' cada vez que uses tu monedero.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: subtextColor, fontSize: 11),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: expenses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = expenses[index];
                final double monto =
                    ((item['monto'] as num?)?.toDouble()) ?? 0.0;
                final String concepto =
                    (item['concepto']?.toString()) ?? "Compra Chedraui";
                final String rawFecha = (item['fecha']?.toString()) ?? "";
                String fechaDisplay = rawFecha;
                try {
                  final dt = DateTime.parse(rawFecha);
                  fechaDisplay = DateFormat('dd/MM/yyyy').format(dt);
                } catch (_) {}

                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _isDarkMode
                        ? Colors.white.withAlpha(8)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _isDarkMode
                          ? Colors.white12
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withAlpha(_isDarkMode ? 30 : 20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.receipt_rounded,
                          size: 18,
                          color: Colors.redAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              concepto,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              fechaDisplay,
                              style: TextStyle(
                                  color: subtextColor, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "-\$${monto.toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, size: 18, color: subtextColor),
                        color: _isDarkMode
                            ? const Color(0xFF1E293B)
                            : Colors.white,
                        onSelected: (val) {
                          if (val == 'edit') {
                            _showExpenseDialog(expenseToEdit: item);
                          } else if (val == 'delete') {
                            _deleteExpense(item);
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 16),
                                SizedBox(width: 8),
                                Text("Editar"),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete,
                                    size: 16, color: Colors.redAccent),
                                SizedBox(width: 8),
                                Text("Eliminar",
                                    style: TextStyle(color: Colors.redAccent)),
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
        ],
      ),
    );
  }

  Widget _buildReconciliationSection({
    required List<Map<String, dynamic>> secondQuincenasList,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color subtextColor,
    required Color accentColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(_isDarkMode ? 30 : 10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(_isDarkMode ? 35 : 25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Historial y Conciliación de Depósitos",
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Depósitos en monedero en las 2das quincenas del ciclo",
                      style: TextStyle(color: subtextColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (secondQuincenasList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  "No hay 2das quincenas en el ciclo configurado.",
                  style: TextStyle(color: subtextColor, fontSize: 12),
                ),
              ),
            )
          else
            ...secondQuincenasList.map((item) {
              final String pid = item['pid'] as String;
              final int qNum = item['qNum'] as int;
              final Map cfg = item['cfg'] as Map;
              final double defaultAmount = item['defaultAmount'] as double;
              final double actualAmount = item['actualAmount'] as double;
              final bool isVerified = item['isVerified'] as bool;
              final bool isPayoutPassed =
                  (item['isPayoutPassed'] as bool?) ?? false;
              final String payoutStr = (cfg['payout'] as String?) ?? '';
              final String qLabel = "Quincena ${qNum.toString().padLeft(2, '0')}";

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isDarkMode
                      ? (isVerified
                          ? const Color(0xFF0F241D)
                          : const Color(0xFF1E293B))
                      : (isVerified
                          ? const Color(0xFFF0FDF4)
                          : const Color(0xFFF8FAFC)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isVerified
                        ? (_isDarkMode
                            ? Colors.greenAccent.withAlpha(70)
                            : const Color(0xFF86EFAC))
                        : (!isPayoutPassed
                            ? (_isDarkMode
                                ? Colors.blueGrey.withAlpha(50)
                                : const Color(0xFFCBD5E1))
                            : (_isDarkMode
                                ? Colors.orangeAccent.withAlpha(70)
                                : const Color(0xFFFDBA74))),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: _isDarkMode
                                    ? Colors.white10
                                    : const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                qLabel,
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              payoutStr.isNotEmpty
                                  ? "Fecha de pago: $payoutStr"
                                  : "2da Quincena",
                              style: TextStyle(
                                color: subtextColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        if (isVerified)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _isDarkMode
                                  ? Colors.green.withAlpha(30)
                                  : const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 12,
                                  color: _isDarkMode
                                      ? Colors.greenAccent
                                      : const Color(0xFF15803D),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  "Conciliado ✓",
                                  style: TextStyle(
                                    color: _isDarkMode
                                        ? Colors.greenAccent
                                        : const Color(0xFF15803D),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (!isPayoutPassed)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _isDarkMode
                                  ? Colors.blue.withAlpha(30)
                                  : const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "Programado",
                              style: TextStyle(
                                color: _isDarkMode
                                    ? Colors.lightBlueAccent
                                    : const Color(0xFF0284C7),
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
                              color: _isDarkMode
                                  ? Colors.orange.withAlpha(30)
                                  : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "Por conciliar",
                              style: TextStyle(
                                color: _isDarkMode
                                    ? Colors.orangeAccent
                                    : const Color(0xFFB45309),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (isVerified) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Monto acreditado: \$${actualAmount.toStringAsFixed(2)}",
                            style: TextStyle(
                              color: textColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          InkWell(
                            onTap: () => _showOverrideDialog(
                              pid: pid,
                              qNum: qNum,
                              initialAmount: actualAmount,
                            ),
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined,
                                      size: 12, color: accentColor),
                                  const SizedBox(width: 3),
                                  Text(
                                    "Corregir monto",
                                    style: TextStyle(
                                      color: accentColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else if (!isPayoutPassed) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Depósito estimado: \$${defaultAmount.toStringAsFixed(2)}",
                            style: TextStyle(
                              color: textColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Podrás conciliar el recibo a partir del $payoutStr",
                        style: TextStyle(
                          color: subtextColor,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _isDarkMode
                              ? Colors.black.withAlpha(50)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isDarkMode
                                ? Colors.white12
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "¿Tu recibo de nómina acreditó exactamente \$${defaultAmount.toStringAsFixed(2)}?",
                              style: TextStyle(
                                color: textColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isDarkMode
                                          ? const Color(0xFF166534)
                                          : const Color(0xFF15803D),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      elevation: 0,
                                    ),
                                    onPressed: () async {
                                      setState(() {
                                        _appState._valesPayStubOverrides[pid] =
                                            defaultAmount;
                                      });
                                      await _appState._saveData(
                                          checkSalaryChange: false);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                "$qLabel confirmada: \$${defaultAmount.toStringAsFixed(2)}"),
                                            duration:
                                                const Duration(seconds: 2),
                                            backgroundColor:
                                                const Color(0xFF15803D),
                                          ),
                                        );
                                      }
                                    },
                                    child: const Text(
                                      "Sí, coincide ✓",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: accentColor,
                                      side: BorderSide(color: accentColor),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () => _showOverrideDialog(
                                      pid: pid,
                                      qNum: qNum,
                                      initialAmount: defaultAmount,
                                    ),
                                    child: const Text(
                                      "Corregir monto",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildExpirationNoticeCard({
    required Color cardBg,
    required Color textColor,
    required Color subtextColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDarkMode
            ? const Color(0xFF2D1F0E)
            : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isDarkMode
              ? Colors.amber.withAlpha(120)
              : const Color(0xFFFCD34D),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: _isDarkMode ? Colors.amberAccent : const Color(0xFFD97706),
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Vigencia y Caducidad de Monedero Chedraui",
                  style: TextStyle(
                    color: _isDarkMode
                        ? Colors.amberAccent
                        : const Color(0xFFB45309),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "• Caducidad por inactividad: Tu saldo acumulado en Monedero Chedraui tiene vigencia. Si la tarjeta pasa 6 meses consecutivos sin registrar compras o movimientos, el saldo acumulado expira por inactividad.\n\n• Recomendación: Realiza al menos una compra periódica (incluso de monto mínimo) para mantener tu monedero y saldo siempre activos.",
            style: TextStyle(
              color: _isDarkMode ? Colors.white70 : const Color(0xFF78350F),
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Divider(
            color: _isDarkMode
                ? Colors.amber.withAlpha(50)
                : const Color(0xFFFDE68A),
          ),
          const SizedBox(height: 10),
          Text(
            "Canales Oficiales de Consulta de Saldo Chedraui:",
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.chat_bubble_outline_rounded,
                  size: 16, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white70 : const Color(0xFF334155),
                      fontSize: 12,
                      height: 1.35,
                    ),
                    children: const [
                      TextSpan(
                        text: "WhatsApp Oficial: ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: "Envía un mensaje al "),
                      TextSpan(
                        text: "55 4370 7075",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      TextSpan(text: " para consultar tu saldo al instante."),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.sms_outlined, size: 16, color: Colors.blueAccent),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white70 : const Color(0xFF334155),
                      fontSize: 12,
                      height: 1.35,
                    ),
                    children: const [
                      TextSpan(
                        text: "Mensaje SMS: ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: "Envía la palabra "),
                      TextSpan(
                        text: "SALDO",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: " seguida de tus 16 dígitos al número "),
                      TextSpan(
                        text: "64243",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      TextSpan(text: "."),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    const String waUrl =
                        "https://wa.me/525543707075?text=Hola%2C%20deseo%20consultar%20el%20saldo%20de%20mi%20Monedero%20Chedraui";
                    final uri = Uri.parse(waUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    } else {
                      await Clipboard.setData(
                          const ClipboardData(text: "5543707075"));
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                "Número de WhatsApp copiado: 55 4370 7075"),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.chat, size: 16),
                  label: const Text(
                    "WhatsApp Chedraui",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blueAccent,
                    side: const BorderSide(color: Colors.blueAccent),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    await Clipboard.setData(
                        const ClipboardData(text: "64243"));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text("Número SMS copiado al portapapeles: 64243"),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text(
                    "Copiar SMS 64243",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color accentColor =
        _isDarkMode ? Colors.orange : const Color(0xFFC2410C);
    final Color cardBg = _isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final Color borderColor =
        _isDarkMode ? Colors.white12 : const Color(0xFFCBD5E1);
    final Color textColor = _isDarkMode ? Colors.white : Colors.black;
    final Color subtextColor =
        _isDarkMode ? Colors.white60 : const Color(0xFF475569);
    final Color bgColor =
        _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);

    final DateTime now = DateTime.now();
    final int currentQuincena = (now.month - 1) * 2 + (now.day <= 15 ? 1 : 2);
    final int currentYear = now.year;

    final metrics = _appState.calculateValesChedrauiMetrics();
    final double saldoDisponible = metrics['saldoDisponible'] as double;
    final double totalDepositado = metrics['totalDepositado'] as double;
    final double totalGastado = metrics['totalGastado'] as double;
    final double proyeccionAnual = metrics['proyeccionAnual'] as double;
    final List<Map<String, dynamic>> secondQuincenasList =
        (metrics['allSecondQuincenas'] as List<Map<String, dynamic>>?) ?? [];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardBg,
        foregroundColor: textColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Vales de Fomento Cultural",
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // 1. Main Toggle Card
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _appState._valesFomentoCulturalEnabled
                      ? (_isDarkMode
                          ? Colors.orange.withAlpha(120)
                          : const Color(0xFFFDBA74))
                      : borderColor,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(_isDarkMode ? 30 : 10),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _appState._valesFomentoCulturalEnabled
                            ? (_isDarkMode
                                ? Colors.green.withAlpha(35)
                                : const Color(0xFFDCFCE7))
                            : accentColor.withAlpha(_isDarkMode ? 35 : 25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _appState._valesFomentoCulturalEnabled
                            ? Icons.card_giftcard_rounded
                            : Icons.card_giftcard_outlined,
                        color: _appState._valesFomentoCulturalEnabled
                            ? (_isDarkMode
                                ? Colors.greenAccent
                                : const Color(0xFF16A34A))
                            : accentColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "¿Cuentas con Vales de Fomento Cultural?",
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _appState._valesFomentoCulturalEnabled
                                ? "Activo: Monedero Chedraui en 2das quincenas"
                                : "Monedero Chedraui depositado en 2da quincena",
                            style: TextStyle(color: subtextColor, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _appState._valesFomentoCulturalEnabled,
                      activeColor:
                          _isDarkMode ? Colors.orange : const Color(0xFFD9531E),
                      onChanged: (val) async {
                        if (val) {
                          if (_appState._valesFomentoCulturalAmount <= 0) {
                            final bool confirmed =
                                await _showConfirmInitialAmountDialog();
                            if (!confirmed) {
                              return;
                            }
                          } else {
                            setState(() {
                              _appState._valesFomentoCulturalEnabled = true;
                            });
                            await _appState._saveData(checkSalaryChange: false);
                          }
                        } else {
                          setState(() {
                            _appState._valesFomentoCulturalEnabled = false;
                          });
                          await _appState._saveData(checkSalaryChange: false);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            if (_appState._valesFomentoCulturalEnabled) ...[
              // 2. Summary Cards
              _buildSummaryCards(
                saldoDisponible: saldoDisponible,
                totalDepositado: totalDepositado,
                totalGastado: totalGastado,
                proyeccionAnual: proyeccionAnual,
                cardBg: cardBg,
                borderColor: borderColor,
                textColor: textColor,
                subtextColor: subtextColor,
                accentColor: accentColor,
              ),

              // 3. Monto del recibo & Quincena de inicio dropdown
              _buildConfigCard(
                currentQuincena: currentQuincena,
                currentYear: currentYear,
                cardBg: cardBg,
                borderColor: borderColor,
                textColor: textColor,
                subtextColor: subtextColor,
                accentColor: accentColor,
              ),

              // 4. Control de Gastos
              _buildExpensesSection(
                cardBg: cardBg,
                borderColor: borderColor,
                textColor: textColor,
                subtextColor: subtextColor,
                accentColor: accentColor,
              ),

              // 5. Historial y Conciliación de Depósitos
              _buildReconciliationSection(
                secondQuincenasList: secondQuincenasList,
                cardBg: cardBg,
                borderColor: borderColor,
                textColor: textColor,
                subtextColor: subtextColor,
                accentColor: accentColor,
              ),

              // 6. Tarjeta Informativa de Caducidad
              _buildExpirationNoticeCard(
                cardBg: cardBg,
                textColor: textColor,
                subtextColor: subtextColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
