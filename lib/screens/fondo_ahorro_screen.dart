part of '../main.dart';

class _FondoAhorroScreen extends StatefulWidget {
  final _TelevisaAppState appState;

  const _FondoAhorroScreen({
    required this.appState,
  });

  @override
  State<_FondoAhorroScreen> createState() => _FondoAhorroScreenState();
}

class _FondoAhorroScreenState extends State<_FondoAhorroScreen> {
  _TelevisaAppState get _appState => widget.appState;
  bool get _isDarkMode => _appState._isDarkMode;
  bool _isCutoffUnlocked = false;

  @override
  void initState() {
    super.initState();
    if (_appState._fondoAhorroPctController.text.isEmpty) {
      _appState._fondoAhorroPctController.text =
          _appState._fondoAhorroPct.toStringAsFixed(1);
    }
  }

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

  Widget _buildMatchRatioPill({
    required String label,
    required double ratio,
    required String controllerText,
    required Color accentColor,
  }) {
    final bool isSelected = _appState._fondoAhorroMatchRatio == ratio;
    final Color bg = isSelected
        ? (_isDarkMode
            ? Colors.orange.withAlpha(45)
            : const Color(0xFFFEF3C7))
        : (_isDarkMode
            ? const Color(0xFF0F172A)
            : const Color(0xFFF1F5F9));
    final Color borderCol = isSelected
        ? (_isDarkMode ? Colors.orange : const Color(0xFFEA580C))
        : (_isDarkMode ? Colors.white24 : const Color(0xFFCBD5E1));
    final Color txtCol = isSelected
        ? (_isDarkMode ? Colors.orange : const Color(0xFFEA580C))
        : (_isDarkMode ? Colors.white : const Color(0xFF334155));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _appState._fondoAhorroMatchRatio = ratio;
            _appState._fondoAhorroMatchRatioController.text = controllerText;
          });
          _appState._saveData(checkSalaryChange: false);
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderCol,
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                Icon(
                  Icons.check,
                  size: 16,
                  color: txtCol,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: txtCol,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavingsCard([Map<String, dynamic>? metricsParam]) {
    final metrics =
        metricsParam ?? _appState.calculateFondoAhorroCycleMetrics();
    final double accumulatedTotal = metrics['accumulatedTotal'] as double;
    final double accumulatedEmployee = metrics['accumulatedEmployee'] as double;
    final double accumulatedEmployer = metrics['accumulatedEmployer'] as double;
    final int accumulatedQuincenas = metrics['accumulatedQuincenas'] as int;
    final double projectedTotal = metrics['projectedTotal'] as double;
    final double projectedEmployee = metrics['projectedEmployee'] as double;
    final double projectedEmployer = metrics['projectedEmployer'] as double;
    final Map<String, double> standardFaCalc =
        metrics['standardFaCalc'] as Map<String, double>;

    final int totalCycleQuincenas =
        (_appState._fondoAhorroCutoffQuincena - _appState._fondoAhorroStartQuincena + 1)
            .clamp(1, 24);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _isDarkMode
            ? const Color(0xFF0F241D)
            : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isDarkMode
              ? Colors.greenAccent.withAlpha(100)
              : const Color(0xFF86EFAC),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header
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
                      Icons.savings_rounded,
                      color: _isDarkMode
                          ? Colors.greenAccent
                          : const Color(0xFF15803D),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "FONDO DE AHORRO ANUAL",
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
                        ? Colors.greenAccent.withAlpha(80)
                        : const Color(0xFF86EFAC),
                  ),
                ),
                child: Text(
                  "Entrega: Quincena ${_appState._fondoAhorroCutoffQuincena.toString().padLeft(2, '0')}",
                  style: TextStyle(
                    color: _isDarkMode
                        ? Colors.greenAccent
                        : const Color(0xFF166534),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2 Big Values: Saldo Acumulado & Proyección Anual
          Row(
            children: [
              // Saldo Acumulado
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isDarkMode
                        ? Colors.black.withAlpha(80)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isDarkMode
                          ? Colors.white10
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "SALDO ACUMULADO",
                        style: TextStyle(
                          color: _isDarkMode
                              ? Colors.white70
                              : const Color(0xFF475569),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "\$${accumulatedTotal.toStringAsFixed(2)}",
                          style: TextStyle(
                            color: _isDarkMode
                                ? Colors.greenAccent
                                : const Color(0xFF15803D),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Tú: \$${accumulatedEmployee.toStringAsFixed(2)}\nEmp: \$${accumulatedEmployer.toStringAsFixed(2)}",
                        style: TextStyle(
                          color: _isDarkMode
                              ? Colors.white54
                              : const Color(0xFF64748B),
                          fontSize: 10,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Proyección Anual
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isDarkMode
                        ? Colors.black.withAlpha(80)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isDarkMode
                          ? Colors.white10
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "ENTREGA PROYECTADA",
                        style: TextStyle(
                          color: _isDarkMode
                              ? Colors.white70
                              : const Color(0xFF475569),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "\$${projectedTotal.toStringAsFixed(2)}",
                          style: TextStyle(
                            color: _isDarkMode
                                ? Colors.orangeAccent
                                : const Color(0xFFC2410C),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Tú: \$${projectedEmployee.toStringAsFixed(2)}\nEmp: \$${projectedEmployer.toStringAsFixed(2)}",
                        style: TextStyle(
                          color: _isDarkMode
                              ? Colors.white54
                              : const Color(0xFF64748B),
                          fontSize: 10,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress bar: Quincenas cotizadas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Ciclo de Ahorro: $accumulatedQuincenas de $totalCycleQuincenas quincenas",
                style: TextStyle(
                  color:
                      _isDarkMode ? Colors.white70 : const Color(0xFF334155),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                "${totalCycleQuincenas > 0 ? ((accumulatedQuincenas / totalCycleQuincenas) * 100).clamp(0, 100).toStringAsFixed(0) : 0}%",
                style: TextStyle(
                  color: _isDarkMode
                      ? Colors.greenAccent
                      : const Color(0xFF15803D),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: totalCycleQuincenas > 0
                  ? (accumulatedQuincenas / totalCycleQuincenas)
                      .clamp(0.0, 1.0)
                  : 0.0,
              backgroundColor:
                  _isDarkMode ? Colors.white10 : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                _isDarkMode ? Colors.greenAccent : const Color(0xFF16A34A),
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 10),

          // Quincenal regular detail row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Ahorro quincenal regular:",
                style: TextStyle(
                  color: _isDarkMode
                      ? Colors.white54
                      : const Color(0xFF64748B),
                  fontSize: 11,
                ),
              ),
              Text(
                "\$${standardFaCalc['totalSavings']!.toStringAsFixed(2)} (\$${standardFaCalc['deduction']!.toStringAsFixed(2)} + \$${standardFaCalc['employerMatch']!.toStringAsFixed(2)})",
                style: TextStyle(
                  color: _isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value, Color valColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: _isDarkMode ? Colors.white70 : const Color(0xFF475569),
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditPercentageDialog(BuildContext context) async {
    final TextEditingController pctController = TextEditingController(
      text: _appState._fondoAhorroPct.toStringAsFixed(1),
    );
    String? errorMessage;

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor:
                  _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.percent_rounded,
                    color: _isDarkMode
                        ? Colors.orangeAccent
                        : const Color(0xFFEA580C),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Editar Porcentaje de Ahorro",
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
                    "Define el porcentaje de aportación de tu sueldo base quincenal. El tope máximo permitido exento de ISR es 13.0% (LISR Art. 27 Fracc. XI).",
                    style: TextStyle(
                      color: _isDarkMode
                          ? Colors.white70
                          : const Color(0xFF475569),
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: pctController,
                          autofocus: true,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          style: TextStyle(
                            color: _isDarkMode ? Colors.white : Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            suffixText: "%",
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: _isDarkMode
                                    ? Colors.white24
                                    : const Color(0xFFCBD5E1),
                              ),
                            ),
                          ),
                          onChanged: (val) {
                            final parsed = double.tryParse(val.trim());
                            if (parsed == null || parsed < 0) {
                              setDialogState(() {
                                errorMessage = "Ingresa un porcentaje válido";
                              });
                            } else if (parsed > 13.0) {
                              setDialogState(() {
                                errorMessage =
                                    "El tope máximo permitido es 13.0%";
                              });
                            } else {
                              if (errorMessage != null) {
                                setDialogState(() {
                                  errorMessage = null;
                                });
                              }
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          side: BorderSide(
                            color: _isDarkMode
                                ? Colors.orangeAccent
                                : const Color(0xFFEA580C),
                          ),
                        ),
                        onPressed: () {
                          pctController.text = "13.0";
                          pctController.selection = TextSelection.fromPosition(
                            const TextPosition(offset: 4),
                          );
                          setDialogState(() {
                            errorMessage = null;
                          });
                        },
                        child: Text(
                          "13% Máx LISR",
                          style: TextStyle(
                            color: _isDarkMode
                                ? Colors.orangeAccent
                                : const Color(0xFFEA580C),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      errorMessage!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text(
                    "Cancelar",
                    style: TextStyle(
                      color: _isDarkMode
                          ? Colors.white60
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isDarkMode
                        ? Colors.orange
                        : const Color(0xFFEA580C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    final double? parsed =
                        double.tryParse(pctController.text.trim());
                    if (parsed == null || parsed < 0) {
                      setDialogState(() {
                        errorMessage = "Ingresa un porcentaje válido";
                      });
                      return;
                    }
                    final double finalPct =
                        parsed > 13.0 ? 13.0 : parsed;
                    final nav = Navigator.of(dialogCtx);
                    setState(() {
                      _appState._fondoAhorroPct = finalPct;
                      _appState._fondoAhorroPctController.text =
                          finalPct.toStringAsFixed(1);
                    });
                    await _appState._saveData(checkSalaryChange: false);
                    if (dialogCtx.mounted) {
                      nav.pop();
                    }
                  },
                  child: const Text("Guardar Cambios"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditPayStubDialog(
    BuildContext context,
    String pid,
    int qNum,
    double initialAmount,
  ) async {
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
                  "Corregir Descuento ($qLabel)",
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
                "Ingresa el importe exacto descontado por concepto de Fondo de Ahorro en tu recibo de nómina de esta quincena:",
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
                      borderRadius: BorderRadius.circular(8)),
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
                  final messenger = ScaffoldMessenger.of(context);
                  final nav = Navigator.of(dialogCtx);
                  setState(() {
                    _appState._fondoAhorroPayStubOverrides[pid] = parsed;
                  });
                  _appState.calibrateFondoAhorroFixedAmount();
                  await _appState._saveData(checkSalaryChange: false);
                  if (dialogCtx.mounted) {
                    nav.pop();
                  }
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                            "$qLabel corregida con éxito: \$${parsed.toStringAsFixed(2)}"),
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

  Widget _buildPayStubReconciliationCard({
    required Map<String, dynamic> metrics,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color subtextColor,
    required Color accentColor,
  }) {
    final List<Map<String, dynamic>> rawPaid = metrics['paidQuincenas'] != null
        ? List<Map<String, dynamic>>.from(metrics['paidQuincenas'] as List)
        : [];

    final List<Map<String, dynamic>> paidList = rawPaid
      ..sort((a, b) => (b['qNum'] as int).compareTo(a['qNum'] as int));

    final double? fixedAmount = metrics['fixedAmount'] as double?;

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
                      "Conciliación de Recibos de Nómina",
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Verifica o ajusta el descuento quincenal real de tu recibo",
                      style: TextStyle(color: subtextColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Calibration banner if 4-consecutive triggered
          if (fixedAmount != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _isDarkMode
                    ? Colors.blue.withAlpha(30)
                    : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isDarkMode
                      ? Colors.blueAccent.withAlpha(80)
                      : const Color(0xFF93C5FD),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: _isDarkMode
                        ? Colors.blueAccent
                        : const Color(0xFF1D4ED8),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Calibración automática activa: 4 quincenas consecutivas con \$${fixedAmount.toStringAsFixed(2)} registradas. Este monto se aplica como valor sugerido en las siguientes quincenas del ciclo.",
                      style: TextStyle(
                        color: _isDarkMode
                            ? Colors.blueAccent
                            : const Color(0xFF1E40AF),
                        fontSize: 11,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (paidList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  "Aún no hay quincenas pagadas en el ciclo actual.\nConforme se cumplan las fechas de pago, aparecerán aquí para su conciliación.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: subtextColor, fontSize: 12, height: 1.4),
                ),
              ),
            )
          else
            ...paidList.map((item) {
              final String pid = item['pid'] as String;
              final int qNum = item['qNum'] as int;
              final Map cfg = item['cfg'] as Map;
              final double calculatedDeduction =
                  item['calculatedDeduction'] as double;
              final double actualDeduction =
                  item['actualDeduction'] as double;
              final double employerMatch = item['employerMatch'] as double;
              final double totalSavings = item['totalSavings'] as double;
              final bool isVerified = item['isVerified'] as bool;
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
                        : (_isDarkMode
                            ? Colors.orangeAccent.withAlpha(70)
                            : const Color(0xFFFDBA74)),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row top: Q number, Payout date, Status badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
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
                              "Fecha de pago: $payoutStr",
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
                      // Verified view
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Descuento en recibo: -\$${actualDeduction.toStringAsFixed(2)}",
                            style: TextStyle(
                              color: textColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            "Total Quincena: \$${totalSavings.toStringAsFixed(2)}",
                            style: TextStyle(
                              color: _isDarkMode
                                  ? Colors.greenAccent
                                  : const Color(0xFF15803D),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Tú: \$${actualDeduction.toStringAsFixed(2)} + Empresa: \$${employerMatch.toStringAsFixed(2)}",
                            style:
                                TextStyle(color: subtextColor, fontSize: 11),
                          ),
                          InkWell(
                            onTap: () => _showEditPayStubDialog(
                              context,
                              pid,
                              qNum,
                              actualDeduction,
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
                    ] else ...[
                      // Prompt for unverified quincena
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
                              "¿Tu recibo de nómina descontó exactamente \$${calculatedDeduction.toStringAsFixed(2)}?",
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
                                      final messenger =
                                          ScaffoldMessenger.of(context);
                                      setState(() {
                                        _appState._fondoAhorroPayStubOverrides[
                                            pid] = calculatedDeduction;
                                      });
                                      _appState.calibrateFondoAhorroFixedAmount();
                                      await _appState._saveData(
                                          checkSalaryChange: false);
                                      if (mounted) {
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                "$qLabel confirmada: \$${calculatedDeduction.toStringAsFixed(2)}"),
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
                                    onPressed: () => _showEditPayStubDialog(
                                      context,
                                      pid,
                                      qNum,
                                      calculatedDeduction,
                                    ),
                                    child: const Text(
                                      "No, corregir monto ✎",
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

  Widget _buildInformationalGuideCard({
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color subtextColor,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(_isDarkMode ? 30 : 8),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(_isDarkMode ? 35 : 25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Guía Informativa y Marco Legal LISR",
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildGuideItem(
            icon: Icons.account_balance_wallet_outlined,
            iconColor: _isDarkMode ? Colors.greenAccent : const Color(0xFF16A34A),
            title: "Saldo Acumulado",
            description:
                "Representa el ahorro real acumulado hasta el momento en el ciclo anual en curso. Suma tus deducciones de nómina más las aportaciones patronales de las quincenas efectivamente transcurridas y cotizadas.",
            textColor: textColor,
            subtextColor: subtextColor,
          ),
          const SizedBox(height: 12),
          _buildGuideItem(
            icon: Icons.trending_up_rounded,
            iconColor: _isDarkMode ? Colors.orangeAccent : const Color(0xFFEA580C),
            title: "Entrega Proyectada",
            description:
                "Es el monto total estimado que recibirás al cierre de tu ciclo de ahorro (quincena de corte). Incluye tu ahorro actual más las aportaciones previstas tuyas y de la empresa hasta finalizar el periodo.",
            textColor: textColor,
            subtextColor: subtextColor,
          ),
          const SizedBox(height: 12),
          _buildGuideItem(
            icon: Icons.event_available_rounded,
            iconColor: _isDarkMode ? Colors.blueAccent : const Color(0xFF2563EB),
            title: "Ciclo de Ahorro y Fecha de Entrega",
            description:
                "El Fondo de Ahorro opera por ciclos anuales de 12 meses. De conformidad con las disposiciones fiscales y la Ley del Impuesto sobre la Renta (LISR), la entrega de los fondos y sus rendimientos debe efectuarse una vez al año, típicamente durante los primeros 5 días de diciembre (al cierre de la Quincena 22 / finales de noviembre), garantizando el beneficio de previsión social.",
            textColor: textColor,
            subtextColor: subtextColor,
          ),
          const SizedBox(height: 12),
          _buildGuideItem(
            icon: Icons.verified_user_outlined,
            iconColor: _isDarkMode ? Colors.purpleAccent : const Color(0xFF9333EA),
            title: "Tope Legal Exento (1.3 UMA)",
            description:
                "Conforme al Art. 27 Fracc. XI de la LISR, las aportaciones del fondo de ahorro están exentas de ISR siempre que no superen el 13% del salario del trabajador ni el límite legal de 1.3 veces la UMA mensualizada (\$${_TelevisaAppState.kFondoAhorroQuincenaCap.toStringAsFixed(2)} MXN por quincena en 2026). La app aplica este tope automáticamente para proteger tu exención fiscal.",
            textColor: textColor,
            subtextColor: subtextColor,
          ),
        ],
      ),
    );
  }

  Widget _buildGuideItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required Color textColor,
    required Color subtextColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: subtextColor,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
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
    final metrics = _appState.calculateFondoAhorroCycleMetrics();

    // Current calculation for live preview
    final double currentDailySalary = _appState._getSalaryForDate(now);
    final double baseQuincena = currentDailySalary * 15.0;
    final faCalc = _appState.calculateFondoAhorro(baseEarned: baseQuincena);
    final double deduction = faCalc['deduction']!;
    final double employerMatch = faCalc['employerMatch']!;
    final double totalSavings = faCalc['totalSavings']!;
    final double uncapped = faCalc['uncappedDeduction']!;
    final bool isCapped = faCalc['isCapped'] == 1.0;

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
          "Fondo de Ahorro",
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
                  color: _appState._fondoAhorroEnabled
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _appState._fondoAhorroEnabled
                            ? (_isDarkMode
                                ? Colors.green.withAlpha(35)
                                : const Color(0xFFDCFCE7))
                            : accentColor.withAlpha(_isDarkMode ? 35 : 25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _appState._fondoAhorroEnabled
                            ? Icons.savings_rounded
                            : Icons.savings_outlined,
                        color: _appState._fondoAhorroEnabled
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
                            "¿Cuentas con Fondo de Ahorro?",
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _appState._fondoAhorroEnabled
                                ? "Activo: ${_appState._fondoAhorroPct.toStringAsFixed(1)}% de aportación"
                                : "Ahorro quincenal con aportación de la empresa",
                            style: TextStyle(color: subtextColor, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _appState._fondoAhorroEnabled,
                      activeColor:
                          _isDarkMode ? Colors.orange : const Color(0xFFD9531E),
                      onChanged: (val) async {
                        setState(() {
                          _appState._fondoAhorroEnabled = val;
                        });
                        await _appState._saveData(checkSalaryChange: false);
                      },
                    ),
                  ],
                ),
              ),
            ),

            if (_appState._fondoAhorroEnabled) ...[
              // 2. Fondo de Ahorro Anual (Saldo & Entrega)
              _buildSavingsCard(metrics),

              // 3. Cálculo de Descuento Quincenal
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _isDarkMode
                      ? Colors.black.withAlpha(80)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _isDarkMode
                        ? Colors.white12
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calculate_outlined,
                            size: 18, color: accentColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Cálculo de descuento quincenal para Fondo de Ahorro",
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildPreviewRow(
                      "Tu sueldo base quincenal (15 días):",
                      "\$${baseQuincena.toStringAsFixed(2)}",
                      textColor,
                    ),
                    _buildPreviewRow(
                      "Tu aportación quincenal (${_appState._fondoAhorroPct.toStringAsFixed(1)}%):",
                      "-\$${deduction.toStringAsFixed(2)}",
                      _isDarkMode
                          ? Colors.orangeAccent
                          : const Color(0xFFC2410C),
                    ),
                    _buildPreviewRow(
                      "Aportación que te da la empresa (${(_appState._fondoAhorroMatchRatio * 100).round()}%):",
                      "+\$${employerMatch.toStringAsFixed(2)}",
                      _isDarkMode
                          ? Colors.greenAccent
                          : const Color(0xFF16A34A),
                    ),
                    Divider(color: borderColor, height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "Total depositado a tu fondo cada quincena:",
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "\$${totalSavings.toStringAsFixed(2)}",
                          style: TextStyle(
                            color: _isDarkMode
                                ? Colors.greenAccent
                                : const Color(0xFF16A34A),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 1.3 UMA Cap Alert
                    if (isCapped)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber
                              .withAlpha(_isDarkMode ? 35 : 20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.amber.withAlpha(120),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: Colors.amber, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Tope Legal LISR (Art. 27 Fracc. XI) Aplicado:\n"
                                "El cálculo al ${_appState._fondoAhorroPct.toStringAsFixed(1)}% (\$${uncapped.toStringAsFixed(2)}) supera el límite legal exento de 1.3 UMA mensualizada (UMA 2026: \$${_TelevisaAppState.kDailyUma2026} MXN, tope quincenal: \$${_TelevisaAppState.kFondoAhorroQuincenaCap.toStringAsFixed(2)}). Tu aportación se limita a dicho tope para mantener la exención fiscal de ISR.",
                                style: TextStyle(
                                  color: _isDarkMode
                                      ? Colors.amberAccent
                                      : const Color(0xFF92400E),
                                  fontSize: 11,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green
                              .withAlpha(_isDarkMode ? 30 : 15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.green.withAlpha(80),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline,
                                color: _isDarkMode
                                    ? Colors.greenAccent
                                    : const Color(0xFF16A34A),
                                size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Dentro del tope legal exento de ISR (1.3 UMA = \$${_TelevisaAppState.kFondoAhorroQuincenaCap.toStringAsFixed(2)} / quincena en 2026).",
                                style: TextStyle(
                                  color: _isDarkMode
                                      ? Colors.greenAccent
                                      : const Color(0xFF166534),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // 4. Parámetros del Fondo
              Container(
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
                        Icon(Icons.tune_rounded, size: 18, color: accentColor),
                        const SizedBox(width: 8),
                        Text(
                          "Parámetros del Fondo",
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Porcentaje de Ahorro (View-only with '✎ Editar' button)
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Porcentaje de Ahorro (Trabajador):",
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "13.0% es el tope máximo legal exento de ISR (Estándar Televisa)",
                                style: TextStyle(
                                  color: _isDarkMode
                                      ? Colors.orangeAccent
                                      : const Color(0xFFC2410C),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: accentColor.withAlpha(_isDarkMode ? 35 : 20),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: accentColor.withAlpha(80),
                            ),
                          ),
                          child: Text(
                            "${_appState._fondoAhorroPct.toStringAsFixed(1)} %",
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: accentColor,
                            side: BorderSide(color: accentColor),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => _showEditPercentageDialog(context),
                          child: const Text(
                            "✎ Editar",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Employer Match Ratio
                    Text(
                      "Aportación de la Empresa:",
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "💡 Recomendado (Estándar Televisa): 100% (1 a 1)",
                      style: TextStyle(
                        color: _isDarkMode
                            ? Colors.orangeAccent
                            : const Color(0xFFC2410C),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildMatchRatioPill(
                          label: "100% (1 a 1)",
                          ratio: 1.0,
                          controllerText: "100",
                          accentColor: accentColor,
                        ),
                        _buildMatchRatioPill(
                          label: "50% (1 a 0.5)",
                          ratio: 0.5,
                          controllerText: "50",
                          accentColor: accentColor,
                        ),
                        _buildMatchRatioPill(
                          label: "Sin Aporte (1 a 0)",
                          ratio: 0.0,
                          controllerText: "0",
                          accentColor: accentColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Starting Quincena
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Fondo de Ahorro Activo desde:",
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: _isDarkMode
                                ? Colors.black26
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _appState._fondoAhorroStartQuincena
                                  .clamp(1, 24),
                              dropdownColor: cardBg,
                              isDense: true,
                              isExpanded: true,
                              style: TextStyle(
                                  color: textColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                              items: List.generate(24, (i) {
                                final int q = i + 1;
                                return DropdownMenuItem<int>(
                                  value: q,
                                  child: Text(_formatQuincenaItem(
                                      q, currentQuincena, now.year)),
                                );
                              }),
                              onChanged: (newQ) {
                                if (newQ != null) {
                                  setState(() {
                                    _appState._fondoAhorroStartQuincena = newQ;
                                    if (_appState._fondoAhorroCutoffQuincena <
                                        _appState._fondoAhorroStartQuincena) {
                                      _appState._fondoAhorroCutoffQuincena =
                                          _appState._fondoAhorroStartQuincena;
                                    }
                                  });
                                  _appState._saveData(checkSalaryChange: false);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Cutoff Quincena
                    if (!_isCutoffUnlocked)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Quincena de Entrega / Corte:",
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _isDarkMode
                                        ? Colors.white10
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: _isDarkMode
                                          ? Colors.white24
                                          : const Color(0xFFCBD5E1),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.lock_rounded,
                                        size: 13,
                                        color: _isDarkMode
                                            ? Colors.orangeAccent
                                            : const Color(0xFFEA580C),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _appState._fondoAhorroCutoffQuincena == 22
                                            ? "Quincena 22 (Entrega 1-5 Dic)"
                                            : "Quincena ${_appState._fondoAhorroCutoffQuincena.toString().padLeft(2, '0')}",
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _isCutoffUnlocked = true;
                              });
                            },
                            icon: const Icon(Icons.lock_open_rounded, size: 14),
                            label: const Text(
                              "Editar excepción",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: accentColor,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Quincena de Entrega / Corte:",
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                "Excepción desbloqueada",
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: _isDarkMode
                                  ? Colors.black26
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: borderColor),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _appState._fondoAhorroCutoffQuincena
                                    .clamp(1, 24),
                                dropdownColor: cardBg,
                                isDense: true,
                                isExpanded: true,
                                style: TextStyle(
                                    color: textColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                                items: List.generate(24, (i) {
                                  final int q = i + 1;
                                  return DropdownMenuItem<int>(
                                    value: q,
                                    child: Text(_formatQuincenaItem(
                                        q, currentQuincena, now.year)),
                                  );
                                }),
                                onChanged: (newQ) {
                                  if (newQ != null) {
                                    setState(() {
                                      _appState._fondoAhorroCutoffQuincena = newQ;
                                      if (_appState._fondoAhorroCutoffQuincena <
                                          _appState._fondoAhorroStartQuincena) {
                                        _appState._fondoAhorroStartQuincena =
                                            _appState._fondoAhorroCutoffQuincena;
                                      }
                                    });
                                    _appState._saveData(checkSalaryChange: false);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // 5. Historial y Conciliación
              _buildPayStubReconciliationCard(
                metrics: metrics,
                cardBg: cardBg,
                borderColor: borderColor,
                textColor: textColor,
                subtextColor: subtextColor,
                accentColor: accentColor,
              ),
            ],

            // 6. Guía Informativa
            _buildInformationalGuideCard(
              cardBg: cardBg,
              borderColor: borderColor,
              textColor: textColor,
              subtextColor: subtextColor,
              accentColor: accentColor,
            ),
          ],
        ),
      ),
    );
  }
}
