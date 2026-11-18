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
        double applicableRetention = _getRetentionForDate(referenceDate);
        double applicableFomentoRate =
            _getFomentoForDate(referenceDate) / 100.0;
        double applicableCuotaRate =
            _getCuotaForDate(referenceDate) / 100.0;
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
            .where((d) => d.isRestDay && !d.esFalta)
            .fold(0, (totalSum, d) => totalSum + d.dailyPay);
        double fomentoEficiencia = baseEarned * applicableFomentoRate;
        double totalBruto = baseEarned +
            fomentoEficiencia +
            totalExtras +
            weekendBonus;
        if (totalBruto < 0) totalBruto = 0.0;

        double cuotaSindical = baseEarned * applicableCuotaRate;
        double fondoAhorroEmpleado = 0.0;
        if (_fondoAhorroEnabled &&
            qNum >= _fondoAhorroStartQuincena &&
            qNum <= _fondoAhorroCutoffQuincena) {
          final faRes = calculateFondoAhorro(baseEarned: baseEarned);
          fondoAhorroEmpleado = faRes['deduction']!;
        }

        double isrEstimate =
            totalBruto > 0 ? totalBruto * (applicableRetention / 100) : 0.0;
        double netDeposit =
            totalBruto - (isrEstimate + cuotaSindical) - fondoAhorroEmpleado;
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
