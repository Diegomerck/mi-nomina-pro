part of '../main.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _QuincenaTabExt on _TelevisaAppState {
  Widget _buildQuincenaTab() {
    DateTime now = DateTime.now();
    DateTime mondayThisWeek = now.subtract(Duration(days: now.weekday - 1));
    DateTime mondayLastWeek = mondayThisWeek.subtract(const Duration(days: 7));
    DateTime sundayThisWeek = mondayThisWeek.add(const Duration(days: 6));
    DateTime startOfRange =
        DateTime(mondayLastWeek.year, mondayLastWeek.month, mondayLastWeek.day);
    DateTime endOfRange = DateTime(sundayThisWeek.year, sundayThisWeek.month,
        sundayThisWeek.day, 23, 59, 59);
    List<WorkDay> filteredHistory = _weeklyHistory.where((day) {
      return day.entrada
              .isAfter(startOfRange.subtract(const Duration(seconds: 1))) &&
          day.entrada.isBefore(endOfRange.add(const Duration(seconds: 1)));
    }).toList();
    // 1. Group days by Week Number
    final Map<int, List<WorkDay>> weeks = {};
    for (final d in filteredHistory) {
      final int week = _getWeekNumber(d.entrada);
      weeks.putIfAbsent(week, () => []);
      weeks[week]!.add(d);
    }

    // 2. Identify Week Numbers for "Last" and "Current"
    int weekNumLast = _getWeekNumber(mondayLastWeek);
    int weekNumCurrent = _getWeekNumber(mondayThisWeek);

    // 3. Calculate Totals and Hours Separately
    double totalLastWeek = 0.0;
    double hoursLastWeek = 0.0;
    if (weeks.containsKey(weekNumLast)) {
      final map = calculateWeeklyOvertimeBreakdown(weeks[weekNumLast]!);
      totalLastWeek = map.values.fold(0.0, (acc, b) => acc + b.totalPay);
      hoursLastWeek =
          map.values.fold(0.0, (acc, b) => acc + (b.hours2x + b.hours3x));
    }

    double totalThisWeek = 0.0;
    double hoursThisWeek = 0.0;
    if (weeks.containsKey(weekNumCurrent)) {
      final map = calculateWeeklyOvertimeBreakdown(weeks[weekNumCurrent]!);
      totalThisWeek = map.values.fold(0.0, (acc, b) => acc + b.totalPay);
      hoursThisWeek =
          map.values.fold(0.0, (acc, b) => acc + (b.hours2x + b.hours3x));
    }

    // Individual week sharing is now used instead of combined sharing
    // Manual Spanish lists for the list items
    final List<String> daysES = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo'
    ];
    final List<String> monthsES = [
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
    return Column(children: [
      Container(
          padding: const EdgeInsets.all(12),
          width: double.infinity,
          decoration: BoxDecoration(
            color: _isDarkMode
                ? Colors.orange.withAlpha(25)
                : const Color(0xFFFFF7ED),
            border: _isDarkMode
                ? null
                : const Border(
                    bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- LAST WEEK ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text("SEM. PASADA",
                                style: TextStyle(
                                    color: _isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                    fontSize: 16,
                                    letterSpacing: 1.0,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                        IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(Icons.share,
                                color: _isDarkMode
                                    ? Colors.white70
                                    : const Color(0xFF475569),
                                size: 16),
                            onPressed: () => _shareSingleWeekSummary(
                                weeks[weekNumLast] ?? [],
                                weekNumLast,
                                "SEMANA PASADA")),
                      ],
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "\$${totalLastWeek.toStringAsFixed(2)} - (${hoursLastWeek.toStringAsFixed(1)} hrs)",
                        style: TextStyle(
                          color: _isDarkMode
                              ? Colors.white
                              : Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // --- THIS WEEK ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text("SEM. ACTUAL",
                                style: TextStyle(
                                    color: _isDarkMode
                                        ? Colors.orange
                                        : const Color(0xFFC2410C),
                                    fontSize: 16,
                                    letterSpacing: 1.0,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                        IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(Icons.share,
                                color: _isDarkMode
                                    ? Colors.orange
                                    : const Color(0xFFC2410C),
                                size: 18),
                            onPressed: () => _shareSingleWeekSummary(
                                weeks[weekNumCurrent] ?? [],
                                weekNumCurrent,
                                "SEMANA ACTUAL")),
                      ],
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "\$${totalThisWeek.toStringAsFixed(2)} - (${hoursThisWeek.toStringAsFixed(1)} hrs)",
                        style: TextStyle(
                          color: _isDarkMode
                              ? Colors.orange
                              : const Color(0xFFC2410C),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        color: _isDarkMode ? Colors.black26 : const Color(0xFFF1F5F9),
        child: Column(children: [
          _buildWeekRow(mondayLastWeek, "SEM PASADA", false),
          const SizedBox(height: 8),
          _buildWeekRow(mondayThisWeek, "SEM ACTUAL", true),
        ]),
      ),
      Expanded(
        child: filteredHistory.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                    child: Text("No hay registros en estas dos semanas",
                        style: TextStyle(
                            color: _isDarkMode
                                ? Colors.white24
                                : const Color(0xFF64748B)))))
            : ListView.builder(
                itemCount: filteredHistory.length,
                itemBuilder: (context, index) {
                  final day = filteredHistory[index];
                  bool isSelected =
                      day.entrada.day == _selectedCalendarDay.day &&
                          day.entrada.month == _selectedCalendarDay.month;

                  final int week = _getWeekNumber(day.entrada);
                  final List<WorkDay> weekDays = filteredHistory
                      .where((d) => _getWeekNumber(d.entrada) == week)
                      .toList();
                  final weeklyOTMap =
                      calculateWeeklyOvertimeBreakdown(weekDays);
                  final breakdown = weeklyOTMap[day] ?? OvertimeBreakdown();
                  final double realExtrasPay = breakdown.totalPay;

                  // Construct Spanish date string
                  String dateStringES =
                      "${daysES[day.entrada.weekday - 1]}, ${day.entrada.day} ${monthsES[day.entrada.month - 1]}";
                  final bool isSharedWithManager = _isUnitShareActive &&
                      _isDateSharedWithManager(day.entrada, shiftId: day.id);

                  if (day.isInProgress) {
                    return Card(
                      color: _isDarkMode
                          ? Colors.orange.withAlpha(35)
                          : const Color(0xFFFFF7ED),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                            color: _isDarkMode
                                ? Colors.orangeAccent.withAlpha(120)
                                : const Color(0xFFF97316),
                            width: 1.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        dateStringES,
                                        style: TextStyle(
                                            color: _isDarkMode
                                                ? Colors.white70
                                                : const Color(0xFF1E293B),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                      if (isSharedWithManager) ...[
                                        const SizedBox(width: 6),
                                        Icon(
                                          Icons.share_rounded,
                                          size: 14,
                                          color: _isDarkMode
                                              ? Colors.cyanAccent
                                              : const Color(0xFF0284C7),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.timelapse,
                                          color: _isDarkMode
                                              ? Colors.orangeAccent
                                              : const Color(0xFFC2410C),
                                          size: 16),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          "TURNO EN PROGRESO (Entrada: ${DateFormat('hh:mm a').format(day.entrada)})",
                                          style: TextStyle(
                                              color: _isDarkMode
                                                  ? Colors.orangeAccent
                                                  : const Color(0xFFC2410C),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit,
                                      color: _isDarkMode
                                          ? Colors.orange
                                          : const Color(0xFFC2410C),
                                      size: 20),
                                  tooltip: "Editar turno",
                                  onPressed: () => _editExistingWorkDay(
                                      _weeklyHistory.indexOf(day)),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline,
                                      color: _isDarkMode
                                          ? Colors.white54
                                          : const Color(0xFF64748B),
                                      size: 24),
                                  tooltip: "Descartar turno en progreso",
                                  onPressed: () => _showDeleteDialog(
                                      _weeklyHistory.indexOf(day)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (day.esFalta) {
                    return Card(
                      color: _isDarkMode
                          ? Colors.red.withAlpha(40)
                          : const Color(0xFFFEF2F2),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: _isDarkMode
                              ? Colors.transparent
                              : const Color(0xFFFCA5A5),
                          width: _isDarkMode ? 0 : 1.5,
                        ),
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
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(dateStringES,
                                              style: TextStyle(
                                                  color: _isDarkMode
                                                      ? Colors.redAccent
                                                      : const Color(0xFF991B1B),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18)),
                                          if (isSharedWithManager) ...[
                                            const SizedBox(width: 6),
                                            Icon(
                                              Icons.share_rounded,
                                              size: 14,
                                              color: _isDarkMode
                                                  ? Colors.cyanAccent
                                                  : const Color(0xFF0284C7),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text("FALTA / NO LABORADO",
                                          style: TextStyle(
                                              color: _isDarkMode
                                                  ? Colors.white
                                                  : const Color(0xFF1E293B),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14)),
                                    ]),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit,
                                          color: _isDarkMode
                                              ? Colors.orange
                                              : const Color(0xFFC2410C),
                                          size: 20),
                                      tooltip: "Editar registro",
                                      onPressed: () => _editExistingWorkDay(
                                          _weeklyHistory.indexOf(day)),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline,
                                          color: _isDarkMode
                                              ? Colors.white54
                                              : const Color(0xFF64748B),
                                          size: 24),
                                      onPressed: () => _showDeleteDialog(
                                          _weeklyHistory.indexOf(day)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Divider(
                                color: _isDarkMode
                                    ? Colors.white24
                                    : const Color(0xFFE2E8F0)),
                            _buildNotesSection(day),
                          ],
                        ),
                      ),
                    );
                  }

                  if (day.esVacaciones) {
                    return Card(
                      color: _isDarkMode
                          ? Colors.lightGreen.withAlpha(30)
                          : const Color(0xFFF0FDF4),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                            color: _isDarkMode
                                ? Colors.lightGreenAccent.withAlpha(100)
                                : const Color(0xFF86EFAC),
                            width: _isDarkMode ? 2 : 1.5),
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
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(dateStringES,
                                            style: TextStyle(
                                                color: _isDarkMode
                                                    ? Colors.lightGreenAccent
                                                    : const Color(0xFF166534),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18)),
                                        if (isSharedWithManager) ...[
                                          const SizedBox(width: 6),
                                          Icon(
                                            Icons.share_rounded,
                                            size: 14,
                                            color: _isDarkMode
                                                ? Colors.cyanAccent
                                                : const Color(0xFF0284C7),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                          color: _isDarkMode
                                              ? Colors.lightGreen.withAlpha(60)
                                              : const Color(0xFFDCFCE7),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: _isDarkMode
                                              ? null
                                              : Border.all(
                                                  color: const Color(0xFF86EFAC))),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.star,
                                              color: _isDarkMode
                                                  ? Colors.lightGreenAccent
                                                  : const Color(0xFF15803D),
                                              size: 14),
                                          const SizedBox(width: 4),
                                          Text("VACACIONES",
                                              style: TextStyle(
                                                  color: _isDarkMode
                                                      ? Colors.lightGreenAccent
                                                      : const Color(0xFF15803D),
                                                  fontSize: 11,
                                                  fontWeight:
                                                      FontWeight.bold)),
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
                                              : const Color(0xFFC2410C),
                                          size: 20),
                                      tooltip: "Editar registro",
                                      onPressed: () => _editExistingWorkDay(
                                          _weeklyHistory.indexOf(day)),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline,
                                          color: _isDarkMode
                                              ? Colors.white54
                                              : const Color(0xFF64748B),
                                          size: 24),
                                      onPressed: () => _showDeleteDialog(
                                          _weeklyHistory.indexOf(day)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _isDarkMode
                                    ? Colors.lightGreen.withAlpha(20)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: _isDarkMode
                                        ? Colors.lightGreenAccent.withAlpha(100)
                                        : const Color(0xFF86EFAC)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      "VACACIONES - PAGO BASE COMPLETO",
                                      style: TextStyle(
                                          color: _isDarkMode
                                              ? Colors.lightGreenAccent
                                              : const Color(0xFF15803D),
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(
                                      "Pago base: \$${day.dailyPay.toStringAsFixed(2)} | Sin descuento ni horas extra",
                                      style: TextStyle(
                                          color: _isDarkMode
                                              ? Colors.white70
                                              : const Color(0xFF334155),
                                          fontSize: 13)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Divider(
                                color: _isDarkMode
                                    ? Colors.white24
                                    : const Color(0xFFE2E8F0)),
                            _buildNotesSection(day),
                          ],
                        ),
                      ),
                    );
                  } else if (day.esFestivo && !day.festivoTrabajado) {
                    return Card(
                      color: _isDarkMode
                          ? Colors.purple.withAlpha(30)
                          : const Color(0xFFFAF5FF),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                            color: _isDarkMode
                                ? Colors.purpleAccent.withAlpha(100)
                                : const Color(0xFFD8B4FE),
                            width: _isDarkMode ? 2 : 1.5),
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
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(dateStringES,
                                            style: TextStyle(
                                                color: _isDarkMode
                                                    ? Colors.purpleAccent
                                                    : const Color(0xFF6B21A8),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18)),
                                        if (isSharedWithManager) ...[
                                          const SizedBox(width: 6),
                                          Icon(
                                            Icons.share_rounded,
                                            size: 14,
                                            color: _isDarkMode
                                                ? Colors.cyanAccent
                                                : const Color(0xFF0284C7),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                          color: _isDarkMode
                                              ? Colors.purple.withAlpha(60)
                                              : const Color(0xFFF3E8FF),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: _isDarkMode
                                              ? null
                                              : Border.all(
                                                  color: const Color(0xFFD8B4FE))),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.star,
                                              color: _isDarkMode
                                                  ? Colors.purpleAccent
                                                  : const Color(0xFF7E22CE),
                                              size: 14),
                                          const SizedBox(width: 4),
                                          Text("DÍA FESTIVO",
                                              style: TextStyle(
                                                  color: _isDarkMode
                                                      ? Colors.purpleAccent
                                                      : const Color(0xFF7E22CE),
                                                  fontSize: 11,
                                                  fontWeight:
                                                      FontWeight.bold)),
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
                                              : const Color(0xFFC2410C),
                                          size: 20),
                                      tooltip: "Editar registro",
                                      onPressed: () => _editExistingWorkDay(
                                          _weeklyHistory.indexOf(day)),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline,
                                          color: _isDarkMode
                                              ? Colors.white54
                                              : const Color(0xFF64748B),
                                          size: 24),
                                      onPressed: () => _showDeleteDialog(
                                          _weeklyHistory.indexOf(day)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _isDarkMode
                                    ? Colors.purple.withAlpha(20)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: _isDarkMode
                                        ? Colors.purpleAccent.withAlpha(100)
                                        : const Color(0xFFD8B4FE)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      "DÍA FESTIVO - PAGO BASE COMPLETO",
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
                                              : const Color(0xFF334155),
                                          fontSize: 13)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Divider(
                                color: _isDarkMode
                                    ? Colors.white24
                                    : const Color(0xFFE2E8F0)),
                            _buildNotesSection(day),
                          ],
                        ),
                      ),
                    );
                  }

                  bool startedOnWeekend = day.isRestDay;
                  double normalHrs = day.totalHours > day.baseHours
                      ? day.baseHours
                      : day.totalHours;

                  // Determine colors based on day type
                  Color cardColor;
                  Color headerColor;
                  Color borderColor;
                  if (_isDarkMode) {
                    if (day.esMantenimiento) {
                      cardColor = isSelected
                          ? Colors.blue.withAlpha(50)
                          : Colors.blue.withAlpha(20);
                      headerColor = Colors.blueAccent;
                      borderColor = Colors.blueAccent;
                    } else if (day.esFestivo && day.festivoTrabajado) {
                      cardColor = isSelected
                          ? Colors.purple.withAlpha(50)
                          : Colors.purple.withAlpha(20);
                      headerColor = Colors.purpleAccent;
                      borderColor = Colors.purpleAccent;
                    } else if (startedOnWeekend) {
                      cardColor = isSelected
                          ? Colors.orange.withAlpha(50)
                          : Colors.white.withAlpha(20);
                      headerColor = Colors.yellowAccent;
                      borderColor = Colors.orange;
                    } else {
                      cardColor = isSelected
                          ? Colors.orange.withAlpha(50)
                          : Colors.white.withAlpha(20);
                      headerColor = Colors.orange;
                      borderColor = Colors.orange;
                    }
                  } else {
                    // Light Mode
                    if (day.esMantenimiento) {
                      cardColor = isSelected
                          ? const Color(0xFFEFF6FF)
                          : Colors.white;
                      headerColor = const Color(0xFF1D4ED8);
                      borderColor = isSelected
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF93C5FD);
                    } else if (day.esFestivo && day.festivoTrabajado) {
                      cardColor = isSelected
                          ? const Color(0xFFFAF5FF)
                          : Colors.white;
                      headerColor = const Color(0xFF6B21A8);
                      borderColor = isSelected
                          ? const Color(0xFF9333EA)
                          : const Color(0xFFD8B4FE);
                    } else {
                      cardColor = isSelected
                          ? const Color(0xFFFFF7ED)
                          : Colors.white;
                      headerColor = Colors.black;
                      borderColor = isSelected
                          ? const Color(0xFFEA580C)
                          : const Color(0xFFCBD5E1);
                    }
                  }

                  return Card(
                      color: cardColor,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                            color: _isDarkMode
                                ? borderColor.withAlpha(100)
                                : borderColor,
                            width: _isDarkMode
                                ? ((day.esMantenimiento || (day.esFestivo && day.festivoTrabajado)) ? 2 : 0)
                                : (isSelected ? 2.0 : 1.5)),
                      ),
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(children: [
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(dateStringES,
                                                style: TextStyle(
                                                    color: headerColor,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18)),
                                            if (isSharedWithManager) ...[
                                              const SizedBox(width: 6),
                                              Icon(
                                                Icons.share_rounded,
                                                size: 14,
                                                color: _isDarkMode
                                                    ? Colors.cyanAccent
                                                    : const Color(0xFF0284C7),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (day.esMantenimiento)
                                          Container(
                                              margin:
                                                  const EdgeInsets.only(top: 6),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                  color: _isDarkMode
                                                      ? Colors.blueAccent.withAlpha(60)
                                                      : const Color(0xFFDBEAFE),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  border: _isDarkMode
                                                      ? null
                                                      : Border.all(
                                                          color: const Color(0xFF93C5FD))),
                                              child: Text(
                                                  "DÍA DE MANTENIMIENTO",
                                                  style: TextStyle(
                                                      color: _isDarkMode
                                                          ? Colors.blueAccent
                                                          : const Color(0xFF1D4ED8),
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold))),
                                        if (day.esFestivo && day.festivoTrabajado)
                                          Container(
                                              margin:
                                                  const EdgeInsets.only(top: 6),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                  color: _isDarkMode
                                                      ? Colors.purpleAccent.withAlpha(60)
                                                      : const Color(0xFFF3E8FF),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  border: _isDarkMode
                                                      ? null
                                                      : Border.all(
                                                          color: const Color(0xFFD8B4FE))),
                                              child: Text(
                                                  "DÍA FESTIVO",
                                                  style: TextStyle(
                                                      color: _isDarkMode
                                                          ? Colors.purpleAccent
                                                          : const Color(0xFF6B21A8),
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold))),
                                        if (day.isOvernight &&
                                            !day.esMantenimiento)
                                          Container(
                                              margin:
                                                  const EdgeInsets.only(top: 6),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                  color: _isDarkMode
                                                      ? Colors.redAccent.withAlpha(60)
                                                      : const Color(0xFFFEE2E2),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  border: _isDarkMode
                                                      ? null
                                                      : Border.all(
                                                          color: const Color(0xFFFCA5A5))),
                                              child: Text(
                                                  "SALIDA DÍA SIGUIENTE",
                                                  style: TextStyle(
                                                      color: _isDarkMode
                                                          ? Colors.redAccent
                                                          : const Color(0xFFB91C1C),
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold)))
                                      ]),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit,
                                            color: _isDarkMode
                                                ? Colors.orange
                                                : const Color(0xFFC2410C),
                                            size: 20),
                                        tooltip: "Editar turno",
                                        onPressed: () => _editExistingWorkDay(
                                            _weeklyHistory.indexOf(day)),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline,
                                            color: _isDarkMode
                                                ? Colors.white54
                                                : const Color(0xFF64748B),
                                            size: 24),
                                        onPressed: () => _showDeleteDialog(
                                            _weeklyHistory.indexOf(day)),
                                      ),
                                    ],
                                  ),
                                ]),
                            Divider(
                                color: _isDarkMode
                                    ? Colors.white24
                                    : const Color(0xFFE2E8F0)),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                          "Entrada Asignada: ${DateFormat('hh:mm a').format(day.entrada)}",
                                          style: TextStyle(
                                              color: _isDarkMode
                                                  ? (day.esMantenimiento
                                                      ? Colors.blueAccent
                                                      : Colors.orangeAccent)
                                                  : (day.esMantenimiento
                                                      ? const Color(0xFF1D4ED8)
                                                      : const Color(0xFFC2410C)),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500)),
                                      Text(
                                          "Salida: ${DateFormat('hh:mm a').format(day.salida)}",
                                          style: TextStyle(
                                              color: _isDarkMode
                                                  ? Colors.redAccent
                                                  : const Color(0xFFB91C1C),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                  if (day.entradaReal != null &&
                                      day.entradaReal != day.entrada)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                          "Registro Real: ${DateFormat('hh:mm a').format(day.entradaReal!)} ${day.entradaReal!.isBefore(day.entrada) ? '(Temprano)' : '(Tarde)'}",
                                          style: TextStyle(
                                              color: _isDarkMode
                                                  ? (day.entradaReal!.isBefore(day.entrada)
                                                      ? Colors.greenAccent
                                                      : Colors.yellowAccent)
                                                  : (day.entradaReal!.isBefore(day.entrada)
                                                      ? const Color(0xFF15803D)
                                                      : const Color(0xFFB45309)),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500)),
                                    ),
                                ],
                              ),
                            ),
                            if (day.esFestivo && day.festivoTrabajado)
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                        isMoney: true)
                                  ])
                            else if (!day.esMantenimiento)
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _statDetail(
                                        "DESGLOSE DE HORAS",
                                        "${normalHrs.toStringAsFixed(1)}h (Base) + ${day.extraHoursCount.toStringAsFixed(2)}h (Extra)",
                                        "${day.totalHours.toStringAsFixed(2)} hrs totales"),
                                    _statDetail(
                                        "DESGLOSE DE PAGO",
                                        _restDays.contains(day.entrada.weekday)
                                            ? "\$${day.sueldoBase.toStringAsFixed(2)} Base\n"
                                                "\$${day.sueldoBase.toStringAsFixed(2)} Día de descanso\n"
                                                "2× ${breakdown.hours2x.toStringAsFixed(2)}h  \$${breakdown.pay2x.toStringAsFixed(2)}\n"
                                                "3× ${breakdown.hours3x.toStringAsFixed(2)}h  \$${breakdown.pay3x.toStringAsFixed(2)}"
                                            : "\$${day.dailyPay.toStringAsFixed(2)} Base\n"
                                                "2× ${breakdown.hours2x.toStringAsFixed(2)}h  \$${breakdown.pay2x.toStringAsFixed(2)}\n"
                                                "3× ${breakdown.hours3x.toStringAsFixed(2)}h  \$${breakdown.pay3x.toStringAsFixed(2)}",
                                        "\$${(day.dailyPay + realExtrasPay).toStringAsFixed(2)}",
                                        isMoney: true)
                                  ])
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
                                          : const Color(0xFF93C5FD)),
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
                                                : const Color(0xFF334155),
                                            fontSize: 13)),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 8),
                            Divider(
                                color: _isDarkMode
                                    ? Colors.white24
                                    : const Color(0xFFE2E8F0)),
                            _buildNotesSection(day),
                          ])));
                }),
        ),
      ],
    );
  }

  Widget _buildYearSegmentedControl({
    required int selectedYear,
    required ValueChanged<int> onYearChanged,
  }) {
    const years = [2026, 2027];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _isDarkMode
            ? Colors.black.withAlpha(120)
            : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isDarkMode
              ? Colors.white.withAlpha(35)
              : const Color(0xFFCBD5E1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: years.map((year) {
          final isSelected = selectedYear == year;
          return GestureDetector(
            onTap: isSelected ? null : () => onYearChanged(year),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? (_isDarkMode ? Colors.orange : const Color(0xFFEA580C))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: (_isDarkMode
                                  ? Colors.orange
                                  : const Color(0xFFEA580C))
                              .withAlpha(80),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                year.toString(),
                style: TextStyle(
                  color: isSelected
                      ? (_isDarkMode ? Colors.black : Colors.white)
                      : (_isDarkMode ? Colors.white70 : const Color(0xFF475569)),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _build2027DisclaimerBanner({EdgeInsetsGeometry? margin}) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _isDarkMode
            ? Colors.amber.withAlpha(20)
            : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isDarkMode
              ? Colors.amber.withAlpha(90)
              : const Color(0xFFFDE68A),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: _isDarkMode ? Colors.amberAccent : const Color(0xFFD97706),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "CALENDARIO 2027 PRELIMINAR",
                  style: TextStyle(
                    color: _isDarkMode
                        ? Colors.amberAccent
                        : const Color(0xFFB45309),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Las fechas de corte y depósito de 2027 son estimaciones preliminares sujetas a confirmación oficial por parte de la Mesa de Control de Incidencias.",
                  style: TextStyle(
                    color: _isDarkMode
                        ? Colors.white70
                        : const Color(0xFF78350F),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  void _scrollToCurrentWeek() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      DateTime now = DateTime.now();
      int year = _selectedAnoYear;
      if (year != now.year) return;
      DateTime jan1 = DateTime(year, 1, 1);
      DateTime firstMonday = jan1.subtract(Duration(days: jan1.weekday - 1));

      int currentWeekIndex = -1;
      for (int i = 0; i < 53; i++) {
        DateTime weekStart = firstMonday.add(Duration(days: i * 7));
        DateTime weekEnd = weekStart.add(const Duration(days: 6));

        if (now.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
            now.isBefore(weekEnd.add(const Duration(seconds: 1)))) {
          currentWeekIndex = i;
          break;
        }
      }

      if (currentWeekIndex != -1 && currentWeekIndex < _weekKeys.length) {
        final key = _weekKeys[currentWeekIndex];
        if (key.currentContext != null) {
          Scrollable.ensureVisible(
            key.currentContext!,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            alignment: 0.15,
          );
        }
      }
    });
  }


}
