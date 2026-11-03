part of '../main.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _AnoTabExt on _TelevisaAppState {
  Widget _buildAnoTab() {
    int year = _selectedAnoYear;
    DateTime jan1 = DateTime(year, 1, 1);
    // Find the Monday of the week containing Jan 1st
    DateTime firstMonday = jan1.subtract(Duration(days: jan1.weekday - 1));

    // Spanish month abbreviations
    const List<String> monthNames = [
      'ENE',
      'FEB',
      'MAR',
      'ABR',
      'MAY',
      'JUN',
      'JUL',
      'AGO',
      'SEP',
      'OCT',
      'NOV',
      'DIC'
    ];

    // Trigger auto-scroll on first display of this tab
    if (!_hasAutoScrolledAnoTab && _selectedAnoYear == DateTime.now().year) {
      _hasAutoScrolledAnoTab = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentWeek();
      });
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          width: double.infinity,
          decoration: BoxDecoration(
            color: _isDarkMode
                ? Colors.orange.withAlpha(30)
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Registro Anual:",
                style: TextStyle(
                  color: _isDarkMode
                      ? Colors.orange
                      : const Color(0xFFC2410C),
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 12),
              _buildYearSegmentedControl(
                selectedYear: _selectedAnoYear,
                onYearChanged: (newYear) {
                  _rebuild(() => _selectedAnoYear = newYear);
                  if (_selectedAnoYear == DateTime.now().year) {
                    _scrollToCurrentWeek();
                  } else if (_anoScrollController.hasClients) {
                    _anoScrollController.animateTo(
                      0.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                    );
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _anoScrollController,
            child: Column(
              children: [
        // Month header row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              const SizedBox(width: 60), // Space for week label
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('L',
                        style: TextStyle(
                            color: _isDarkMode
                                ? Colors.orange
                                : const Color(0xFFC2410C),
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    Text('M',
                        style: TextStyle(
                            color: _isDarkMode
                                ? Colors.orange
                                : const Color(0xFFC2410C),
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    Text('M',
                        style: TextStyle(
                            color: _isDarkMode
                                ? Colors.orange
                                : const Color(0xFFC2410C),
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    Text('J',
                        style: TextStyle(
                            color: _isDarkMode
                                ? Colors.orange
                                : const Color(0xFFC2410C),
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    Text('V',
                        style: TextStyle(
                            color: _isDarkMode
                                ? Colors.orange
                                : const Color(0xFFC2410C),
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    Text('S',
                        style: TextStyle(
                            color: _isDarkMode
                                ? Colors.orange
                                : const Color(0xFFC2410C),
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    Text('D',
                        style: TextStyle(
                            color: _isDarkMode
                                ? Colors.orange
                                : const Color(0xFFC2410C),
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(
            color: _isDarkMode ? Colors.white24 : const Color(0xFFCBD5E1),
            height: 1),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: 53, // Covers all potential weeks in a year
            itemBuilder: (context, index) {
              DateTime weekStart = firstMonday.add(Duration(days: index * 7));
              DateTime weekEnd = weekStart.add(const Duration(days: 6));

              // Highlight current week logic
              DateTime now = DateTime.now();
              bool isCurrent = now.year == year &&
                  now.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
                  now.isBefore(weekEnd.add(const Duration(seconds: 1)));

              // Check if this week contains the first day of a month
              String? monthLabel;
              for (int day = 0; day < 7; day++) {
                DateTime checkDate = weekStart.add(Duration(days: day));
                if (checkDate.day == 1) {
                  monthLabel = monthNames[checkDate.month - 1];
                  break;
                }
              }

              return Padding(
                key: _weekKeys[index],
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Container(
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? (_isDarkMode
                            ? Colors.orange.withAlpha(30)
                            : const Color(0xFFFFF7ED))
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    border: isCurrent
                        ? Border.all(
                            color: _isDarkMode
                                ? Colors.orangeAccent.withAlpha(150)
                                : const Color(0xFFEA580C),
                            width: 2,
                          )
                        : null,
                  ),
                  padding: isCurrent ? const EdgeInsets.all(8) : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isCurrent)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8, left: 70),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isDarkMode
                                ? Colors.orangeAccent
                                : const Color(0xFFEA580C),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.today,
                                    color: _isDarkMode
                                        ? Colors.black
                                        : Colors.white,
                                    size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  "SEMANA ACTUAL",
                                  style: TextStyle(
                                    color: _isDarkMode
                                        ? Colors.black
                                        : Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ]),
                        ),
                      if (monthLabel != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6, left: 70),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _isDarkMode
                                  ? Colors.orange.withAlpha(80)
                                  : const Color(0xFFC2410C),
                              borderRadius: BorderRadius.circular(6),
                              border: _isDarkMode
                                  ? Border.all(
                                      color: Colors.orangeAccent.withAlpha(100))
                                  : null,
                            ),
                            child: Text(
                              monthLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16, // INCREASED from 11 to 16
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      _buildWeekRow(weekStart, "SEM ${index + 1}", isCurrent),
                      // Show overtime summary for this week if data exists
                      _buildWeekOvertimeSummary(weekStart),
                    ],
                  ),
                ),
              );
            },
          ),
          if (_selectedAnoYear == 2027)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              child: _build2027DisclaimerBanner(),
            ),
        ],
      ),
    ),
  ),
],
);
  }

  Widget _buildWeekOvertimeSummary(DateTime weekStart) {
    // Get all days in this week (Monday to Sunday)
    DateTime weekEnd = weekStart.add(const Duration(days: 6));
    List<WorkDay> weekDays = _weeklyHistory.where((d) {
      return d.entrada
              .isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
          d.entrada.isBefore(weekEnd.add(const Duration(seconds: 1))) &&
          !d.esFalta;
    }).toList();

    if (weekDays.isEmpty) return const SizedBox.shrink();

    // Calculate overtime for this week
    final breakdownMap = calculateWeeklyOvertimeBreakdown(weekDays);
    double totalPay = 0.0;
    double totalHours = 0.0;
    for (var b in breakdownMap.values) {
      totalPay += b.totalPay;
      totalHours += b.hours2x + b.hours3x;
    }

    if (totalHours <= 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(left: 70, right: 10, bottom: 8, top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _isDarkMode
            ? Colors.orange.withAlpha(30)
            : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(8),
        border: _isDarkMode
            ? Border.all(color: Colors.orange.withAlpha(60))
            : Border.all(color: const Color(0xFFFED7AA), width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Extras: ${totalHours.toStringAsFixed(1)} hrs",
            style: TextStyle(
              color: _isDarkMode
                  ? Colors.orangeAccent
                  : const Color(0xFFC2410C),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "\$${totalPay.toStringAsFixed(2)}",
            style: TextStyle(
              color: _isDarkMode
                  ? Colors.greenAccent
                  : const Color(0xFF15803D),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekRow(DateTime startDay, String label, bool isCurrent) {
    // Check if today is in this week
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    return Row(
      children: [
        SizedBox(
            width: 60,
            child: Column(
              children: [
                Text(label,
                    style: TextStyle(
                        color: isCurrent
                            ? (_isDarkMode
                                ? Colors.orangeAccent
                                : Colors.black)
                            : (_isDarkMode
                                ? Colors.white54
                                : Colors.black),
                        fontSize: isCurrent ? 14 : 12,
                        fontWeight: FontWeight.bold)),
                if (isCurrent)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _isDarkMode
                          ? Colors.orangeAccent
                          : const Color(0xFFC2410C),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            )),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              DateTime dayDate = startDay.add(Duration(days: index));
              DateTime dayDateNormalized =
                  DateTime(dayDate.year, dayDate.month, dayDate.day);
              bool isToday = dayDateNormalized == today;
              bool isSelected = dayDate.day == _selectedCalendarDay.day &&
                  dayDate.month == _selectedCalendarDay.month &&
                  dayDate.year == _selectedCalendarDay.year;
              bool hasData = _weeklyHistory.any((d) =>
                  d.entrada.day == dayDate.day &&
                  d.entrada.month == dayDate.month &&
                  d.entrada.year == dayDate.year);
              bool isMantenimiento = _weeklyHistory.any((d) =>
                  d.entrada.day == dayDate.day &&
                  d.entrada.month == dayDate.month &&
                  d.entrada.year == dayDate.year &&
                  d.esMantenimiento);
              bool isVacaciones = _weeklyHistory.any((d) =>
                  d.entrada.day == dayDate.day &&
                  d.entrada.month == dayDate.month &&
                  d.entrada.year == dayDate.year &&
                  d.esVacaciones);
              bool isFestivo = _weeklyHistory.any((d) =>
                  d.entrada.day == dayDate.day &&
                  d.entrada.month == dayDate.month &&
                  d.entrada.year == dayDate.year &&
                  d.esFestivo);
              bool isFalta = _weeklyHistory.any((d) =>
                  d.entrada.day == dayDate.day &&
                  d.entrada.month == dayDate.month &&
                  d.entrada.year == dayDate.year &&
                  d.esFalta);
              bool hasNotes = _weeklyHistory.any((d) =>
                  d.entrada.day == dayDate.day &&
                  d.entrada.month == dayDate.month &&
                  d.entrada.year == dayDate.year &&
                  d.notas.isNotEmpty);

              // Manual Spanish Map
              const dialNames = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
              String dayLetter = dialNames[dayDate.weekday - 1];
              return GestureDetector(
                onTap: () {
                  _rebuild(() => _selectedCalendarDay = dayDate);
                  _showManualDayDialog(dayDate);
                },
                child: Container(
                  width: isToday ? 48 : 42, // Slightly larger for today
                  height: isToday ? 48 : 42,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isToday
                        ? (_isDarkMode
                            ? Colors.orangeAccent.withAlpha(80) // Strong highlight for today
                            : const Color(0xFFFFEDD5))
                        : isSelected
                            ? (_isDarkMode
                                ? (isMantenimiento
                                    ? Colors.blue.withAlpha(50)
                                    : isFestivo
                                        ? Colors.purple.withAlpha(50)
                                        : isVacaciones
                                            ? Colors.lightGreen.withAlpha(50)
                                            : isFalta
                                                ? Colors.red.shade700
                                                : Colors.green.withAlpha(50)) // Asistencia GREEN
                                : (isMantenimiento
                                    ? const Color(0xFFDBEAFE)
                                    : isFestivo
                                        ? const Color(0xFFF3E8FF)
                                        : isVacaciones
                                            ? const Color(0xFFDCFCE7)
                                            : isFalta
                                                ? const Color(0xFFFEE2E2)
                                                : (hasData
                                                    ? const Color(0xFFDCFCE7)
                                                    : Colors.white)))
                            : (hasData
                                ? (_isDarkMode
                                    ? (isMantenimiento
                                        ? Colors.blue.withAlpha(40)
                                        : isFestivo
                                            ? Colors.purple.withAlpha(40)
                                            : isVacaciones
                                                ? Colors.lightGreen.withAlpha(40)
                                                : isFalta
                                                    ? Colors.red.shade700
                                                    : Colors.green.withAlpha(40)) // Asistencia GREEN
                                    : (isMantenimiento
                                        ? const Color(0xFFEFF6FF)
                                        : isFestivo
                                            ? const Color(0xFFFAF5FF)
                                            : isVacaciones
                                                ? const Color(0xFFDCFCE7)
                                                : isFalta
                                                    ? const Color(0xFFFEF2F2)
                                                    : const Color(0xFFDCFCE7)))
                                : (_isDarkMode
                                    ? (isCurrent
                                        ? Colors.transparent
                                        : Colors.white.withAlpha(5))
                                    : Colors.white)),
                    borderRadius: BorderRadius.circular(
                        isToday ? 12 : 8), // More rounded for today
                    border: Border.all(
                        color: isToday
                            ? (_isDarkMode
                                ? Colors.orangeAccent // Bright border for today
                                : const Color(0xFFEA580C))
                            : isSelected
                                ? (_isDarkMode
                                    ? (isMantenimiento
                                        ? Colors.blueAccent
                                        : isFestivo
                                            ? Colors.purpleAccent
                                            : isVacaciones
                                                ? Colors.lightGreenAccent
                                                : isFalta
                                                    ? Colors.redAccent
                                                    : Colors.greenAccent)
                                    : const Color(0xFFEA580C))
                                : (hasData
                                    ? (_isDarkMode
                                        ? (isMantenimiento
                                            ? Colors.blueAccent
                                            : isFestivo
                                                ? Colors.purpleAccent
                                                : isVacaciones
                                                    ? Colors.lightGreenAccent
                                                    : isFalta
                                                        ? Colors.redAccent
                                                        : Colors.greenAccent)
                                        : (isMantenimiento
                                            ? const Color(0xFF93C5FD)
                                            : isFestivo
                                                ? const Color(0xFFD8B4FE)
                                                : isVacaciones
                                                    ? const Color(0xFF16A34A)
                                                    : isFalta
                                                        ? const Color(0xFFFCA5A5)
                                                        : const Color(0xFF16A34A)))
                                    : (_isDarkMode
                                        ? Colors.white10
                                        : const Color(0xFFCBD5E1))),
                        width: isToday
                            ? 3
                            : (isSelected ? 2.0 : (hasData ? 2.0 : 1.2))), // Thicker border for today
                    boxShadow: isToday
                        ? [
                            BoxShadow(
                              color: _isDarkMode
                                  ? Colors.orangeAccent.withAlpha(100)
                                  : const Color(0xFFEA580C).withAlpha(60),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(dayLetter,
                                  style: TextStyle(
                                      color: isToday
                                          ? (_isDarkMode
                                              ? Colors.white // White for today
                                              : const Color(0xFF9A3412))
                                          : (isFalta
                                              ? (_isDarkMode
                                                  ? Colors.white
                                                  : const Color(0xFF991B1B))
                                              : (_isDarkMode
                                                  ? Colors.orange
                                                  : const Color(0xFFC2410C))),
                                      fontSize: isToday ? 12 : 10,
                                      height: 1.0,
                                      fontWeight: FontWeight.bold)),
                              if (hasNotes) ...[
                                const SizedBox(width: 2),
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: _isDarkMode
                                        ? Colors.orangeAccent
                                        : const Color(0xFFC2410C),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                              if (isVacaciones || isFestivo) ...[
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.star,
                                  color: _isDarkMode
                                      ? (isVacaciones
                                          ? Colors.lightGreenAccent
                                          : Colors.purpleAccent)
                                      : (isVacaciones
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFF9333EA)),
                                  size: 10,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(dayDate.day.toString(),
                              style: TextStyle(
                                  color: isToday
                                      ? (_isDarkMode
                                          ? Colors.black // Black number on orange for contrast
                                          : const Color(0xFF7C2D12))
                                      : (hasData
                                          ? (_isDarkMode
                                              ? (isMantenimiento
                                                  ? Colors.blueAccent
                                                  : isFestivo
                                                      ? Colors.purpleAccent
                                                      : isVacaciones
                                                          ? Colors.lightGreenAccent
                                                          : isFalta
                                                              ? Colors.white
                                                              : Colors.greenAccent)
                                              : (isMantenimiento
                                                  ? const Color(0xFF1D4ED8)
                                                  : isFestivo
                                                      ? const Color(0xFF6B21A8)
                                                      : isVacaciones
                                                          ? const Color(0xFF14532D)
                                                          : isFalta
                                                              ? const Color(0xFF991B1B)
                                                              : const Color(0xFF14532D)))
                                          : (_isDarkMode
                                              ? (isCurrent
                                                  ? Colors.white
                                                  : Colors.white70)
                                              : Colors.black)),
                                  fontSize: isToday ? 16 : 14,
                                  height: 1.0,
                                  fontWeight: isToday
                                      ? FontWeight.w900
                                      : FontWeight.bold)), // Extra bold for today
                        ]),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  (DateTime, DateTime)? _getQuincenaDateRange(
      String pid, Map<String, dynamic> cfg) {
    List<int> quincenaWeeks = List<int>.from(cfg['weeks'] ?? []);
    if (quincenaWeeks.isEmpty) return null;
    quincenaWeeks.sort();

    int quincenaYear = int.tryParse(pid.substring(0, 4)) ?? 2026;
    int quincenaNum = int.tryParse(pid.substring(4)) ?? 1;

    // Quincenas 1 and 2 in a payout calendar (payout in January) cover the closing weeks of the previous year
    int yearForFirstWeek = (quincenaNum <= 2 && quincenaWeeks.first >= 48)
        ? quincenaYear - 1
        : quincenaYear;
    int yearForLastWeek = (quincenaNum <= 2 && quincenaWeeks.last >= 48)
        ? quincenaYear - 1
        : quincenaYear;

    DateTime jan4First = DateTime(yearForFirstWeek, 1, 4);
    DateTime firstMonday =
        jan4First.subtract(Duration(days: jan4First.weekday - 1));
    DateTime startDate =
        firstMonday.add(Duration(days: (quincenaWeeks.first - 1) * 7));

    DateTime jan4Last = DateTime(yearForLastWeek, 1, 4);
    DateTime lastMonday =
        jan4Last.subtract(Duration(days: jan4Last.weekday - 1));
    DateTime endDate = lastMonday
        .add(Duration(days: (quincenaWeeks.last - 1) * 7))
        .add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

    return (startDate, endDate);
  }

  void _scrollToActiveNomina() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted || !_nominaScrollController.hasClients) return;

      DateTime now = DateTime.now();
      int enProgresoIndex = -1;

      final pids = _payCalendar.keys
          .where((k) => k.startsWith(_selectedNominaYear.toString()))
          .toList();

      for (int i = 0; i < pids.length; i++) {
        String pid = pids[i];
        var cfg = _payCalendar[pid]!;
        final range = _getQuincenaDateRange(pid, cfg);
        if (range != null) {
          bool isCurrentlyAffected = now.isAfter(
                  range.$1.subtract(const Duration(seconds: 1))) &&
              now.isBefore(range.$2.add(const Duration(seconds: 1)));
          if (isCurrentlyAffected) {
            enProgresoIndex = i;
            break;
          }
        }
      }

      if (enProgresoIndex != -1) {
        double estimatedItemHeight = 135.0;
        double viewport = _nominaScrollController.position.viewportDimension;

        // Formula from Screenshot 1 shifted up by 2 cards (-250px) to match Screenshot 2
        double targetOffset =
            (((enProgresoIndex + 1) * estimatedItemHeight) - viewport + 24.0) -
                250.0;
        double maxScroll = _nominaScrollController.position.maxScrollExtent;
        targetOffset = targetOffset.clamp(0.0, maxScroll);

        _nominaScrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }


}
