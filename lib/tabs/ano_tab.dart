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
              DateTime weekEnd = weekStart.add(const Duration(
                  days: 6, hours: 23, minutes: 59, seconds: 59));

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
    DateTime weekEnd = weekStart.add(
        const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
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

              Color tileBg;
              Color tileBorder;
              double tileBorderWidth;
              Color letterColor;
              Color numberColor;
              Color starColor = Colors.transparent;

              if (hasData) {
                if (!_isDarkMode) {
                  if (isMantenimiento) {
                    tileBg = const Color(0xFFBFDBFE);
                    tileBorder = const Color(0xFF1D4ED8);
                    tileBorderWidth = 2.5;
                    letterColor = const Color(0xFF1E3A8A);
                    numberColor = const Color(0xFF1E3A8A);
                  } else if (isVacaciones) {
                    tileBg = const Color(0xFFD9F99D);
                    tileBorder = const Color(0xFF4D7C0F);
                    tileBorderWidth = 2.5;
                    letterColor = const Color(0xFF365314);
                    numberColor = const Color(0xFF365314);
                    starColor = const Color(0xFF4D7C0F);
                  } else if (isFestivo) {
                    tileBg = const Color(0xFFE9D5FF);
                    tileBorder = const Color(0xFF7E22CE);
                    tileBorderWidth = 2.5;
                    letterColor = const Color(0xFF581C87);
                    numberColor = const Color(0xFF581C87);
                    starColor = const Color(0xFF7E22CE);
                  } else if (isFalta) {
                    tileBg = const Color(0xFFFECACA);
                    tileBorder = const Color(0xFFB91C1C);
                    tileBorderWidth = 2.5;
                    letterColor = const Color(0xFF7F1D1D);
                    numberColor = const Color(0xFF7F1D1D);
                  } else {
                    // Regular Jornada
                    tileBg = const Color(0xFFBBF7D0);
                    tileBorder = const Color(0xFF15803D);
                    tileBorderWidth = 2.5;
                    letterColor = const Color(0xFF14532D);
                    numberColor = const Color(0xFF14532D);
                  }
                } else {
                  // Dark Mode with Data
                  if (isMantenimiento) {
                    tileBg = Colors.blue.withAlpha(50);
                    tileBorder = Colors.blueAccent;
                    tileBorderWidth = 2.5;
                    letterColor = Colors.blueAccent;
                    numberColor = Colors.blueAccent;
                  } else if (isVacaciones) {
                    tileBg = Colors.lightGreen.withAlpha(50);
                    tileBorder = Colors.lightGreenAccent;
                    tileBorderWidth = 2.5;
                    letterColor = Colors.lightGreenAccent;
                    numberColor = Colors.lightGreenAccent;
                    starColor = Colors.lightGreenAccent;
                  } else if (isFestivo) {
                    tileBg = Colors.purple.withAlpha(50);
                    tileBorder = Colors.purpleAccent;
                    tileBorderWidth = 2.5;
                    letterColor = Colors.purpleAccent;
                    numberColor = Colors.purpleAccent;
                    starColor = Colors.purpleAccent;
                  } else if (isFalta) {
                    tileBg = Colors.red.shade900.withAlpha(180);
                    tileBorder = Colors.redAccent;
                    tileBorderWidth = 2.5;
                    letterColor = Colors.white;
                    numberColor = Colors.white;
                  } else {
                    // Regular Jornada Dark Mode
                    tileBg = Colors.green.withAlpha(50);
                    tileBorder = Colors.greenAccent;
                    tileBorderWidth = 2.5;
                    letterColor = Colors.greenAccent;
                    numberColor = Colors.greenAccent;
                  }
                }
              } else {
                // No Data
                if (isToday) {
                  if (!_isDarkMode) {
                    tileBg = const Color(0xFFFED7AA);
                    tileBorder = const Color(0xFFEA580C);
                    tileBorderWidth = 3.0;
                    letterColor = const Color(0xFF7C2D12);
                    numberColor = const Color(0xFF7C2D12);
                  } else {
                    tileBg = Colors.orangeAccent.withAlpha(70);
                    tileBorder = Colors.orangeAccent;
                    tileBorderWidth = 3.0;
                    letterColor = Colors.white;
                    numberColor = Colors.white;
                  }
                } else {
                  if (!_isDarkMode) {
                    tileBg = Colors.white;
                    tileBorder = isSelected
                        ? const Color(0xFFEA580C)
                        : const Color(0xFF94A3B8);
                    tileBorderWidth = isSelected ? 2.0 : 1.5;
                    numberColor = const Color(0xFF1E293B);
                    letterColor = const Color(0xFF475569);
                  } else {
                    tileBg = isCurrent
                        ? Colors.transparent
                        : Colors.white.withAlpha(5);
                    tileBorder =
                        isSelected ? Colors.orangeAccent : Colors.white12;
                    tileBorderWidth = isSelected ? 2.0 : 1.5;
                    letterColor = Colors.white60;
                    numberColor =
                        isCurrent ? Colors.white : Colors.white70;
                  }
                }
              }

              return GestureDetector(
                onTap: () {
                  _rebuild(() => _selectedCalendarDay = dayDate);
                  _showManualDayDialog(dayDate);
                },
                child: Container(
                  width: isToday ? 46 : 42,
                  height: isToday ? 46 : 42,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: tileBg,
                    borderRadius: BorderRadius.circular(isToday ? 10 : 8),
                    border: Border.all(
                      color: tileBorder,
                      width: tileBorderWidth,
                    ),
                    boxShadow: isToday
                        ? [
                            BoxShadow(
                              color: const Color(0xFFEA580C)
                                  .withAlpha(_isDarkMode ? 120 : 160),
                              blurRadius: 6,
                              spreadRadius: 2.5,
                            ),
                          ]
                        : null,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isToday && hasData) ...[
                            Container(
                              width: 14,
                              height: 3,
                              margin: const EdgeInsets.only(bottom: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEA580C),
                                borderRadius: BorderRadius.circular(1.5),
                              ),
                            ),
                          ],
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(dayLetter,
                                  style: TextStyle(
                                      color: letterColor,
                                      fontSize: isToday ? 11 : 10,
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
                                  color: starColor,
                                  size: 10,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(dayDate.day.toString(),
                              style: TextStyle(
                                  color: numberColor,
                                  fontSize: isToday ? 15 : 14,
                                  height: 1.0,
                                  fontWeight: isToday
                                      ? FontWeight.w900
                                      : FontWeight.bold)),
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
