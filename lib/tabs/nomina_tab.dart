part of '../main.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _NominaTabExt on _TelevisaAppState {
  Widget _buildNominaTab() {
    // Get current date info for determining quincena status
    DateTime now = DateTime.now();

    // 1. Calculate globalNextToPayPid across all entries in _payCalendar (chronologically)
    String? globalNextToPayPid;
    DateTime? earliestUnpaidPayoutDate;

    for (final entry in _payCalendar.entries) {
      final checkPid = entry.key;
      final checkCfg = entry.value;

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

      if (checkPayoutDate == null) continue;

      // Skip if paid out (payout date is today or in the past)
      bool checkIsPaidOut = checkPayoutDate.isBefore(now) ||
          (checkPayoutDate.year == now.year &&
              checkPayoutDate.month == now.month &&
              checkPayoutDate.day == now.day);
      if (checkIsPaidOut) continue;

      // Skip if currently affected (shift period in progress)
      final checkRange = _getQuincenaDateRange(checkPid, checkCfg);
      bool checkIsCurrentlyAffected = checkRange != null &&
          now.isAfter(checkRange.$1.subtract(const Duration(seconds: 1))) &&
          now.isBefore(checkRange.$2.add(const Duration(seconds: 1)));
      if (checkIsCurrentlyAffected) continue;

      // Check if chronologically earliest unpaid non-affected payout
      if (earliestUnpaidPayoutDate == null ||
          checkPayoutDate.isBefore(earliestUnpaidPayoutDate)) {
        earliestUnpaidPayoutDate = checkPayoutDate;
        globalNextToPayPid = checkPid;
      }
    }

    final List<String> currentYearPids = _payCalendar.keys
        .where((k) => k.startsWith(_selectedNominaYear.toString()))
        .toList();

    final bool show2027Disclaimer = (_selectedNominaYear == 2027);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          width: double.infinity,
          decoration: BoxDecoration(
            color: _isDarkMode
                ? Colors.orange.withAlpha(25)
                : const Color(0xFFFFF7ED),
            border: Border(
              bottom: BorderSide(
                color: _isDarkMode
                    ? Colors.orange.withAlpha(60)
                    : const Color(0xFFE2E8F0),
                width: 1.5,
              ),
            ),
          ),
          child: Center(
            child: _buildYearSegmentedControl(
              selectedYear: _selectedNominaYear,
              onYearChanged: (newYear) {
                _rebuild(() => _selectedNominaYear = newYear);
                if (_selectedNominaYear == DateTime.now().year) {
                  _scrollToActiveNomina();
                } else if (_nominaScrollController.hasClients) {
                  _nominaScrollController.animateTo(
                    0.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                  );
                }
              },
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _nominaScrollController,
            padding: const EdgeInsets.all(16),
            itemCount: currentYearPids.length + (show2027Disclaimer ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == currentYearPids.length) {
                return _build2027DisclaimerBanner(
                  margin: const EdgeInsets.only(top: 8, bottom: 20),
                );
              }

              String pid = currentYearPids[index];
              final int qNum = int.tryParse(pid.substring(4)) ?? 0;
              var cfg = _payCalendar[pid]!;

              // Calculate date range for this quincena based on its weeks and quincena year
              final dateRange = _getQuincenaDateRange(pid, cfg);
              final DateTime? quincenaStartDate = dateRange?.$1;
              final DateTime? quincenaEndDate = dateRange?.$2;

              List<WorkDay> matched = _weeklyHistory.where((d) {
                if (!cfg['weeks'].contains(_getWeekNumber(d.entrada))) {
                  return false;
                }
                if (quincenaStartDate != null && quincenaEndDate != null) {
                  return d.entrada.isAfter(quincenaStartDate
                          .subtract(const Duration(seconds: 1))) &&
                      d.entrada.isBefore(quincenaEndDate
                          .add(const Duration(seconds: 1)));
                }
                return true;
              }).toList();

              // Parse payout date (format: "dd/MM/yy")
              DateTime? payoutDate;
              try {
                String payoutStr = cfg['payout'] as String;
                List<String> parts = payoutStr.split('/');
                if (parts.length == 3) {
                  int day = int.parse(parts[0]);
                  int month = int.parse(parts[1]);
                  int year = 2000 + int.parse(parts[2]); // Convert "26" to 2026, "27" to 2027
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

              // Currently affected if today falls within the quincena's date range
              bool isCurrentlyAffected = quincenaStartDate != null &&
                  quincenaEndDate != null &&
                  now.isAfter(
                      quincenaStartDate.subtract(const Duration(seconds: 1))) &&
                  now.isBefore(quincenaEndDate.add(const Duration(seconds: 1)));

              // Set isNextToPay based on the global next-to-pay payout
              bool isNextToPay = (pid == globalNextToPayPid);

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
        final contractConfig = _getContractForDate(referenceDate);
        final double applicableFomentoRate =
            (contractConfig['fomento'] as num).toDouble() / 100.0;
        final double applicableCuotaRate =
            (contractConfig['cuota'] as num).toDouble() / 100.0;
        final String cuotaFrequency =
            (contractConfig['frequency'] ?? 'both').toString();
        double baseQuincena = applicableSalary * 15;

        int faltasCount = matched.where((d) => d.esFalta).length;

        // Proportional factor per absence decoupled from calendar weeks length
        // Standard 5-day workweek with 2 rest days yields restRatio = 2/5 = 0.4, factorPerFalta = 1.4
        final double restRatio = _restDays.isNotEmpty
            ? (_restDays.length / (7.0 - _restDays.length))
            : 0.4;
        final double factorPerFalta = 1.0 + restRatio;
        final double descuentoFaltas =
            math.min(baseQuincena, faltasCount * factorPerFalta * applicableSalary);

        double baseEarned = math.max(0.0, baseQuincena - descuentoFaltas);

        double totalExtras = 0.0;
        double totalHours2x = 0.0;
        double totalHours3x = 0.0;
        double totalPay2x = 0.0;
        double totalPay3x = 0.0;

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
            totalPay2x += b.pay2x;
            totalPay3x += b.pay3x;
          }
        }

        final bool isFirstQuincena = (qNum % 2 != 0);

        double weekendBonus = matched
            .where((d) => d.isRestDay && !d.esFalta)
            .fold(0, (totalSum, d) => totalSum + d.dailyPay);
        double fomentoEficiencia = baseEarned * applicableFomentoRate;
        double totalBruto = baseEarned +
            fomentoEficiencia +
            totalExtras +
            weekendBonus;
        if (totalBruto < 0) totalBruto = 0.0;

        double cuotaSindical = PayrollEngine.calculateCuotaSindical(
          baseEarned: baseEarned,
          applicableCuotaRate: applicableCuotaRate,
          qNum: qNum,
          faltasCount: faltasCount,
          applicableSalary: applicableSalary,
          frequency: cuotaFrequency,
        );
        double fondoAhorroEmpleado = 0.0;
        if (_fondoAhorroEnabled &&
            qNum >= _fondoAhorroStartQuincena &&
            qNum <= _fondoAhorroCutoffQuincena) {
          final faRes = calculateFondoAhorro(baseEarned: baseEarned);
          fondoAhorroEmpleado = faRes['deduction']!;
        }

        final List<dynamic> paidWeeks = (cfg['weeks'] as List? ?? []);
        final int weeksPaid = paidWeeks.isNotEmpty ? paidWeeks.length : 2;
        final double doublePayExemption = math.min(
            0.50 * totalPay2x, 5.0 * _TelevisaAppState.kDailyUma2026 * weeksPaid);
        final double taxableDoubles =
            math.max(0.0, totalPay2x - doublePayExemption);
        final double baseGravable =
            baseEarned + fomentoEficiencia + totalPay3x + taxableDoubles;
        final double isrRetenido =
            _TelevisaAppState.calculateSatIsr2026Quincenal(baseGravable);
        double netDeposit =
            totalBruto - (isrRetenido + cuotaSindical) - fondoAhorroEmpleado;
        if (netDeposit < 0) netDeposit = 0.0;

        final double valesAmountForQna =
            _valesPayStubOverrides.containsKey(pid)
                ? _valesPayStubOverrides[pid]!
                : _valesFomentoCulturalAmount;

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
                  _confirmRow("I.S.R. Retenido (Tabla SAT 2026):",
                      "-\$${isrRetenido.toStringAsFixed(2)}"),
                  if (cuotaSindical > 0)
                    _confirmRow("Cuota Sindical:",
                        "-\$${cuotaSindical.toStringAsFixed(2)}"),
                  if (_fondoAhorroEnabled && fondoAhorroEmpleado > 0)
                    _confirmRow("Fondo de Ahorro:",
                        "-\$${fondoAhorroEmpleado.toStringAsFixed(2)}"),
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
                  if (!isFirstQuincena &&
                      _valesFomentoCulturalEnabled &&
                      qNum >= _valesStartQuincena &&
                      valesAmountForQna > 0) ...[
                    const SizedBox(height: 14),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ValesChedrauiScreen(
                              appState: this,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: _isDarkMode
                              ? Colors.blue.withAlpha(25)
                              : const Color(0xFFF0F7FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isDarkMode
                                ? Colors.blue.withAlpha(70)
                                : const Color(0xFFBAE6FD),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.confirmation_number_outlined,
                                  size: 18,
                                  color: _isDarkMode
                                      ? Colors.lightBlueAccent
                                      : const Color(0xFF0284C7),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      Text(
                                        "Vales de Fomento Cultural",
                                        style: TextStyle(
                                          color: _isDarkMode
                                              ? Colors.white
                                              : const Color(0xFF0F172A),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _isDarkMode
                                              ? Colors.blue.withAlpha(45)
                                              : const Color(0xFFDBEAFE),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                            color: _isDarkMode
                                                ? Colors.blue.withAlpha(100)
                                                : const Color(0xFF93C5FD),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          "MONEDERO CHEDRAUI",
                                          style: TextStyle(
                                            color: _isDarkMode
                                                ? Colors.lightBlueAccent
                                                : const Color(0xFF1D4ED8),
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "\$${valesAmountForQna.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    color: _isDarkMode
                                        ? Colors.lightBlueAccent
                                        : const Color(0xFF0369A1),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Depósito en Monedero Chedraui (toca para ver saldo y conciliar)",
                              style: TextStyle(
                                color: _isDarkMode
                                    ? Colors.white60
                                    : const Color(0xFF64748B),
                                fontSize: 11.5,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ]),
              )
            ],
          ),
        );
      },
    ),
  ),
],
);
  }
}
