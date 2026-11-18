part of '../main.dart';

/// Recursively sanitizes a map/doc for local JSON caching in SharedPreferences.
/// Converts [Timestamp], [DateTime], and [FieldValue] into ISO8601 strings.
Map<String, dynamic> sanitizeUnitShareMapForCache(Map<String, dynamic> data) {
  final sanitized = <String, dynamic>{};
  data.forEach((key, value) {
    if (value is Timestamp) {
      sanitized[key] = value.toDate().toIso8601String();
    } else if (value is DateTime) {
      sanitized[key] = value.toIso8601String();
    } else if (value is FieldValue) {
      sanitized[key] = DateTime.now().toIso8601String();
    } else if (value is Map) {
      sanitized[key] =
          sanitizeUnitShareMapForCache(Map<String, dynamic>.from(value));
    } else if (value is List) {
      sanitized[key] = value.map((item) {
        if (item is Timestamp) {
          return item.toDate().toIso8601String();
        } else if (item is DateTime) {
          return item.toIso8601String();
        } else if (item is FieldValue) {
          return DateTime.now().toIso8601String();
        } else if (item is Map) {
          return sanitizeUnitShareMapForCache(Map<String, dynamic>.from(item));
        }
        return item;
      }).toList();
    } else {
      sanitized[key] = value;
    }
  });
  return sanitized;
}

class _UnitMemberAttendanceCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool isDarkMode;

  const _UnitMemberAttendanceCard({
    required this.data,
    required this.isDarkMode,
  });

  @override
  State<_UnitMemberAttendanceCard> createState() =>
      _UnitMemberAttendanceCardState();
}

class _UnitMemberAttendanceCardState extends State<_UnitMemberAttendanceCard> {
  bool _isExpanded = true;

  String _getShortDayName(int weekday) {
    switch (weekday) {
      case 1:
        return "Lun";
      case 2:
        return "Mar";
      case 3:
        return "Mié";
      case 4:
        return "Jue";
      case 5:
        return "Vie";
      case 6:
        return "Sáb";
      case 7:
        return "Dom";
      default:
        return "";
    }
  }

  Widget _buildDailyAttendanceCard(
      Map<String, dynamic> shift, bool isDarkMode) {
    final String dateStr = (shift['date'] ?? '').toString();
    DateTime? date;
    if (shift['entrada'] is Timestamp) {
      date = (shift['entrada'] as Timestamp).toDate();
    } else if (dateStr.isNotEmpty) {
      date = DateTime.tryParse(dateStr);
    }

    final String dayName = date != null
        ? "${_getShortDayName(date.weekday)} ${DateFormat('dd/MM').format(date)}"
        : dateStr;

    final bool isInProgress = shift['is_in_progress'] == true;
    final bool isFalta = shift['es_falta'] == true;
    final bool isFestivo = shift['es_festivo'] == true;
    final bool isVacaciones = shift['es_vacaciones'] == true;

    final String? entradaStr = shift['entrada_str'] as String?;
    final String? salidaStr = shift['salida_str'] as String?;
    final String? entradaRealStr = shift['entrada_real_str'] as String?;
    final String notes = (shift['notas'] ?? '').toString().trim();

    Color badgeColor;
    String badgeText;
    if (isFalta) {
      badgeColor = Colors.redAccent;
      badgeText = "FALTA";
    } else if (isInProgress) {
      badgeColor = Colors.amber;
      badgeText = "EN CURSO";
    } else if (isFestivo) {
      badgeColor = Colors.purpleAccent;
      badgeText = "FESTIVO";
    } else if (isVacaciones) {
      badgeColor = Colors.blueAccent;
      badgeText = "VACACIONES";
    } else {
      badgeColor = Colors.teal;
      badgeText = "COMPLETO";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF131822) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dayName,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withAlpha(isDarkMode ? 40 : 25),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: badgeColor.withAlpha(100)),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (!isFalta) ...[
            Row(
              children: [
                Icon(Icons.login_rounded,
                    size: 11, color: Colors.greenAccent.shade400),
                const SizedBox(width: 4),
                Text(
                  "Ent: ",
                  style: TextStyle(
                      color: isDarkMode ? Colors.white60 : const Color(0xFF1E293B),
                      fontSize: 10),
                ),
                Expanded(
                  child: Text(
                    entradaStr ?? "---",
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.logout_rounded,
                    size: 11, color: Colors.redAccent.shade200),
                const SizedBox(width: 4),
                Text(
                  "Sal: ",
                  style: TextStyle(
                      color: isDarkMode ? Colors.white60 : const Color(0xFF1E293B),
                      fontSize: 10),
                ),
                Expanded(
                  child: Text(
                    isInProgress ? "En turno" : (salidaStr ?? "---"),
                    style: TextStyle(
                      color: isInProgress
                          ? Colors.amber
                          : (isDarkMode ? Colors.white : Colors.black),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (entradaRealStr != null && entradaRealStr.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.timer_outlined,
                      size: 11, color: Colors.cyanAccent),
                  const SizedBox(width: 4),
                  Text(
                    "Real: ",
                    style: TextStyle(
                        color: isDarkMode ? Colors.white60 : const Color(0xFF1E293B),
                        fontSize: 10),
                  ),
                  Expanded(
                    child: Text(
                      entradaRealStr,
                      style: TextStyle(
                        color: isDarkMode
                            ? Colors.cyanAccent
                            : const Color(0xFF0284C7),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.black26 : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 10,
                      color: isDarkMode ? Colors.white54 : const Color(0xFF1E293B)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      notes,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black,
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttendanceColumn({
    required String title,
    required String subtitle,
    required List<Map<String, dynamic>> shifts,
    required Color accentColor,
    required bool isThisWeek,
    required bool isDarkMode,
    String? timeframe,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF1E293B).withAlpha(150)
            : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDarkMode ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isDarkMode
                            ? Colors.white54
                            : const Color(0xFF1E293B),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(isDarkMode ? 35 : 20),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: accentColor.withAlpha(80)),
                ),
                child: Text(
                  "${shifts.length} ${shifts.length == 1 ? 'd' : 'd'}",
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (shifts.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.black26 : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                (!isThisWeek &&
                        (timeframe == 'current_week' ||
                            timeframe == 'Esta semana'))
                    ? "No compartido por colaborador\n(Solo semana en curso)"
                    : "Sin registros para este período",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDarkMode ? Colors.white38 : const Color(0xFF1E293B),
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            Column(
              children: shifts
                  .map((s) => _buildDailyAttendanceCard(s, isDarkMode))
                  .toList(),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;
    final data = widget.data;
    final Color unitColor =
        isDarkMode ? Colors.cyanAccent : const Color(0xFF0284C7);
    final Color cardBg =
        isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final Color borderColor =
        isDarkMode ? Colors.white12 : const Color(0xFFCBD5E1);
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color subtextColor =
        isDarkMode ? Colors.white54 : const Color(0xFF1E293B);

    final String memberName =
        (data['member_name'] ?? 'Sin nombre').toString();
    final String memberEmp =
        (data['member_emp'] ?? '---').toString();

    // Active status / retention check
    final now = DateTime.now();
    final rawUntil = data['active_sharing_until'];
    DateTime? activeUntil;
    if (rawUntil is Timestamp) {
      activeUntil = rawUntil.toDate();
    } else if (rawUntil is String) {
      activeUntil = DateTime.tryParse(rawUntil);
    }

    final bool isCurrentlyActive =
        activeUntil != null && activeUntil.isAfter(now);

    // Format last clock out
    final rawLastClockOut = data['last_clock_out'];
    DateTime? lastClockOut;
    if (rawLastClockOut is Timestamp) {
      lastClockOut = rawLastClockOut.toDate();
    } else if (rawLastClockOut is String) {
      lastClockOut = DateTime.tryParse(rawLastClockOut);
    }

    final String lastClockOutStr = lastClockOut != null
        ? DateFormat('dd/MM/yyyy - hh:mm a').format(lastClockOut)
        : "Sin salida registrada";

    // Split shifts into This Week vs Last Week
    final rawShifts = (data['shifts'] as List?) ?? [];
    final List<Map<String, dynamic>> shifts = rawShifts
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final mondayThisWeek = now.subtract(Duration(days: now.weekday - 1));
    final startThisWeek =
        DateTime(mondayThisWeek.year, mondayThisWeek.month, mondayThisWeek.day);
    final endThisWeek = startThisWeek
        .add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

    final mondayLastWeek = startThisWeek.subtract(const Duration(days: 7));
    final endLastWeek = startThisWeek.subtract(const Duration(seconds: 1));

    final thisWeekShifts = shifts.where((s) {
      final String dateStr = (s['date'] ?? '').toString();
      DateTime? d;
      if (s['entrada'] is Timestamp) {
        d = (s['entrada'] as Timestamp).toDate();
      } else if (dateStr.isNotEmpty) {
        d = DateTime.tryParse(dateStr);
      }
      if (d == null) return false;
      return d.isAfter(startThisWeek.subtract(const Duration(seconds: 1))) &&
          d.isBefore(endThisWeek.add(const Duration(seconds: 1)));
    }).toList()
      ..sort((a, b) =>
          (a['date'] ?? '').toString().compareTo((b['date'] ?? '').toString()));

    final lastWeekShifts = shifts.where((s) {
      final String dateStr = (s['date'] ?? '').toString();
      DateTime? d;
      if (s['entrada'] is Timestamp) {
        d = (s['entrada'] as Timestamp).toDate();
      } else if (dateStr.isNotEmpty) {
        d = DateTime.tryParse(dateStr);
      }
      if (d == null) return false;
      return d.isAfter(mondayLastWeek.subtract(const Duration(seconds: 1))) &&
          d.isBefore(endLastWeek.add(const Duration(seconds: 1)));
    }).toList()
      ..sort((a, b) =>
          (a['date'] ?? '').toString().compareTo((b['date'] ?? '').toString()));

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDarkMode ? 35 : 10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: unitColor.withAlpha(isDarkMode ? 35 : 20),
                    child: Text(
                      memberName.isNotEmpty ? memberName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: unitColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          memberName,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.white10
                                    : const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "No. $memberEmp",
                                style: TextStyle(
                                  color: subtextColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (isCurrentlyActive)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withAlpha(30),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: Colors.green.withAlpha(100)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_circle_rounded,
                                        size: 10, color: Colors.greenAccent),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Activo",
                                      style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.greenAccent
                                            : Colors.green.shade800,
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
                                  color: Colors.amber.withAlpha(30),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: Colors.amber.withAlpha(100)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.history_rounded,
                                        size: 10, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    Text(
                                      "En consulta (14d)",
                                      style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.amber
                                            : Colors.amber.shade900,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.calendar_month_rounded,
                      color: unitColor,
                      size: 22,
                    ),
                    tooltip: "Ver calendario de asistencias",
                    onPressed: () => _showMemberCalendarDialog(
                      context,
                      shifts,
                      memberName,
                      isDarkMode,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: subtextColor,
                    ),
                    onPressed: () =>
                        setState(() => _isExpanded = !_isExpanded),
                  ),
                ],
              ),
            ),
          ),

          // Quick Glance: Last clock-out
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.white10
                      : const Color(0xFFCBD5E1),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.logout_rounded,
                      size: 14,
                      color: isDarkMode
                          ? Colors.cyanAccent
                          : const Color(0xFF0284C7)),
                  const SizedBox(width: 8),
                  Text(
                    "Última Salida: ",
                    style: TextStyle(
                      color: isDarkMode
                          ? Colors.white70
                          : const Color(0xFF475569),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      lastClockOutStr,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Expandable 2 Parallel Columns
          if (_isExpanded) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildAttendanceColumn(
                      title: "Esta Semana",
                      subtitle:
                          "${DateFormat('dd/MM').format(startThisWeek)} - ${DateFormat('dd/MM').format(endThisWeek)}",
                      shifts: thisWeekShifts,
                      accentColor: unitColor,
                      isThisWeek: true,
                      isDarkMode: isDarkMode,
                      timeframe: data['timeframe'],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildAttendanceColumn(
                      title: "Semana Pasada",
                      subtitle:
                          "${DateFormat('dd/MM').format(mondayLastWeek)} - ${DateFormat('dd/MM').format(endLastWeek)}",
                      shifts: lastWeekShifts,
                      accentColor: isDarkMode
                          ? Colors.orangeAccent
                          : const Color(0xFFEA580C),
                      isThisWeek: false,
                      isDarkMode: isDarkMode,
                      timeframe: data['timeframe'],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  static const List<String> _calendarMonthsES = [
    "Enero",
    "Febrero",
    "Marzo",
    "Abril",
    "Mayo",
    "Junio",
    "Julio",
    "Agosto",
    "Septiembre",
    "Octubre",
    "Noviembre",
    "Diciembre"
  ];

  static const List<String> _calendarDaysES = [
    "Lunes",
    "Martes",
    "Miércoles",
    "Jueves",
    "Viernes",
    "Sábado",
    "Domingo"
  ];

  void _showMemberCalendarDialog(
    BuildContext context,
    List<Map<String, dynamic>> shifts,
    String memberName,
    bool isDarkMode,
  ) {
    final Map<String, Map<String, dynamic>> shiftByDate = {};
    for (var s in shifts) {
      final String d = (s['date'] ?? '').toString();
      if (d.isNotEmpty) {
        shiftByDate[d] = s;
      }
    }

    final now = DateTime.now();
    DateTime displayMonth = DateTime(now.year, now.month, 1);
    DateTime? selectedDate = now;

    if (!shiftByDate.containsKey(DateFormat('yyyy-MM-dd').format(now)) &&
        shifts.isNotEmpty) {
      final sortedShifts = List<Map<String, dynamic>>.from(shifts)
        ..sort((a, b) => (b['date'] ?? '')
            .toString()
            .compareTo((a['date'] ?? '').toString()));
      final latestDateStr = (sortedShifts.first['date'] ?? '').toString();
      final parsed = DateTime.tryParse(latestDateStr);
      if (parsed != null) {
        selectedDate = parsed;
        displayMonth = DateTime(parsed.year, parsed.month, 1);
      }
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final daysInMonth =
                DateTime(displayMonth.year, displayMonth.month + 1, 0).day;
            final int firstWeekday = displayMonth.weekday; // 1 = Monday
            final int leadingBlanks = firstWeekday - 1;

            final selectedDateStr = selectedDate != null
                ? DateFormat('yyyy-MM-dd').format(selectedDate!)
                : '';
            final selectedShift = selectedDateStr.isNotEmpty
                ? shiftByDate[selectedDateStr]
                : null;

            final Color dialogBg =
                isDarkMode ? const Color(0xFF1E293B) : Colors.white;
            final Color textColor = isDarkMode ? Colors.white : Colors.black;
            final Color subtextColor =
                isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF1E293B);
            final Color primaryColor =
                isDarkMode ? Colors.cyanAccent : const Color(0xFF0284C7);

            final String monthYearStr =
                "${_calendarMonthsES[displayMonth.month - 1]} ${displayMonth.year}";

            return Dialog(
              backgroundColor: dialogBg,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.all(18),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: primaryColor
                                      .withAlpha(isDarkMode ? 35 : 20),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.calendar_month_rounded,
                                  color: primaryColor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Calendario de Turnos",
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    memberName,
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(Icons.close_rounded,
                                color: subtextColor, size: 22),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Month Navigation Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(Icons.chevron_left_rounded,
                                color: textColor),
                            onPressed: () {
                              setDialogState(() {
                                displayMonth = DateTime(displayMonth.year,
                                    displayMonth.month - 1, 1);
                              });
                            },
                          ),
                          Text(
                            monthYearStr,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.chevron_right_rounded,
                                color: textColor),
                            onPressed: () {
                              setDialogState(() {
                                displayMonth = DateTime(displayMonth.year,
                                    displayMonth.month + 1, 1);
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Weekday Headers
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: ["L", "M", "M", "J", "V", "S", "D"]
                            .map(
                              (d) => SizedBox(
                                width: 36,
                                child: Text(
                                  d,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: subtextColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 8),

                      // Calendar Grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: leadingBlanks + daysInMonth,
                        itemBuilder: (ctx, index) {
                          if (index < leadingBlanks) {
                            return const SizedBox.shrink();
                          }
                          final dayNum = index - leadingBlanks + 1;
                          final cellDate = DateTime(
                              displayMonth.year, displayMonth.month, dayNum);
                          final cellDateStr =
                              DateFormat('yyyy-MM-dd').format(cellDate);
                          final bool isMarked =
                              shiftByDate.containsKey(cellDateStr);
                          final bool isSelected = selectedDate != null &&
                              selectedDate!.year == cellDate.year &&
                              selectedDate!.month == cellDate.month &&
                              selectedDate!.day == cellDate.day;

                          final shift = shiftByDate[cellDateStr];
                          Color dotColor = Colors.transparent;
                          if (shift != null) {
                            if (shift['es_falta'] == true) {
                              dotColor = Colors.redAccent;
                            } else if (shift['is_in_progress'] == true) {
                              dotColor = Colors.amber;
                            } else if (shift['es_festivo'] == true) {
                              dotColor = Colors.purpleAccent;
                            } else if (shift['es_vacaciones'] == true) {
                              dotColor = Colors.blueAccent;
                            } else {
                              dotColor = isDarkMode
                                  ? Colors.tealAccent
                                  : Colors.teal;
                            }
                          }

                          return InkWell(
                            onTap: () {
                              setDialogState(() {
                                selectedDate = cellDate;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? primaryColor
                                        .withAlpha(isDarkMode ? 60 : 35)
                                    : (isMarked
                                        ? (isDarkMode
                                            ? Colors.white.withAlpha(12)
                                            : const Color(0xFFF1F5F9))
                                        : Colors.transparent),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? primaryColor
                                      : (isMarked
                                          ? dotColor.withAlpha(
                                              isDarkMode ? 120 : 160)
                                          : Colors.transparent),
                                  width: isSelected ? 1.8 : 1.0,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "$dayNum",
                                    style: TextStyle(
                                      color: isSelected
                                          ? (isDarkMode
                                              ? Colors.white
                                              : primaryColor)
                                          : (isMarked
                                              ? textColor
                                              : subtextColor.withAlpha(120)),
                                      fontWeight: isSelected || isMarked
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (isMarked) ...[
                                    const SizedBox(height: 2),
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: dotColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 18),
                      const Divider(height: 1),
                      const SizedBox(height: 14),

                      // Selected Date Detail Card
                      if (selectedShift != null)
                        _buildCalendarShiftDetailCard(
                            selectedShift, isDarkMode, textColor, subtextColor)
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 16),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.white.withAlpha(6)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDarkMode
                                  ? Colors.white10
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.event_busy_rounded,
                                color: subtextColor,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      selectedDate != null
                                          ? "${_calendarDaysES[selectedDate!.weekday - 1]}, ${selectedDate!.day} de ${_calendarMonthsES[selectedDate!.month - 1]} ${selectedDate!.year}"
                                          : "Fecha seleccionada",
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Sin registros compartidos para esta fecha.",
                                      style: TextStyle(
                                        color: subtextColor,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            "CERRAR",
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCalendarShiftDetailCard(
    Map<String, dynamic> shift,
    bool isDarkMode,
    Color textColor,
    Color subtextColor,
  ) {
    final String dateStr = (shift['date'] ?? '').toString();
    DateTime? date;
    if (shift['entrada'] is Timestamp) {
      date = (shift['entrada'] as Timestamp).toDate();
    } else if (dateStr.isNotEmpty) {
      date = DateTime.tryParse(dateStr);
    }

    final String formattedDate = date != null
        ? "${_calendarDaysES[date.weekday - 1]}, ${date.day} de ${_calendarMonthsES[date.month - 1]} ${date.year}"
        : dateStr;

    final bool isInProgress = shift['is_in_progress'] == true;
    final bool isFalta = shift['es_falta'] == true;
    final bool isFestivo = shift['es_festivo'] == true;
    final bool isVacaciones = shift['es_vacaciones'] == true;

    final String? entradaStr = shift['entrada_str'] as String?;
    final String? salidaStr = shift['salida_str'] as String?;
    final String? entradaRealStr = shift['entrada_real_str'] as String?;
    final String notes = (shift['notas'] ?? '').toString().trim();

    Color badgeColor;
    String badgeText;
    if (isFalta) {
      badgeColor = Colors.redAccent;
      badgeText = "FALTA";
    } else if (isInProgress) {
      badgeColor = Colors.amber;
      badgeText = "EN CURSO";
    } else if (isFestivo) {
      badgeColor = Colors.purpleAccent;
      badgeText = "FESTIVO";
    } else if (isVacaciones) {
      badgeColor = Colors.blueAccent;
      badgeText = "VACACIONES";
    } else {
      badgeColor = isDarkMode ? Colors.tealAccent : Colors.teal;
      badgeText = "COMPLETADO";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.white12 : const Color(0xFFCBD5E1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  formattedDate,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withAlpha(isDarkMode ? 40 : 25),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: badgeColor.withAlpha(120)),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.login_rounded,
                        size: 15,
                        color: isDarkMode
                            ? Colors.greenAccent
                            : const Color(0xFF16A34A)),
                    const SizedBox(width: 6),
                    Text(
                      "Entrada: ",
                      style: TextStyle(color: subtextColor, fontSize: 12),
                    ),
                    Text(
                      entradaStr ?? "---",
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded,
                        size: 15,
                        color: isInProgress
                            ? Colors.amber
                            : (isDarkMode
                                ? Colors.redAccent
                                : const Color(0xFFDC2626))),
                    const SizedBox(width: 6),
                    Text(
                      "Salida: ",
                      style: TextStyle(color: subtextColor, fontSize: 12),
                    ),
                    Text(
                      isInProgress ? "En turno" : (salidaStr ?? "---"),
                      style: TextStyle(
                        color: isInProgress ? Colors.amber : textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (entradaRealStr != null && entradaRealStr.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.timer_outlined,
                    size: 15,
                    color: isDarkMode
                        ? Colors.cyanAccent
                        : const Color(0xFF0284C7)),
                const SizedBox(width: 6),
                Text(
                  "Entrada Real: ",
                  style: TextStyle(color: subtextColor, fontSize: 12),
                ),
                Text(
                  entradaRealStr,
                  style: TextStyle(
                    color: isDarkMode
                        ? Colors.cyanAccent
                        : const Color(0xFF0284C7),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.white.withAlpha(8)
                    : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes_rounded, size: 14, color: subtextColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      notes,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 11.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Recursively sanitizes a value (or nested maps/lists) so that any [FieldValue]
/// (such as [FieldValue.serverTimestamp()]) is converted into a [Timestamp] before
/// being placed into Firestore arrays or nested maps.
dynamic sanitizeForFirestoreArray(dynamic value) {
  if (value is FieldValue) {
    return Timestamp.now();
  }
  if (value is Map) {
    final sanitized = <String, dynamic>{};
    value.forEach((k, v) {
      sanitized[k.toString()] = sanitizeForFirestoreArray(v);
    });
    return sanitized;
  }
  if (value is List) {
    return value.map((item) => sanitizeForFirestoreArray(item)).toList();
  }
  return value;
}

/// Sanitizes a shares map to guarantee that no individual grant contains [FieldValue] instances.
Map<String, Map<String, dynamic>> sanitizeSharesMapForFirestore(
    Map<dynamic, dynamic> rawShares) {
  final result = <String, Map<String, dynamic>>{};
  rawShares.forEach((key, value) {
    if (value is Map) {
      result[key.toString()] =
          Map<String, dynamic>.from(sanitizeForFirestoreArray(value) as Map);
    }
  });
  return result;
}

/// Parses a unit-share date/timestamp stored as [Timestamp], [DateTime], or ISO string.
DateTime? parseUnitShareDate(dynamic raw) {
  if (raw == null) return null;
  if (raw is Timestamp) return raw.toDate();
  if (raw is DateTime) return raw;
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}

/// Parses a dynamic list/iterable into a set of non-empty string IDs or date keys.
Set<String> parseUnitShareStringSet(dynamic raw) {
  if (raw == null) return <String>{};
  if (raw is Iterable) {
    return raw
        .map((e) => e.toString().trim())
        .where((s) => s.isNotEmpty)
        .toSet();
  }
  return <String>{};
}

/// Checks whether a specific shift date / id is shared under unit share rules.
bool isDateSharedUnderUnitShare({
  required DateTime date,
  String? shiftId,
  required String mode,
  DateTime? activeUntil,
  Set<String> customDates = const <String>{},
  Set<String> excludedDates = const <String>{},
  DateTime? now,
}) {
  final String dateKey = DateFormat('yyyy-MM-dd').format(date);
  final bool hasShiftId = shiftId != null && shiftId.isNotEmpty;

  // 1. Excluded dates always take precedence
  if (excludedDates.contains(dateKey) ||
      (hasShiftId && excludedDates.contains(shiftId))) {
    return false;
  }

  // 2. 'Yo Decido': ONLY dates in custom_dates (minus excluded) are shared.
  // Empty custom_dates MUST produce false (never all shifts).
  if (mode == 'Yo Decido') {
    if (customDates.isEmpty) return false;
    return customDates.contains(dateKey) ||
        (hasShiftId && customDates.contains(shiftId));
  }

  // 3. 'Todos Mis Registros': shares everything (not excluded)
  if (mode == 'Todos Mis Registros') {
    return true;
  }

  final DateTime ref = now ?? DateTime.now();

  // 4. 'Solo Hoy': only the activation date (or target date)
  if (mode == 'Solo Hoy') {
    final DateTime targetDate = activeUntil ?? ref;
    return date.year == targetDate.year &&
        date.month == targetDate.month &&
        date.day == targetDate.day;
  }

  // 5. 'Este Mes' / 'Mensual'
  if (mode == 'Este Mes' || mode == 'Mensual') {
    final monthStart = DateTime(ref.year, ref.month, 1);
    final monthEnd = DateTime(ref.year, ref.month + 1, 0, 23, 59, 59);
    return !date.isBefore(monthStart) && !date.isAfter(monthEnd);
  }

  // 6. 'Este Año' / 'Anual'
  if (mode == 'Este Año' || mode == 'Anual') {
    final yearStart = DateTime(ref.year, 1, 1);
    final yearEnd = DateTime(ref.year, 12, 31, 23, 59, 59);
    return !date.isBefore(yearStart) && !date.isAfter(yearEnd);
  }

  // 7. Week modes: 'Esta Semana y la Pasada' vs 'Esta Semana' (default)
  final monday = ref.subtract(Duration(days: ref.weekday - 1));
  final sunday = monday.add(const Duration(days: 6));
  final sundayEnd =
      DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);

  if (mode == 'Esta Semana y la Pasada' ||
      mode == 'two_weeks' ||
      mode == 'current_and_previous') {
    final mondayLastWeek = monday.subtract(const Duration(days: 7));
    final mondayLastWeekStart = DateTime(
        mondayLastWeek.year, mondayLastWeek.month, mondayLastWeek.day);
    return !date.isBefore(mondayLastWeekStart) && !date.isAfter(sundayEnd);
  }

  // Default: Esta Semana / Semanal / current_week
  final mondayStart = DateTime(monday.year, monday.month, monday.day);
  return !date.isBefore(mondayStart) && !date.isAfter(sundayEnd);
}

/// Filters a list of WorkDay shifts according to unit share mode and date bounds.
List<WorkDay> filterWorkDaysForUnitShare(
  List<WorkDay> shifts, {
  required String mode,
  DateTime? activeUntil,
  Set<String> customDates = const <String>{},
  Set<String> excludedDates = const <String>{},
  DateTime? now,
}) {
  return shifts.where((d) {
    return isDateSharedUnderUnitShare(
      date: d.entrada,
      shiftId: d.id,
      mode: mode,
      activeUntil: activeUntil,
      customDates: customDates,
      excludedDates: excludedDates,
      now: now,
    );
  }).toList();
}

/// Sanitizes a list of WorkDay shifts for sharing to a Unit Manager.
List<Map<String, dynamic>> sanitizeWorkDaysForUnitShare(
  List<WorkDay> shifts, {
  bool shareEntry = true,
  bool shareExit = true,
  bool shareRealEntry = false,
  bool shareNotes = false,
}) {
  return shifts.map((d) {
    return {
      'id': d.id,
      'date': DateFormat('yyyy-MM-dd').format(d.entrada),
      'weekday': d.entrada.weekday,
      'entrada': shareEntry ? Timestamp.fromDate(d.entrada) : null,
      'entrada_str':
          shareEntry ? DateFormat('hh:mm a').format(d.entrada) : null,
      'salida': (shareExit && !d.isInProgress)
          ? Timestamp.fromDate(d.salida)
          : null,
      'salida_str': (shareExit && !d.isInProgress)
          ? DateFormat('hh:mm a').format(d.salida)
          : null,
      'entrada_real': (shareRealEntry && d.entradaReal != null)
          ? Timestamp.fromDate(d.entradaReal!)
          : null,
      'entrada_real_str': (shareRealEntry && d.entradaReal != null)
          ? DateFormat('hh:mm a').format(d.entradaReal!)
          : null,
      'notas': shareNotes ? d.notas : '',
      'is_in_progress': d.isInProgress,
      'es_falta': d.esFalta,
      'es_festivo': d.esFestivo,
      'es_vacaciones': d.esVacaciones,
    };
  }).toList();
}

/// Extracts all active (non-expired and is_active!=false) share grants from a unit_share document.
Map<String, Map<String, dynamic>> extractActiveSharesFromMap(
    Map<String, dynamic> data) {
  final Map<String, Map<String, dynamic>> result = {};
  final now = DateTime.now();

  final rawShares = data['shares'];
  if (rawShares is Map && rawShares.isNotEmpty) {
    for (final entry in rawShares.entries) {
      if (entry.value is Map) {
        final grant = Map<String, dynamic>.from(entry.value as Map);
        final activeUntil = parseUnitShareDate(grant['active_sharing_until']);
        final isExpired =
            activeUntil != null && now.isAfter(activeUntil);
        if (grant['is_active'] != false && !isExpired) {
          final uid = (grant['manager_uid'] ?? entry.key).toString().trim();
          if (uid.isNotEmpty) {
            result[uid] = grant;
          }
        }
      }
    }
  }

  if (result.isNotEmpty) return result;

  // Fallback: check 'managers' list or legacy top-level
  final bool isOverallActive = data['is_active'] == true;
  final overallActiveUntil = parseUnitShareDate(data['active_sharing_until']);
  final isOverallExpired =
      overallActiveUntil != null && now.isAfter(overallActiveUntil);

  if (isOverallActive && !isOverallExpired) {
    final rawManagers = data['managers'];
    if (rawManagers is List && rawManagers.isNotEmpty) {
      for (final m in rawManagers) {
        if (m is Map) {
          final uid = (m['uid'] ?? '').toString().trim();
          if (uid.isNotEmpty) {
            result[uid] = {
              'manager_uid': uid,
              'manager_doc_id': (m['doc_id'] ?? '').toString().trim(),
              'manager_name':
                  (m['name'] ?? 'Ingeniero de Unidad').toString().trim(),
              'manager_emp':
                  (m['emp'] ?? m['employee_number'] ?? '').toString().trim(),
              'mode': data['mode'] ?? data['duration'] ?? 'Esta Semana',
              'active_sharing_until': data['active_sharing_until'],
              'data_retention_until': data['data_retention_until'],
              'share_entry': data['share_entry'] ?? true,
              'share_exit': data['share_exit'] ?? true,
              'share_real_entry': data['share_real_entry'] == true,
              'share_notes': data['share_notes'] == true,
              'custom_dates': data['custom_dates'] ?? [],
              'excluded_dates': data['excluded_dates'] ?? [],
              'is_active': true,
            };
          }
        }
      }
    }
    if (result.isEmpty) {
      final legacyUid =
          (data['manager_uid'] ?? data['uid'] ?? '').toString().trim();
      if (legacyUid.isNotEmpty) {
        result[legacyUid] = {
          'manager_uid': legacyUid,
          'manager_doc_id': (data['manager_doc_id'] ?? '').toString().trim(),
          'manager_name':
              (data['manager_name'] ?? 'Ingeniero de Unidad').toString().trim(),
          'manager_emp': (data['manager_emp'] ?? '').toString().trim(),
          'mode': data['mode'] ?? data['duration'] ?? 'Esta Semana',
          'active_sharing_until': data['active_sharing_until'],
          'data_retention_until': data['data_retention_until'],
          'share_entry': data['share_entry'] ?? true,
          'share_exit': data['share_exit'] ?? true,
          'share_real_entry': data['share_real_entry'] == true,
          'share_notes': data['share_notes'] == true,
          'custom_dates': data['custom_dates'] ?? [],
          'excluded_dates': data['excluded_dates'] ?? [],
          'is_active': true,
        };
      }
    }
  }
  return result;
}

class UnitShareScreen extends StatefulWidget {
  final bool isDarkMode;
  final List<WorkDay>? weeklyHistory;

  const UnitShareScreen({
    super.key,
    required this.isDarkMode,
    this.weeklyHistory,
  });

  @override
  State<UnitShareScreen> createState() => _UnitShareScreenState();
}


class _UnitShareScreenState extends State<UnitShareScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUnitShareActive = false;
  Map<String, dynamic>? _shareData;

  // Active independent shares: managerUid -> grant map
  Map<String, Map<String, dynamic>> _activeShares = {};

  // For viewing shared shifts under active shares:
  String? _inspectingManagerUid;
  List<Map<String, dynamic>> _sharedShifts = [];
  StreamSubscription? _memberSubscription;

  // Search controller and state
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounceTimer;
  bool _isSearching = false;
  String? _searchError;
  List<Map<String, dynamic>> _searchResults = [];

  // Configuration mode:
  // If active shares exist, we view the active cards list by default (_isConfiguringShare = false).
  // When adding (+ Compartir con otro Ingeniero) or editing an existing share, _isConfiguringShare = true.
  // If no active shares exist, _isConfiguringShare is true by default.
  bool _isConfiguringShare = false;
  String? _editingManagerUid; // null if adding/new share, managerUid if editing
  Map<String, dynamic>? _selectedCandidate; // the engineer candidate picked for this configuration

  String _selectedMode = 'Esta Semana';
  static const List<String> _unifiedModes = [
    'Solo Hoy',
    'Esta Semana',
    'Esta Semana y la Pasada',
    'Este Mes',
    'Este Año',
    'Todos Mis Registros',
    'Yo Decido',
  ];

  bool _shareEntry = true;
  bool _shareExit = true;
  bool _shareRealEntry = false;
  bool _shareNotes = false;

  String _userName = '';
  String _userEmp = '';
  List<WorkDay> _userWorkDays = [];
  Set<String> _excludedDates = {};
  Set<String> _customDates = {};

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _memberSubscription?.cancel();
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _sanitizeUnitShareMap(Map<String, dynamic> data) {
    return sanitizeUnitShareMapForCache(data);
  }

  Map<String, Map<String, dynamic>> _extractActiveSharesFromMap(
      Map<String, dynamic> data) {
    return extractActiveSharesFromMap(data);
  }

  Future<void> _loadInitialData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. Load User Profile
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists && userDoc.data() != null) {
        final ud = userDoc.data()!;
        _userName = "${ud['first_name'] ?? ''} ${ud['last_name'] ?? ''}".trim();
        if (_userName.isEmpty) _userName = user.displayName ?? '';
        _userEmp = (ud['employee_number'] ?? ud['user_emp'] ?? '').toString();
      }

      // 2. Load WorkDays History
      if (widget.weeklyHistory != null && widget.weeklyHistory!.isNotEmpty) {
        _userWorkDays = List.from(widget.weeklyHistory!);
      } else {
        final daysSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('days')
            .get();
        if (daysSnap.docs.isNotEmpty) {
          _userWorkDays = daysSnap.docs
              .map((d) => WorkDay.fromJson(d.data()))
              .toList();
          _userWorkDays.sort((a, b) => b.entrada.compareTo(a.entrada));
        }
      }

      // 3. Load Unit Share Settings
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'active_unit_share_cache_${user.uid}';
      final cached = prefs.getString(cacheKey);
      if (cached != null) {
        try {
          final Map<String, dynamic> c = jsonDecode(cached);
          final parsedShares = _extractActiveSharesFromMap(c);
          if (parsedShares.isNotEmpty) {
            _activeShares = parsedShares;
            _shareData = _sanitizeUnitShareMap(c);
            _isUnitShareActive = true;
            _isConfiguringShare = false;
          }
        } catch (_) {}
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('unit_share')
          .get();

      if (doc.exists && doc.data() != null) {
        final d = doc.data()!;
        final parsedShares = _extractActiveSharesFromMap(d);
        if (parsedShares.isNotEmpty) {
          _activeShares = parsedShares;
          _shareData = _sanitizeUnitShareMap(d);
          _isUnitShareActive = true;
          _isConfiguringShare = false;

          // Self-heal each manager
          for (final entry in _activeShares.entries) {
            final grant = entry.value;
            final mUid = entry.key;
            final activeUntil = parseUnitShareDate(grant['active_sharing_until']);
            _healSharedShifts(
              managerUid: mUid,
              userUid: user.uid,
              mode: (grant['mode'] ?? grant['duration'] ?? 'Esta Semana')
                  .toString(),
              activeUntil: activeUntil,
              customDates: parseUnitShareStringSet(grant['custom_dates']),
              excludedDates: parseUnitShareStringSet(grant['excluded_dates']),
              shareEntry: grant['share_entry'] ?? true,
              shareExit: grant['share_exit'] ?? true,
              shareRealEntry: grant['share_real_entry'] == true,
              shareNotes: grant['share_notes'] == true,
            );
          }

          _inspectingManagerUid = _activeShares.keys.first;
          _setupMemberListener(_inspectingManagerUid!, user.uid);
        } else {
          _isUnitShareActive = false;
          _shareData = null;
          _activeShares.clear();
          _isConfiguringShare = true;
          _selectedCandidate = null;
        }
      } else {
        _isUnitShareActive = false;
        _shareData = null;
        _activeShares.clear();
        _isConfiguringShare = true;
        _selectedCandidate = null;
      }
    } catch (e) {
      debugPrint("Error loading unit share in UnitShareScreen: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _healSharedShifts({
    required String managerUid,
    required String userUid,
    required String mode,
    DateTime? activeUntil,
    required Set<String> customDates,
    required Set<String> excludedDates,
    required bool shareEntry,
    required bool shareExit,
    required bool shareRealEntry,
    required bool shareNotes,
  }) async {
    try {
      final relevantShifts = filterWorkDaysForUnitShare(
        _userWorkDays,
        mode: mode,
        activeUntil: activeUntil,
        customDates: customDates,
        excludedDates: excludedDates,
      );
      final sanitizedShifts = sanitizeWorkDaysForUnitShare(
        relevantShifts,
        shareEntry: shareEntry,
        shareExit: shareExit,
        shareRealEntry: shareRealEntry,
        shareNotes: shareNotes,
      );
      await FirebaseFirestore.instance
          .collection('unit_shares')
          .doc(managerUid)
          .collection('members')
          .doc(userUid)
          .set({
        'shifts': sanitizedShifts,
        'last_synced_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error self-healing unit share shifts: $e");
    }
  }

  void _setupMemberListener(String managerUid, String userUid) {
    _memberSubscription?.cancel();
    _memberSubscription = FirebaseFirestore.instance
        .collection('unit_shares')
        .doc(managerUid)
        .collection('members')
        .doc(userUid)
        .snapshots()
        .listen((snap) {
      if (snap.exists && snap.data() != null) {
        final data = snap.data()!;
        final rawShifts = data['shifts'] as List<dynamic>? ?? [];
        final parsedShifts =
            rawShifts.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        parsedShifts.sort((a, b) {
          final aDate = a['date']?.toString() ?? '';
          final bDate = b['date']?.toString() ?? '';
          return bDate.compareTo(aDate);
        });
        if (mounted) {
          setState(() {
            _sharedShifts = parsedShifts;
          });
        }
      }
    }, onError: (e) => debugPrint("Error listening to shared shifts: $e"));
  }

  void _onSearchChanged(String text) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 350), () {
      _searchUnitManager(text);
    });
  }

  Future<void> _searchUnitManager(String queryInput) async {
    final query = queryInput.trim();
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchResults = [];
          _searchError = null;
        });
      }
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (mounted) {
      setState(() {
        _isSearching = true;
        _searchError = null;
      });
    }

    try {
      final querySnap = await FirebaseFirestore.instance
          .collection('unit_managers')
          .get();

      if (querySnap.docs.isEmpty) {
        if (mounted) {
          setState(() {
            _isSearching = false;
            _searchResults = [];
            _searchError =
                "No hay Ingenieros de Unidad registrados en el sistema.";
          });
        }
        return;
      }

      final normalizedQuery = query.toLowerCase();

      final matchingDocs = querySnap.docs.where((doc) {
        final d = doc.data();
        final emp = (d['employee_number'] ?? d['user_emp'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
        final name = (d['name'] ?? '').toString().trim().toLowerCase();
        return emp.contains(normalizedQuery) || name.contains(normalizedQuery);
      }).toList();

      if (matchingDocs.isEmpty) {
        if (mounted) {
          setState(() {
            _isSearching = false;
            _searchResults = [];
            _searchError =
                "No se encontró ningún Ingeniero de Unidad con '$query'.";
          });
        }
        return;
      }

      final List<Map<String, dynamic>> results = [];
      for (final doc in matchingDocs) {
        final data = doc.data();
        final managerDocId = doc.id;
        final managerUid = (data['uid'] ?? managerDocId).toString().trim();

        if (currentUser != null &&
            (managerUid == currentUser.uid || managerDocId == currentUser.uid)) {
          continue;
        }

        final fullName = (data['name'] ?? 'Sin nombre').toString().trim();
        final emp = (data['employee_number'] ?? data['user_emp'] ?? '')
            .toString()
            .trim();

        results.add({
          'uid': managerUid,
          'doc_id': managerDocId,
          'name': fullName.isEmpty ? 'Sin nombre' : fullName,
          'emp': emp,
          'employee_number': emp,
          'role': data['role'] ?? 'ingeniero_de_unidad',
        });
      }

      if (results.isEmpty) {
        if (mounted) {
          setState(() {
            _isSearching = false;
            _searchResults = [];
            _searchError = "No puedes compartir datos con tu propia cuenta.";
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchError = null;
          _searchResults = results;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchResults = [];
          _searchError = "Error al buscar: $e";
        });
      }
    }
  }

  void _selectCandidate(Map<String, dynamic> candidate) {
    final uid =
        (candidate['uid'] ?? candidate['doc_id'] ?? '').toString().trim();
    final emp = (candidate['emp'] ?? candidate['employee_number'] ?? '')
        .toString()
        .trim();

    final isAlreadyShared = _activeShares.values.any((s) {
      final sUid = (s['manager_uid'] ?? s['uid'] ?? '').toString().trim();
      final sEmp = (s['manager_emp'] ?? s['emp'] ?? '').toString().trim();
      return (uid.isNotEmpty && sUid == uid) ||
          (emp.isNotEmpty && sEmp == emp);
    });

    if (isAlreadyShared) {
      final name = candidate['name'] ?? 'este supervisor';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Ya estás compartiendo asistencia con $name. Puedes editar sus permisos o revocar su acceso desde la lista de comparticiones activas."),
          backgroundColor: Colors.amber.shade800,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() {
      _selectedCandidate = candidate;
      _searchController.clear();
      _searchResults = [];
      _searchError = null;
      _isSearching = false;
      _selectedMode = 'Esta Semana';
      _shareEntry = true;
      _shareExit = true;
      _shareRealEntry = false;
      _shareNotes = true;
      _customDates = {};
      _excludedDates = {};
    });
  }

  void _removeSelectedCandidate() {
    setState(() {
      _selectedCandidate = null;
      _searchController.clear();
      _searchResults = [];
      _searchError = null;
    });
  }

  DateTime? _calculateActiveUntil(String mode, [DateTime? fromDate]) {
    final now = fromDate ?? DateTime.now();
    switch (mode) {
      case 'Solo Hoy':
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
      case 'Esta Semana':
        final sunday = now.add(Duration(days: 7 - now.weekday));
        return DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);
      case 'Esta Semana y la Pasada':
        final sunday = now.add(Duration(days: 7 - now.weekday));
        return DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);
      case 'Este Mes':
        final lastDay = DateTime(now.year, now.month + 1, 0);
        return DateTime(lastDay.year, lastDay.month, lastDay.day, 23, 59, 59);
      case 'Este Año':
        return DateTime(now.year, 12, 31, 23, 59, 59);
      case 'Todos Mis Registros':
      case 'Yo Decido':
      default:
        return null; // Unlimited vigencia (sin fecha límite)
    }
  }

  String _formatCountdown(DateTime? activeUntil) {
    if (activeUntil == null) return "Vigencia: Ilimitada";
    final now = DateTime.now();
    final diff = activeUntil.difference(now);
    if (diff.isNegative) return "Expirado";
    if (diff.inDays > 0) {
      final hours = diff.inHours % 24;
      return "${diff.inDays}d ${hours}h restantes";
    } else if (diff.inHours > 0) {
      final mins = diff.inMinutes % 60;
      return "${diff.inHours}h ${mins}m restantes";
    } else {
      return "${diff.inMinutes} min restantes";
    }
  }

  String _formatDayNameAndDate(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      const dayNames = [
        'Lunes',
        'Martes',
        'Miércoles',
        'Jueves',
        'Viernes',
        'Sábado',
        'Domingo'
      ];
      const monthNames = [
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
      final dayName = dayNames[parsed.weekday - 1];
      final monthName = monthNames[parsed.month - 1];
      return "$dayName, ${parsed.day} $monthName ${parsed.year}";
    } catch (_) {
      return dateStr;
    }
  }

  String _getModeDescription(String mode) {
    switch (mode) {
      case 'Solo Hoy':
        return "Se compartirán exclusivamente los registros de hoy. Vigencia: 24 horas.";
      case 'Esta Semana':
        return "Se compartirán los turnos de lunes a domingo de la semana en curso. (Recomendado)";
      case 'Esta Semana y la Pasada':
        return "Se compartirán los registros de los últimos 14 días (semana en curso y anterior).";
      case 'Este Mes':
        return "Se compartirán todos los registros del mes actual completo.";
      case 'Este Año':
        return "Se compartirán los registros del año calendario en curso.";
      case 'Todos Mis Registros':
        return "Se compartirán todos tus registros históricos acumulados en la app. Vigencia: Ilimitada.";
      case 'Yo Decido':
        return "Tú decides qué turnos compartir o excluir individualmente en la lista activa. Vigencia: Ilimitada.";
      default:
        return "";
    }
  }

  Future<bool> _showConfirmUnitManagerDialog({
    required Map<String, dynamic> manager,
  }) async {
    final mName = (manager['name'] ?? 'Ingeniero de Unidad').toString();
    final mEmp =
        (manager['emp'] ?? manager['employee_number'] ?? '').toString();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.shield_rounded,
              color: widget.isDarkMode
                  ? Colors.cyanAccent
                  : const Color(0xFF0284C7),
              size: 26,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "¿Confirmar Ingeniero de Unidad?",
                style: TextStyle(
                  color: widget.isDarkMode
                      ? Colors.white
                      : const Color(0xFF0F172A),
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
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
              "Estás a punto de conceder acceso a tus horarios y registros de asistencia al siguiente supervisor:",
              style: TextStyle(
                color: widget.isDarkMode
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF1E293B),
                fontSize: 13,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.isDarkMode
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: widget.isDarkMode
                    ? Colors.cyanAccent.withAlpha(60)
                    : const Color(0xFFBAE6FD),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: widget.isDarkMode
                        ? Colors.cyanAccent.withAlpha(40)
                        : const Color(0xFF0284C7).withAlpha(30),
                    child: Text(
                      mName.isNotEmpty
                          ? mName.substring(0, 1).toUpperCase()
                          : 'I',
                      style: TextStyle(
                        color: widget.isDarkMode
                            ? Colors.cyanAccent
                            : const Color(0xFF0284C7),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mName,
                          style: TextStyle(
                            color: widget.isDarkMode
                                ? Colors.white
                                : const Color(0xFF0F172A),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (mEmp.isNotEmpty)
                          Text(
                            "No. Empleado: $mEmp",
                            style: TextStyle(
                              color: widget.isDarkMode
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF1E293B),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Tus datos de sueldo, costo por hora y totales de nómina NUNCA se comparten.",
              style: TextStyle(
                color: widget.isDarkMode
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF1E293B),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              "CANCELAR",
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white60 : const Color(0xFF1E293B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isDarkMode
                  ? Colors.orangeAccent
                  : const Color(0xFFEA580C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "CONFIRMAR Y COMPARTIR",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Map<String, dynamic> _encodeSharesForCache(Map<String, dynamic> doc) {
    return sanitizeUnitShareMapForCache(doc);
  }

  Future<void> _saveShareInstance({bool isUpdating = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Debes iniciar sesión para compartir datos."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final mgr = _selectedCandidate;
    if (mgr == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor selecciona a un Ingeniero de Unidad."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (!isUpdating) {
      final confirmed = await _showConfirmUnitManagerDialog(manager: mgr);
      if (!confirmed) return;
    }

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final activeUntil = _calculateActiveUntil(_selectedMode, now);
      final retentionUntil = activeUntil?.add(const Duration(days: 14));

      final mgrUid = (mgr['uid'] ?? '').toString().trim();
      final mgrDocId = (mgr['doc_id'] ?? '').toString().trim();
      final mgrName = (mgr['name'] ?? 'Ingeniero de Unidad').toString().trim();
      final mgrEmp =
          (mgr['emp'] ?? mgr['employee_number'] ?? '').toString().trim();
      final targetKey = mgrUid.isNotEmpty
          ? mgrUid
          : (mgrDocId.isNotEmpty ? mgrDocId : mgrEmp);

      final existingGrant = _activeShares[targetKey];
      final customDates = _customDates.isNotEmpty
          ? _customDates
          : parseUnitShareStringSet(existingGrant?['custom_dates']);

      final List<WorkDay> relevantShifts = filterWorkDaysForUnitShare(
        _userWorkDays,
        mode: _selectedMode,
        activeUntil: activeUntil,
        customDates: customDates,
        excludedDates: _excludedDates,
        now: now,
      );

      Timestamp? lastClockOut;
      final completed =
          _userWorkDays.where((d) => !d.isInProgress && !d.esFalta).toList();
      if (completed.isNotEmpty) {
        completed.sort((a, b) => b.salida.compareTo(a.salida));
        lastClockOut = Timestamp.fromDate(completed.first.salida);
      }

      final List<Map<String, dynamic>> sanitizedShifts =
          sanitizeWorkDaysForUnitShare(
        relevantShifts,
        shareEntry: _shareEntry,
        shareExit: _shareExit,
        shareRealEntry: _shareRealEntry,
        shareNotes: _shareNotes,
      );

      final shareGrant = {
        'manager_uid': mgrUid,
        'manager_doc_id': mgrDocId,
        'manager_name': mgrName,
        'manager_emp': mgrEmp,
        'mode': _selectedMode,
        'duration': _selectedMode,
        'timeframe': _selectedMode,
        'active_sharing_until':
            activeUntil != null ? Timestamp.fromDate(activeUntil) : null,
        'data_retention_until': retentionUntil != null
            ? Timestamp.fromDate(retentionUntil)
            : null,
        'share_real_entry': _shareRealEntry,
        'share_entry': _shareEntry,
        'share_exit': _shareExit,
        'share_notes': _shareNotes,
        'excluded_dates': _excludedDates.toList(),
        'custom_dates': customDates.toList(),
        'is_active': true,
        'created_at': (existingGrant != null &&
                existingGrant['created_at'] != null &&
                existingGrant['created_at'] is! FieldValue)
            ? existingGrant['created_at']
            : Timestamp.fromDate(now),
        'updated_at': Timestamp.fromDate(now),
      };

      final Map<String, Map<String, dynamic>> rawUpdatedShares =
          Map.from(_activeShares);
      rawUpdatedShares[targetKey] = shareGrant;
      final Map<String, Map<String, dynamic>> updatedShares =
          sanitizeSharesMapForFirestore(rawUpdatedShares);

      final primaryGrant = updatedShares.values.first;
      final String primaryUid =
          (primaryGrant['manager_uid'] ?? '').toString().trim();
      final String primaryDocId =
          (primaryGrant['manager_doc_id'] ?? '').toString().trim();
      final String primaryName =
          (primaryGrant['manager_name'] ?? 'Ingeniero de Unidad')
              .toString()
              .trim();
      final String primaryEmp =
          (primaryGrant['manager_emp'] ?? '').toString().trim();

      final userSettingsDoc = {
        'shares': updatedShares,
        'managers': updatedShares.values.toList(),
        'manager_uid': primaryUid,
        'manager_doc_id': primaryDocId,
        'manager_name': primaryName,
        'manager_emp': primaryEmp,
        'is_active': true,
        'mode': primaryGrant['mode'] ?? _selectedMode,
        'duration': primaryGrant['mode'] ?? _selectedMode,
        'timeframe': primaryGrant['mode'] ?? _selectedMode,
        'active_sharing_until': primaryGrant['active_sharing_until'],
        'data_retention_until': primaryGrant['data_retention_until'],
        'share_real_entry': primaryGrant['share_real_entry'] ?? false,
        'share_entry': primaryGrant['share_entry'] ?? true,
        'share_exit': primaryGrant['share_exit'] ?? true,
        'share_notes': primaryGrant['share_notes'] ?? false,
        'excluded_dates': primaryGrant['excluded_dates'] ?? [],
        'custom_dates': primaryGrant['custom_dates'] ?? [],
        'updated_at': FieldValue.serverTimestamp(),
      };

      final memberPayload = {
        'member_uid': user.uid,
        'member_name': _userName.isNotEmpty
            ? _userName
            : (user.displayName ?? 'Sin nombre'),
        'member_emp': _userEmp,
        'member_email': user.email ?? '',
        'is_active': true,
        'mode': _selectedMode,
        'duration': _selectedMode,
        'timeframe': _selectedMode,
        'active_sharing_until':
            activeUntil != null ? Timestamp.fromDate(activeUntil) : null,
        'data_retention_until': retentionUntil != null
            ? Timestamp.fromDate(retentionUntil)
            : null,
        'share_real_entry': _shareRealEntry,
        'share_entry': _shareEntry,
        'share_exit': _shareExit,
        'share_notes': _shareNotes,
        'custom_dates': customDates.toList(),
        'shifts': sanitizedShifts,
        'last_clock_out': lastClockOut,
        'last_synced_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      final batch = FirebaseFirestore.instance.batch();
      batch.set(
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('settings')
            .doc('unit_share'),
        userSettingsDoc,
        SetOptions(merge: true),
      );

      if (mgrUid.isNotEmpty) {
        batch.set(
          FirebaseFirestore.instance
              .collection('unit_shares')
              .doc(mgrUid)
              .collection('members')
              .doc(user.uid),
          memberPayload,
          SetOptions(merge: true),
        );
      }
      if (mgrDocId.isNotEmpty && mgrDocId != mgrUid) {
        batch.set(
          FirebaseFirestore.instance
              .collection('unit_shares')
              .doc(mgrDocId)
              .collection('members')
              .doc(user.uid),
          memberPayload,
          SetOptions(merge: true),
        );
      }
      if (mgrEmp.isNotEmpty && mgrEmp != mgrUid && mgrEmp != mgrDocId) {
        batch.set(
          FirebaseFirestore.instance
              .collection('unit_shares')
              .doc(mgrEmp)
              .collection('members')
              .doc(user.uid),
          memberPayload,
          SetOptions(merge: true),
        );
      }

      await batch.commit();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'active_unit_share_cache_${user.uid}',
        jsonEncode(_encodeSharesForCache(userSettingsDoc)),
      );

      if (mounted) {
        setState(() {
          _isSaving = false;
          _isUnitShareActive = true;
          _isConfiguringShare = false;
          _editingManagerUid = null;
          _selectedCandidate = null;
          _activeShares = updatedShares;
          _shareData = _encodeSharesForCache(userSettingsDoc);
          _inspectingManagerUid = targetKey;
          _sharedShifts = sanitizedShifts;
        });

        if (mgrUid.isNotEmpty) {
          _setupMemberListener(mgrUid, user.uid);
        }

        final String successMessage = isUpdating
            ? "Permisos actualizados con éxito."
            : "Compartiendo asistencia con $mgrName.";

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al guardar configuración: $e"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _startEditingShare(String mgrKey) {
    final grant = _activeShares[mgrKey];
    if (grant == null) return;

    final mUid = (grant['manager_uid'] ?? mgrKey).toString();
    final mDocId = (grant['manager_doc_id'] ?? '').toString();
    final mName = (grant['manager_name'] ?? 'Ingeniero de Unidad').toString();
    final mEmp = (grant['manager_emp'] ?? '').toString();

    setState(() {
      _editingManagerUid = mgrKey;
      _selectedCandidate = {
        'uid': mUid,
        'doc_id': mDocId,
        'name': mName,
        'emp': mEmp,
        'employee_number': mEmp,
      };
      _selectedMode =
          (grant['mode'] ?? grant['duration'] ?? 'Esta Semana').toString();
      _shareEntry = grant['share_entry'] ?? true;
      _shareExit = grant['share_exit'] ?? true;
      _shareRealEntry = grant['share_real_entry'] == true;
      _shareNotes = grant['share_notes'] == true;
      _customDates = parseUnitShareStringSet(grant['custom_dates']);
      _excludedDates = parseUnitShareStringSet(grant['excluded_dates']);
      _isConfiguringShare = true;
      _searchController.clear();
      _searchResults = [];
      _searchError = null;
    });
  }

  void _startNewShare() {
    setState(() {
      _editingManagerUid = null;
      _selectedCandidate = null;
      _isConfiguringShare = true;
      _selectedMode = 'Esta Semana';
      _shareEntry = true;
      _shareExit = true;
      _shareRealEntry = false;
      _shareNotes = true;
      _customDates = {};
      _excludedDates = {};
      _searchController.clear();
      _searchResults = [];
      _searchError = null;
    });
  }

  void _cancelConfiguringShare() {
    setState(() {
      _isConfiguringShare = false;
      _editingManagerUid = null;
      _selectedCandidate = null;
      _searchController.clear();
      _searchResults = [];
      _searchError = null;
    });
  }

  Future<void> _confirmRevokeSingleShare(String mgrKey) async {
    final grant = _activeShares[mgrKey];
    final mgrName =
        (grant?['manager_name'] ?? 'el Ingeniero de Unidad').toString();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.person_remove_rounded,
                color: Colors.redAccent, size: 26),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "¿Dejar de compartir con este ingeniero?",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          "¿Estás seguro de que deseas revocar el acceso de $mgrName a tus registros de asistencia? Dejará de ver tus horarios inmediatamente.",
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white70 : const Color(0xFF475569),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              "CANCELAR",
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white60 : const Color(0xFF1E293B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "REVOCAR ACCESO",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _revokeSingleShare(mgrKey);
    }
  }

  Future<void> _revokeSingleShare(String mgrKey) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final grant = _activeShares[mgrKey];
    final mgrName =
        (grant?['manager_name'] ?? 'el Ingeniero de Unidad').toString();
    final mUid = (grant?['manager_uid'] ?? mgrKey).toString().trim();
    final mDocId = (grant?['manager_doc_id'] ?? '').toString().trim();
    final mEmp = (grant?['manager_emp'] ?? '').toString().trim();

    setState(() => _isSaving = true);

    try {
      final batch = FirebaseFirestore.instance.batch();

      if (mUid.isNotEmpty) {
        batch.delete(FirebaseFirestore.instance
            .collection('unit_shares')
            .doc(mUid)
            .collection('members')
            .doc(user.uid));
      }
      if (mDocId.isNotEmpty && mDocId != mUid) {
        batch.delete(FirebaseFirestore.instance
            .collection('unit_shares')
            .doc(mDocId)
            .collection('members')
            .doc(user.uid));
      }
      if (mEmp.isNotEmpty && mEmp != mUid && mEmp != mDocId) {
        batch.delete(FirebaseFirestore.instance
            .collection('unit_shares')
            .doc(mEmp)
            .collection('members')
            .doc(user.uid));
      }

      final Map<String, Map<String, dynamic>> rawUpdatedShares =
          Map.from(_activeShares);
      rawUpdatedShares.remove(mgrKey);
      final Map<String, Map<String, dynamic>> updatedShares =
          sanitizeSharesMapForFirestore(rawUpdatedShares);

      final prefs = await SharedPreferences.getInstance();

      if (updatedShares.isEmpty) {
        batch.delete(FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('settings')
            .doc('unit_share'));
        await batch.commit();

        await prefs.remove('active_unit_share_cache_${user.uid}');
        _memberSubscription?.cancel();

        if (mounted) {
          setState(() {
            _isSaving = false;
            _isUnitShareActive = false;
            _activeShares = {};
            _shareData = null;
            _isConfiguringShare = false;
            _editingManagerUid = null;
            _selectedCandidate = null;
            _inspectingManagerUid = null;
            _sharedShifts = [];
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Se ha dejado de compartir datos con $mgrName."),
              backgroundColor: Colors.amber.shade800,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        final primaryGrant = updatedShares.values.first;
        final String primaryUid =
            (primaryGrant['manager_uid'] ?? '').toString().trim();
        final String primaryDocId =
            (primaryGrant['manager_doc_id'] ?? '').toString().trim();
        final String primaryName =
            (primaryGrant['manager_name'] ?? 'Ingeniero de Unidad')
                .toString()
                .trim();
        final String primaryEmp =
            (primaryGrant['manager_emp'] ?? '').toString().trim();

        final updatedDoc = {
          'shares': updatedShares,
          'managers': updatedShares.values.toList(),
          'manager_uid': primaryUid,
          'manager_doc_id': primaryDocId,
          'manager_name': primaryName,
          'manager_emp': primaryEmp,
          'is_active': true,
          'mode': primaryGrant['mode'] ?? 'Esta Semana',
          'duration': primaryGrant['mode'] ?? 'Esta Semana',
          'timeframe': primaryGrant['mode'] ?? 'Esta Semana',
          'active_sharing_until': primaryGrant['active_sharing_until'],
          'data_retention_until': primaryGrant['data_retention_until'],
          'share_real_entry': primaryGrant['share_real_entry'] ?? false,
          'share_entry': primaryGrant['share_entry'] ?? true,
          'share_exit': primaryGrant['share_exit'] ?? true,
          'share_notes': primaryGrant['share_notes'] ?? false,
          'excluded_dates': primaryGrant['excluded_dates'] ?? [],
          'custom_dates': primaryGrant['custom_dates'] ?? [],
          'updated_at': FieldValue.serverTimestamp(),
        };

        batch.set(
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('settings')
              .doc('unit_share'),
          updatedDoc,
          SetOptions(merge: true),
        );

        await batch.commit();

        await prefs.setString(
          'active_unit_share_cache_${user.uid}',
          jsonEncode(_encodeSharesForCache(updatedDoc)),
        );

        final nextInspectingUid =
            updatedShares.containsKey(_inspectingManagerUid)
                ? _inspectingManagerUid
                : updatedShares.keys.first;

        if (mounted) {
          setState(() {
            _isSaving = false;
            _activeShares = updatedShares;
            _shareData = _encodeSharesForCache(updatedDoc);
            _inspectingManagerUid = nextInspectingUid;
          });

          if (nextInspectingUid != null && nextInspectingUid.isNotEmpty) {
            _setupMemberListener(nextInspectingUid, user.uid);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Se ha dejado de compartir datos con $mgrName."),
              backgroundColor: Colors.amber.shade800,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al revocar acceso: $e"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmRevokeAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.link_off_rounded, color: Colors.redAccent, size: 26),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "¿Dejar de compartir todos los registros?",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          "¿Estás seguro de que deseas revocar el acceso a todos los Ingenieros de Unidad? Dejarán de ver tus horarios inmediatamente.",
          style: TextStyle(
            color: widget.isDarkMode
                ? Colors.white70
                : const Color(0xFF475569),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              "CANCELAR",
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white60 : const Color(0xFF1E293B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "DEJAR DE COMPARTIR",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final Set<String> targetUids = {};
    for (final grant in _activeShares.values) {
      final u = (grant['manager_uid'] ?? '').toString().trim();
      final d = (grant['manager_doc_id'] ?? '').toString().trim();
      final e = (grant['manager_emp'] ?? '').toString().trim();
      if (u.isNotEmpty) targetUids.add(u);
      if (d.isNotEmpty) targetUids.add(d);
      if (e.isNotEmpty) targetUids.add(e);
    }
    final legacyUid =
        (_shareData?['manager_uid'] ?? _shareData?['uid'] ?? '').toString().trim();
    if (legacyUid.isNotEmpty) targetUids.add(legacyUid);

    try {
      final batch = FirebaseFirestore.instance.batch();
      batch.delete(
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('settings')
            .doc('unit_share'),
      );

      for (final tUid in targetUids) {
        batch.delete(
          FirebaseFirestore.instance
              .collection('unit_shares')
              .doc(tUid)
              .collection('members')
              .doc(user.uid),
        );
      }

      await batch.commit();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('active_unit_share_cache_${user.uid}');

      _memberSubscription?.cancel();

      if (mounted) {
        setState(() {
          _isUnitShareActive = false;
          _activeShares = {};
          _shareData = null;
          _isConfiguringShare = false;
          _editingManagerUid = null;
          _selectedCandidate = null;
          _sharedShifts = [];
          _inspectingManagerUid = null;
          _searchController.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                "Se ha dejado de compartir datos con todos los supervisores."),
            backgroundColor: Colors.amber.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al revocar compartición: $e"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _removeSharedDate(Map<String, dynamic> shift) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _activeShares.isEmpty) return;

    final String targetDate = (shift['date'] ?? '').toString();
    final String targetId = (shift['id'] ?? '').toString();
    if (targetDate.isEmpty && targetId.isEmpty) return;

    final dateKey = targetDate.isNotEmpty ? targetDate : targetId;
    final mgrKey = _inspectingManagerUid ?? _activeShares.keys.first;
    final grant = _activeShares[mgrKey];
    if (grant == null) return;

    final mUid = (grant['manager_uid'] ?? mgrKey).toString().trim();
    final mDocId = (grant['manager_doc_id'] ?? '').toString().trim();
    final mEmp = (grant['manager_emp'] ?? '').toString().trim();

    try {
      final updatedShifts = _sharedShifts.where((s) {
        final sDate = (s['date'] ?? '').toString();
        final sId = (s['id'] ?? '').toString();
        if (targetId.isNotEmpty && sId == targetId) return false;
        if (targetDate.isNotEmpty && sDate == targetDate) return false;
        return true;
      }).toList();

      final currentExcluded = parseUnitShareStringSet(grant['excluded_dates']);
      currentExcluded.add(dateKey);

      final updatedGrant = Map<String, dynamic>.from(grant);
      updatedGrant['excluded_dates'] = currentExcluded.toList();
      updatedGrant['updated_at'] = Timestamp.fromDate(DateTime.now());

      final Map<String, Map<String, dynamic>> rawUpdatedShares =
          Map.from(_activeShares);
      rawUpdatedShares[mgrKey] = updatedGrant;
      final Map<String, Map<String, dynamic>> updatedShares =
          sanitizeSharesMapForFirestore(rawUpdatedShares);

      final batch = FirebaseFirestore.instance.batch();

      batch.set(
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('settings')
            .doc('unit_share'),
        {
          'shares': updatedShares,
          'managers': updatedShares.values.toList(),
          'updated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      final memberTargets = {mUid, mDocId, mEmp}..removeWhere((s) => s.isEmpty);
      for (final t in memberTargets) {
        batch.update(
          FirebaseFirestore.instance
              .collection('unit_shares')
              .doc(t)
              .collection('members')
              .doc(user.uid),
          {
            'shifts': updatedShifts,
            'last_synced_at': FieldValue.serverTimestamp(),
          },
        );
      }

      await batch.commit();

      if (mounted) {
        setState(() {
          _activeShares = updatedShares;
          _sharedShifts = updatedShifts;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Fecha ${_formatDayNameAndDate(targetDate)} excluida para ${grant['manager_name'] ?? 'el supervisor'}."),
            backgroundColor: Colors.teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al excluir fecha: $e"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _saveSpecificDaysSelection(
    String managerKey,
    String managerName,
    Set<String> selectedDateKeys,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !_activeShares.containsKey(managerKey)) return;

    final grant = _activeShares[managerKey]!;
    final mUid = (grant['manager_uid'] ?? managerKey).toString().trim();
    final mDocId = (grant['manager_doc_id'] ?? '').toString().trim();
    final mEmp = (grant['manager_emp'] ?? '').toString().trim();

    final now = DateTime.now();
    final updatedGrant = Map<String, dynamic>.from(grant);
    updatedGrant['mode'] = 'Yo Decido';
    updatedGrant['duration'] = 'Yo Decido';
    updatedGrant['custom_dates'] = selectedDateKeys.toList();
    updatedGrant['excluded_dates'] = <String>[];
    updatedGrant['active_sharing_until'] = null; // Unlimited vigencia
    updatedGrant['updated_at'] = Timestamp.fromDate(now);

    final bool shareEntry = updatedGrant['share_entry'] ?? true;
    final bool shareExit = updatedGrant['share_exit'] ?? true;
    final bool shareRealEntry = updatedGrant['share_real_entry'] == true;
    final bool shareNotes = updatedGrant['share_notes'] == true;

    final List<WorkDay> relevantShifts = filterWorkDaysForUnitShare(
      _userWorkDays,
      mode: 'Yo Decido',
      activeUntil: null,
      customDates: selectedDateKeys,
      excludedDates: {},
      now: now,
    );

    final List<Map<String, dynamic>> sanitizedShifts =
        sanitizeWorkDaysForUnitShare(
      relevantShifts,
      shareEntry: shareEntry,
      shareExit: shareExit,
      shareRealEntry: shareRealEntry,
      shareNotes: shareNotes,
    );

    final Map<String, Map<String, dynamic>> rawUpdatedShares =
        Map.from(_activeShares);
    rawUpdatedShares[managerKey] = updatedGrant;
    final Map<String, Map<String, dynamic>> updatedShares =
        sanitizeSharesMapForFirestore(rawUpdatedShares);

    try {
      final batch = FirebaseFirestore.instance.batch();
      batch.set(
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('settings')
            .doc('unit_share'),
        {
          'shares': updatedShares,
          'managers': updatedShares.values.toList(),
          'updated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      final memberTargets = {mUid, mDocId, mEmp}..removeWhere((s) => s.isEmpty);
      for (final t in memberTargets) {
        batch.set(
          FirebaseFirestore.instance
              .collection('unit_shares')
              .doc(t)
              .collection('members')
              .doc(user.uid),
          {
            'shifts': sanitizedShifts,
            'active_sharing_until': null,
            'mode': 'Yo Decido',
            'last_synced_at': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();

      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'active_unit_share_cache_${user.uid}';
      final cachedStr = prefs.getString(cacheKey);
      if (cachedStr != null) {
        try {
          final Map<String, dynamic> c = jsonDecode(cachedStr);
          c['shares'] = _encodeSharesForCache(updatedShares);
          c['managers'] = c['shares'].values.toList();
          await prefs.setString(cacheKey, jsonEncode(c));
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _activeShares = updatedShares;
          if (_inspectingManagerUid == managerKey ||
              _inspectingManagerUid == null) {
            _sharedShifts = sanitizedShifts;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Se guardaron ${selectedDateKeys.length} fechas específicas para $managerName.",
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al guardar días específicos: $e"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  int _getWeekNumber(DateTime date) {
    if (date.year == 2027 && date.month == 1 && date.day <= 3) {
      return 53;
    }
    int dayOfYear = int.parse(DateFormat("D").format(date));
    int week = ((dayOfYear - date.weekday + 10) / 7).floor();
    if (week == 0) {
      DateTime prevYearEnd = DateTime(date.year - 1, 12, 31);
      int prevDayOfYear = int.parse(DateFormat("D").format(prevYearEnd));
      return ((prevDayOfYear - prevYearEnd.weekday + 10) / 7).floor();
    }
    return week;
  }

  Future<void> _openSpecificDaysPicker(
    String managerKey,
    String managerName,
  ) async {
    final now = DateTime.now();
    final DateTime currentMonday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    final Set<DateTime> mondaySet = {};
    for (int i = 0; i < 8; i++) {
      mondaySet.add(currentMonday.subtract(Duration(days: i * 7)));
    }
    for (final day in _userWorkDays) {
      final m = DateTime(day.entrada.year, day.entrada.month, day.entrada.day)
          .subtract(Duration(days: day.entrada.weekday - 1));
      mondaySet.add(m);
    }
    final List<DateTime> sortedMondays = mondaySet.toList()
      ..sort((a, b) => b.compareTo(a));

    final Set<String> loggedShiftDays = {};
    for (final day in _userWorkDays) {
      loggedShiftDays.add(DateFormat('yyyy-MM-dd').format(day.entrada));
    }

    final grant = _activeShares[managerKey];
    final Set<String> tempSelected = {};
    if (grant != null) {
      final custom = parseUnitShareStringSet(grant['custom_dates']);
      final excluded = parseUnitShareStringSet(grant['excluded_dates']);
      final mode = (grant['mode'] ?? grant['duration'] ?? '').toString();

      if (mode == 'Yo Decido' && custom.isNotEmpty) {
        tempSelected.addAll(custom);
      } else {
        for (final s in _sharedShifts) {
          final d = (s['date'] ?? '').toString();
          if (d.isNotEmpty && !excluded.contains(d)) {
            tempSelected.add(d);
          }
        }
      }
    }

    final isDark = widget.isDarkMode;
    final Color unitColor =
        isDark ? Colors.cyanAccent : const Color(0xFF0284C7);
    final Color cardBg =
        isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color itemBg =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final Color borderColor =
        isDark ? Colors.white12 : const Color(0xFFCBD5E1);
    final Color textColor =
        isDark ? Colors.white : Colors.black;
    final Color subtextColor =
        isDark ? Colors.white60 : const Color(0xFF1E293B);

    final weekdayNames = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setPickerState) {
            return Dialog(
              backgroundColor: cardBg,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: borderColor),
              ),
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: 520, maxHeight: 680),
                child: Padding(
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
                              color: unitColor.withAlpha(isDark ? 40 : 25),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.calendar_month_rounded,
                              color: unitColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Compartir días específicos",
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Para: $managerName",
                                  style: TextStyle(
                                    color: subtextColor,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            color: subtextColor,
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Quick Selection Bar
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: itemBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${tempSelected.length} días seleccionados",
                              style: TextStyle(
                                color: textColor,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (tempSelected.isNotEmpty)
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  setPickerState(() {
                                    tempSelected.clear();
                                  });
                                },
                                child: Text(
                                  "Limpiar todo",
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.redAccent
                                        : const Color(0xFFDC2626),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Weeks list
                      Expanded(
                        child: ListView.builder(
                          itemCount: sortedMondays.length,
                          itemBuilder: (listCtx, idx) {
                            final monday = sortedMondays[idx];
                            final weekDays = List.generate(
                                7, (i) => monday.add(Duration(days: i)));
                            final weekDateKeys = weekDays
                                .map((d) => DateFormat('yyyy-MM-dd').format(d))
                                .toList();
                            final int selectedInWeek = weekDateKeys
                                .where((k) => tempSelected.contains(k))
                                .length;
                            final bool allSelected = selectedInWeek == 7;
                            final bool someSelected =
                                selectedInWeek > 0 && !allSelected;

                            final weekNum = _getWeekNumber(monday);
                            final weekLabel =
                                "Semana $weekNum (${DateFormat('d MMM', 'es').format(monday)} - ${DateFormat('d MMM', 'es').format(weekDays.last)})";

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: itemBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selectedInWeek > 0
                                      ? unitColor.withAlpha(isDark ? 80 : 100)
                                      : borderColor,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Week toggle header
                                  InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () {
                                      setPickerState(() {
                                        if (allSelected) {
                                          tempSelected.removeAll(weekDateKeys);
                                        } else {
                                          tempSelected.addAll(weekDateKeys);
                                        }
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: Checkbox(
                                              value: allSelected
                                                  ? true
                                                  : (someSelected
                                                      ? null
                                                      : false),
                                              tristate: true,
                                              activeColor: unitColor,
                                              checkColor: isDark
                                                  ? Colors.black
                                                  : Colors.white,
                                              onChanged: (val) {
                                                setPickerState(() {
                                                  if (allSelected) {
                                                    tempSelected
                                                        .removeAll(weekDateKeys);
                                                  } else {
                                                    tempSelected
                                                        .addAll(weekDateKeys);
                                                  }
                                                });
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              weekLabel,
                                              style: TextStyle(
                                                color: textColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12.5,
                                              ),
                                            ),
                                          ),
                                          if (selectedInWeek > 0)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: unitColor.withAlpha(
                                                    isDark ? 35 : 20),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                "$selectedInWeek/7",
                                                style: TextStyle(
                                                  color: unitColor,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Day cells row (L - D)
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children:
                                        List.generate(7, (dayIdx) {
                                      final dayDate = weekDays[dayIdx];
                                      final dayKey = weekDateKeys[dayIdx];
                                      final isSelected =
                                          tempSelected.contains(dayKey);
                                      final hasShift =
                                          loggedShiftDays.contains(dayKey);

                                      return Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 2),
                                          child: InkWell(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            onTap: () {
                                              setPickerState(() {
                                                if (isSelected) {
                                                  tempSelected.remove(dayKey);
                                                } else {
                                                  tempSelected.add(dayKey);
                                                }
                                              });
                                            },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 6),
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? unitColor.withAlpha(
                                                        isDark ? 45 : 30)
                                                    : (isDark
                                                        ? Colors.white.withAlpha(8)
                                                        : Colors.white),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: isSelected
                                                      ? unitColor
                                                      : borderColor,
                                                  width: isSelected ? 1.5 : 1.0,
                                                ),
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    weekdayNames[dayIdx],
                                                    style: TextStyle(
                                                      color: isSelected
                                                          ? unitColor
                                                          : subtextColor,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    "${dayDate.day}",
                                                    style: TextStyle(
                                                      color: isSelected
                                                          ? (isDark
                                                              ? Colors.white
                                                              : Colors.black)
                                                          : textColor,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          isSelected || hasShift
                                                              ? FontWeight.bold
                                                              : FontWeight
                                                                  .normal,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Container(
                                                    width: 4,
                                                    height: 4,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: hasShift
                                                          ? Colors.greenAccent
                                                          : Colors.transparent,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Footer Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(
                                    color: isDark
                                        ? Colors.white24
                                        : const Color(0xFFCBD5E1)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(
                                "Cancelar",
                                style: TextStyle(
                                  color: subtextColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: unitColor,
                                foregroundColor:
                                    isDark ? Colors.black : Colors.white,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.check_rounded, size: 18),
                              label: Text(
                                "Guardar (${tempSelected.length} días)",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              onPressed: () async {
                                Navigator.pop(ctx);
                                await _saveSpecificDaysSelection(
                                  managerKey,
                                  managerName,
                                  tempSelected,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final Color unitColor =
        isDark ? Colors.cyanAccent : const Color(0xFF0284C7);
    final Color accentColor =
        isDark ? Colors.orange : const Color(0xFFC2410C);
    final Color cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color borderColor =
        isDark ? Colors.white12 : const Color(0xFFCBD5E1);
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subtextColor =
        isDark ? Colors.white54 : const Color(0xFF1E293B);

    final bool showActiveDashboard =
        (_activeShares.isNotEmpty || _isUnitShareActive) && !_isConfiguringShare;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          showActiveDashboard
              ? "Compartir con Ingeniero"
              : (_editingManagerUid != null
                  ? "Editar Compartición"
                  : "Compartir con Ingeniero"),
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: cardBg,
        leading: BackButton(
          color: textColor,
          onPressed: () {
            if (_isConfiguringShare && _activeShares.isNotEmpty) {
              _cancelConfiguringShare();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        elevation: 0.5,
        actions: [
          if (showActiveDashboard)
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: textColor),
              tooltip: "Actualizar",
              onPressed: _loadInitialData,
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: unitColor),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showActiveDashboard) ...[
                    // Active Manager Cards List & Management
                    _buildActiveSharesView(
                      unitColor,
                      textColor,
                      subtextColor,
                      cardBg,
                      borderColor,
                    ),
                    const SizedBox(height: 24),

                    // Active Shared Dates Manager with Manager Switcher
                    _buildActiveSharedDatesManager(
                      unitColor,
                      textColor,
                      subtextColor,
                      cardBg,
                      borderColor,
                    ),
                    const SizedBox(height: 24),

                    // Global Revoke Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.link_off_rounded, size: 20),
                        label: const Text(
                          "DEJAR DE COMPARTIR TODOS LOS REGISTROS",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(
                              color: Colors.redAccent, width: 1.3),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _confirmRevokeAll,
                      ),
                    ),
                    const SizedBox(height: 30),
                  ] else ...[
                    // Privacy & Advisory Card
                    _buildPrivacyAdvisoryCard(
                        unitColor, textColor, subtextColor),
                    const SizedBox(height: 18),

                    // Form Container Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(isDark ? 30 : 10),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _buildShareForm(
                        unitColor,
                        textColor,
                        subtextColor,
                        accentColor,
                        borderColor,
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildActiveSharesView(Color unitColor, Color textColor,
      Color subtextColor, Color cardBg, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_user_rounded,
                    color: Colors.greenAccent, size: 22),
                const SizedBox(width: 8),
                Text(
                  "INGENIEROS CON ACCESO ACTIVO",
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: widget.isDarkMode
                    ? Colors.green.withAlpha(35)
                    : const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: widget.isDarkMode
                      ? Colors.green.withAlpha(90)
                      : const Color(0xFF16A34A),
                  width: 1.5,
                ),
              ),
              child: Text(
                "${_activeShares.length} ${_activeShares.length == 1 ? 'activo' : 'activos'}",
                style: TextStyle(
                  color: widget.isDarkMode
                      ? Colors.greenAccent
                      : const Color(0xFF15803D),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          "Cada ingeniero cuenta con vigencia y permisos independientes. Puedes editar o revocar el acceso de cada uno por separado.",
          style: TextStyle(color: subtextColor, fontSize: 12),
        ),
        const SizedBox(height: 14),

        // List of Active Share Cards
        ..._activeShares.entries.map((entry) {
          final mgrKey = entry.key;
          final grant = entry.value;
          final mName =
              (grant['manager_name'] ?? 'Ingeniero de Unidad').toString();
          final mEmp = (grant['manager_emp'] ?? '').toString();
          final mode = (grant['mode'] ?? 'Esta Semana').toString();
          final activeUntil = parseUnitShareDate(grant['active_sharing_until']);
          final bool isUnlimited = activeUntil == null ||
              mode == 'Yo Decido' ||
              mode == 'Todos Mis Registros';
          final countdown = _formatCountdown(isUnlimited ? null : activeUntil);

          final bool shareEntry = grant['share_entry'] ?? true;
          final bool shareExit = grant['share_exit'] ?? true;
          final bool shareRealEntry = grant['share_real_entry'] == true;
          final bool shareNotes = grant['share_notes'] == true;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.isDarkMode
                    ? unitColor.withAlpha(70)
                    : const Color(0xFFCBD5E1),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(widget.isDarkMode ? 30 : 10),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Avatar + Name & Emp
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: unitColor.withAlpha(40),
                      child: Text(
                        mName.isNotEmpty ? mName.substring(0, 1).toUpperCase() : 'I',
                        style: TextStyle(
                          color: unitColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mName,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                "Ingeniero de Unidad",
                                style: TextStyle(color: subtextColor, fontSize: 12),
                              ),
                              if (mEmp.isNotEmpty) ...[
                                Text(" • ",
                                    style: TextStyle(
                                        color: subtextColor, fontSize: 12)),
                                Text(
                                  "No. $mEmp",
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  color: widget.isDarkMode
                      ? Colors.white10
                      : const Color(0xFFCBD5E1),
                ),
                const SizedBox(height: 10),

                // Badges: Mode & Vigencia
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildActiveBadge(
                      mode,
                      Icons.schedule_rounded,
                      unitColor,
                    ),
                    _buildActiveBadge(
                      countdown,
                      isUnlimited
                          ? Icons.all_inclusive_rounded
                          : Icons.timer_outlined,
                      isUnlimited ? Colors.greenAccent : Colors.orangeAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Permissions Chips
                Text(
                  "Datos visibles:",
                  style: TextStyle(
                    color: subtextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (shareEntry)
                      _buildChipBadge("Entrada", Icons.login_rounded, Colors.green),
                    if (shareExit)
                      _buildChipBadge(
                          "Salida", Icons.logout_rounded, Colors.orangeAccent),
                    if (shareRealEntry)
                      _buildChipBadge("Entrada Real",
                          Icons.fingerprint_rounded, Colors.blueAccent),
                    if (shareNotes)
                      _buildChipBadge(
                          "Notas", Icons.notes_rounded, Colors.purpleAccent),
                    if (!shareEntry &&
                        !shareExit &&
                        !shareRealEntry &&
                        !shareNotes)
                      _buildChipBadge("Asistencia básica",
                          Icons.check_circle_outline, subtextColor),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  color: widget.isDarkMode
                      ? Colors.white10
                      : const Color(0xFFCBD5E1),
                ),
                const SizedBox(height: 8),

                // Action buttons: Editar & Dejar de compartir
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.tune_rounded, size: 16),
                      label: const Text(
                        "Editar",
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: widget.isDarkMode
                            ? unitColor
                            : const Color(0xFF1D4ED8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                      ),
                      onPressed: () => _startEditingShare(mgrKey),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.person_remove_outlined, size: 16),
                      label: const Text(
                        "Dejar de compartir",
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: widget.isDarkMode
                            ? Colors.redAccent
                            : const Color(0xFFDC2626),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                      ),
                      onPressed: () => _confirmRevokeSingleShare(mgrKey),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 8),
        // Button: Compartir con otro Ingeniero
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: Icon(Icons.person_add_alt_1_rounded,
                color: widget.isDarkMode ? unitColor : const Color(0xFF0284C7),
                size: 18),
            label: Text(
              "Compartir con otro Ingeniero",
              style: TextStyle(
                color: widget.isDarkMode ? unitColor : const Color(0xFF0284C7),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: widget.isDarkMode ? unitColor : const Color(0xFF0284C7),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: _startNewShare,
          ),
        ),
      ],
    );
  }

  Widget _buildChipBadge(String label, IconData icon, Color color) {
    final bool isDark = widget.isDarkMode;
    final Color chipColor;
    final Color chipBg;
    final Color chipBorder;

    if (label == "Entrada") {
      chipColor = isDark ? Colors.greenAccent : const Color(0xFF15803D);
      chipBg = isDark ? Colors.green.withAlpha(35) : const Color(0xFFDCFCE7);
      chipBorder = isDark ? Colors.green.withAlpha(80) : const Color(0xFF16A34A);
    } else if (label == "Salida") {
      chipColor = isDark ? Colors.orangeAccent : const Color(0xFFC2410C);
      chipBg = isDark ? Colors.orangeAccent.withAlpha(35) : const Color(0xFFFFEDD5);
      chipBorder = isDark ? Colors.orangeAccent.withAlpha(80) : const Color(0xFFEA580C);
    } else if (label == "Entrada Real") {
      chipColor = isDark ? Colors.blueAccent : const Color(0xFF1D4ED8);
      chipBg = isDark ? Colors.blueAccent.withAlpha(35) : const Color(0xFFDBEAFE);
      chipBorder = isDark ? Colors.blueAccent.withAlpha(80) : const Color(0xFF2563EB);
    } else if (label == "Notas") {
      chipColor = isDark ? Colors.purpleAccent : const Color(0xFF7E22CE);
      chipBg = isDark ? Colors.purpleAccent.withAlpha(35) : const Color(0xFFF3E8FF);
      chipBorder = isDark ? Colors.purpleAccent.withAlpha(80) : const Color(0xFFA855F7);
    } else {
      chipColor = isDark ? color : const Color(0xFF1E293B);
      chipBg = isDark ? color.withAlpha(35) : const Color(0xFFF1F5F9);
      chipBorder = isDark ? color.withAlpha(80) : const Color(0xFFCBD5E1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: chipBorder, width: isDark ? 1.0 : 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: chipColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: chipColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSharedDatesManager(Color unitColor, Color textColor,
      Color subtextColor, Color cardBg, Color borderColor) {
    final activeManagerKey = _inspectingManagerUid ??
        (_activeShares.isNotEmpty ? _activeShares.keys.first : null);
    final activeManagerData =
        activeManagerKey != null ? _activeShares[activeManagerKey] : null;
    final activeManagerName =
        (activeManagerData?['manager_name'] ?? 'Ingeniero de Unidad').toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.date_range_rounded, color: unitColor, size: 22),
                const SizedBox(width: 8),
                Text(
                  "REGISTROS COMPARTIDOS ACTIVOS",
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            if (_sharedShifts.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: unitColor.withAlpha(widget.isDarkMode ? 35 : 25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${_sharedShifts.length} turnos",
                  style: TextStyle(
                    color: unitColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          "Listado de turnos que $activeManagerName puede visualizar actualmente. Pulsa la 'X' en cualquier día para excluirlo de la compartición.",
          style: TextStyle(color: subtextColor, fontSize: 13),
        ),
        const SizedBox(height: 12),

        // Supervisor switch chips if multiple
        if (_activeShares.length > 1) ...[
          Text(
            "Ver datos visibles para:",
            style: TextStyle(
              color: subtextColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _activeShares.entries.map((e) {
                final isSelected = activeManagerKey == e.key;
                final name =
                    (e.value['manager_name'] ?? 'Ingeniero').toString();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? (widget.isDarkMode ? Colors.black : Colors.white)
                            : (widget.isDarkMode
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFF334155)),
                      ),
                    ),
                    selected: isSelected,
                    checkmarkColor:
                        widget.isDarkMode ? Colors.black : Colors.white,
                    color: WidgetStateProperty.resolveWith<Color?>((states) {
                      if (states.contains(WidgetState.selected)) {
                        return unitColor;
                      }
                      return widget.isDarkMode
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF1F5F9);
                    }),
                    side: WidgetStateBorderSide.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return BorderSide(color: unitColor, width: 1.5);
                      }
                      return BorderSide(color: borderColor, width: 1.0);
                    }),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _inspectingManagerUid = e.key;
                          final u = FirebaseAuth.instance.currentUser;
                          if (u != null) {
                            _setupMemberListener(e.key, u.uid);
                          }
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (activeManagerKey != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Turnos Visibles (${_sharedShifts.length})",
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: unitColor,
                  foregroundColor:
                      widget.isDarkMode ? Colors.black : Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.calendar_month_rounded, size: 16),
                label: const Text(
                  "Compartir días específicos",
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  _openSpecificDaysPicker(
                      activeManagerKey, activeManagerName);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],

        if (_sharedShifts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Column(
              children: [
                Icon(Icons.event_busy_rounded, color: subtextColor, size: 36),
                const SizedBox(height: 8),
                Text(
                  "No hay turnos compartidos actualmente para el periodo seleccionado.",
                  style: TextStyle(color: subtextColor, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _sharedShifts.length,
            itemBuilder: (context, index) {
              final shift = _sharedShifts[index];
              return _buildSharedDateItem(
                shift,
                unitColor,
                textColor,
                subtextColor,
                cardBg,
                borderColor,
              );
            },
          ),
      ],
    );
  }

  Widget _buildSharedDateItem(Map<String, dynamic> shift, Color unitColor,
      Color textColor, Color subtextColor, Color itemBg, Color borderColor) {
    final dateStr = (shift['date'] ?? '').toString();
    final isFalta = shift['es_falta'] == true;
    final isInProgress = shift['is_in_progress'] == true;
    final isVacaciones = shift['es_vacaciones'] == true;
    final isFestivo = shift['es_festivo'] == true;

    Color badgeColor = Colors.green;
    String badgeText = "COMPLETADO";
    IconData badgeIcon = Icons.check_circle_rounded;

    if (isFalta) {
      badgeColor = Colors.redAccent;
      badgeText = "FALTA";
      badgeIcon = Icons.cancel_rounded;
    } else if (isInProgress) {
      badgeColor = Colors.orangeAccent;
      badgeText = "EN CURSO";
      badgeIcon = Icons.timelapse_rounded;
    } else if (isVacaciones) {
      badgeColor = Colors.blueAccent;
      badgeText = "VACACIONES";
      badgeIcon = Icons.beach_access_rounded;
    } else if (isFestivo) {
      badgeColor = Colors.purpleAccent;
      badgeText = "FESTIVO";
      badgeIcon = Icons.celebration_rounded;
    }

    final entradaStr = shift['entrada_str']?.toString();
    final salidaStr = shift['salida_str']?.toString();
    final realEntryStr = shift['entrada_real_str']?.toString();
    final notas = (shift['notas'] ?? '').toString().trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: itemBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: badgeColor.withAlpha(widget.isDarkMode ? 35 : 25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(badgeIcon, color: badgeColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _formatDayNameAndDate(dateStr),
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor
                            .withAlpha(widget.isDarkMode ? 35 : 25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (!isFalta && !isVacaciones) ...[
                  Row(
                    children: [
                      if (entradaStr != null) ...[
                        const Icon(Icons.login_rounded,
                            size: 13, color: Colors.green),
                        const SizedBox(width: 3),
                        Text(
                          entradaStr,
                          style: TextStyle(color: subtextColor, fontSize: 12),
                        ),
                        const SizedBox(width: 10),
                      ],
                      if (salidaStr != null) ...[
                        const Icon(Icons.logout_rounded,
                            size: 13, color: Colors.orangeAccent),
                        const SizedBox(width: 3),
                        Text(
                          salidaStr,
                          style: TextStyle(color: subtextColor, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ],
                if (realEntryStr != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.fingerprint_rounded,
                          size: 13, color: Colors.blueAccent),
                      const SizedBox(width: 3),
                      Text(
                        "Real: $realEntryStr",
                        style: TextStyle(
                          color: widget.isDarkMode
                              ? Colors.lightBlueAccent
                              : const Color(0xFF0369A1),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
                if (notas.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    "Notas: $notas",
                    style: TextStyle(
                      color: subtextColor,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded,
                color: Colors.redAccent, size: 20),
            tooltip: "Excluir este día",
            onPressed: () => _removeSharedDate(shift),
          ),
        ],
      ),
    );
  }

  Widget _buildShareForm(Color unitColor, Color textColor, Color subtextColor,
      Color accentColor, Color borderColor) {
    final bool isEditing = _editingManagerUid != null;
    final candidateName =
        (_selectedCandidate?['name'] ?? 'Ingeniero de Unidad').toString();
    final candidateEmp =
        (_selectedCandidate?['emp'] ?? _selectedCandidate?['employee_number'] ?? '').toString();

    DateTime? previewActiveUntil;
    if (_selectedMode != 'Todos Mis Registros' && _selectedMode != 'Yo Decido') {
      previewActiveUntil = _calculateActiveUntil(_selectedMode, DateTime.now());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isEditing) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: unitColor.withAlpha(widget.isDarkMode ? 30 : 20),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: unitColor.withAlpha(80)),
            ),
            child: Row(
              children: [
                Icon(Icons.edit_note_rounded, color: unitColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Editando permisos y alcance de compartición con $candidateName",
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ] else ...[
          Text(
            "INGENIERO DE UNIDAD",
            style: TextStyle(
              color: subtextColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          // If a candidate is already selected, show explicit confirmation card:
          if (_selectedCandidate != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(widget.isDarkMode ? 35 : 20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withAlpha(120), width: 1.2),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.green.withAlpha(50),
                    child: Text(
                      candidateName.isNotEmpty
                          ? candidateName.substring(0, 1).toUpperCase()
                          : 'I',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                candidateName,
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green
                                    .withAlpha(widget.isDarkMode ? 45 : 30),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.green.withAlpha(120)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_rounded,
                                      size: 12, color: Colors.greenAccent),
                                  SizedBox(width: 4),
                                  Text(
                                    "✓ Seleccionado",
                                    style: TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (candidateEmp.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            "No. Empleado: $candidateEmp",
                            style: TextStyle(color: subtextColor, fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.redAccent, size: 20),
                    tooltip: "Cambiar Ingeniero",
                    onPressed: _removeSelectedCandidate,
                  ),
                ],
              ),
            ),
          ] else ...[
            // Search Input Field
            TextField(
              controller: _searchController,
              keyboardType: TextInputType.text,
              style: TextStyle(color: textColor, fontSize: 15),
              decoration: InputDecoration(
                labelText: "No. Empleado o Nombre del Ingeniero",
                labelStyle: TextStyle(
                  color: widget.isDarkMode
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF1E293B),
                  fontSize: 14,
                ),
                hintText: "Ej. 1043577 o Diego Merck",
                hintStyle: TextStyle(
                  color: widget.isDarkMode
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
                  fontSize: 14,
                ),
                prefixIcon: Icon(Icons.search_rounded, color: unitColor),
                suffixIcon: _isSearching
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: unitColor,
                          ),
                        ),
                      )
                    : (_searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded,
                                color: subtextColor),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchResults = [];
                                _searchError = null;
                              });
                            },
                          )
                        : null),
                filled: true,
                fillColor: widget.isDarkMode
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF8FAFC),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  borderSide: BorderSide(color: unitColor, width: 1.5),
                ),
              ),
              onChanged: _onSearchChanged,
              onSubmitted: _searchUnitManager,
            ),
            if (_searchError != null) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.redAccent
                      .withAlpha(widget.isDarkMode ? 35 : 25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Colors.redAccent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _searchError!,
                        style: TextStyle(
                          color: widget.isDarkMode
                              ? Colors.white
                              : Colors.red.shade900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_searchResults.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: widget.isDarkMode
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _searchResults.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: widget.isDarkMode
                        ? Colors.white10
                        : const Color(0xFFE2E8F0),
                  ),
                  itemBuilder: (context, i) {
                    final item = _searchResults[i];
                    final itemUid = (item['uid'] ?? '').toString();
                    final isAlreadyShared = _activeShares.containsKey(itemUid);

                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: unitColor.withAlpha(40),
                        child: Text(
                          item['name'].toString().isNotEmpty
                              ? item['name']
                                  .toString()
                                  .substring(0, 1)
                                  .toUpperCase()
                              : 'I',
                          style: TextStyle(
                            color: unitColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      title: Text(
                        item['name'].toString(),
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        "No. Empleado: ${item['emp']}",
                        style: TextStyle(color: subtextColor, fontSize: 12),
                      ),
                      trailing: isAlreadyShared
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green
                                    .withAlpha(widget.isDarkMode ? 35 : 20),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                "Ya activo",
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : Icon(Icons.add_circle_outline_rounded,
                              color: unitColor, size: 22),
                      onTap: () => _selectCandidate(item),
                    );
                  },
                ),
              ),
            ],
          ],
          const SizedBox(height: 20),
        ],

        // Unified Vigencia Selector
        Text(
          "MODO DE VIGENCIA Y ALCANCE",
          style: TextStyle(
            color: subtextColor,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Elige el alcance de registros a compartir con tu Ingeniero de Unidad:",
          style: TextStyle(color: subtextColor, fontSize: 12),
        ),
        const SizedBox(height: 10),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _unifiedModes.map((mode) {
            final isSelected = _selectedMode == mode;
            return ChoiceChip(
              label: Text(
                mode,
                style: TextStyle(
                  color: isSelected
                      ? (widget.isDarkMode ? Colors.black : Colors.white)
                      : (widget.isDarkMode
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF334155)),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              selected: isSelected,
              color: WidgetStateProperty.resolveWith<Color?>((states) {
                if (states.contains(WidgetState.selected)) {
                  return unitColor;
                }
                return widget.isDarkMode
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF1F5F9);
              }),
              side: WidgetStateBorderSide.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return BorderSide(color: unitColor, width: 1.5);
                }
                return BorderSide(color: borderColor);
              }),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedMode = mode);
                }
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 10),

        // Mode Description Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: unitColor.withAlpha(widget.isDarkMode ? 25 : 15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: unitColor.withAlpha(60)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    previewActiveUntil == null
                        ? Icons.all_inclusive_rounded
                        : Icons.info_outline_rounded,
                    color: unitColor,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _getModeDescription(_selectedMode),
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 22),
                child: Text(
                  previewActiveUntil == null
                      ? "Vigencia: Ilimitada (activo hasta revocar manualmente)"
                      : "Vigencia activa hasta: ${DateFormat('dd/MM/yyyy').format(previewActiveUntil)} (con 2 semanas de consulta adicional)",
                  style: TextStyle(
                    color: previewActiveUntil == null
                        ? Colors.greenAccent
                        : subtextColor,
                    fontSize: 11,
                    fontWeight: previewActiveUntil == null
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Checkboxes for Permissions
        Text(
          "DATOS A COMPARTIR",
          style: TextStyle(
            color: subtextColor,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        _buildCheckboxTile(
          title: "Hora Entrada",
          subtitle: "Comparte tu hora de entrada programada",
          value: _shareEntry,
          onChanged: (v) => setState(() => _shareEntry = v ?? false),
          unitColor: unitColor,
          textColor: textColor,
          subtextColor: subtextColor,
        ),
        _buildCheckboxTile(
          title: "Hora Salida",
          subtitle: "Comparte tu marcaje de salida",
          value: _shareExit,
          onChanged: (v) => setState(() => _shareExit = v ?? false),
          unitColor: unitColor,
          textColor: textColor,
          subtextColor: subtextColor,
        ),
        _buildCheckboxTile(
          title: "Hora Entrada Real",
          subtitle: "Permite ver el minuto exacto de tu llegada",
          value: _shareRealEntry,
          onChanged: (v) => setState(() => _shareRealEntry = v ?? false),
          unitColor: unitColor,
          textColor: textColor,
          subtextColor: subtextColor,
        ),
        _buildCheckboxTile(
          title: "Notas de Jornada",
          subtitle: "Comparte tus observaciones registradas en cada turno",
          value: _shareNotes,
          onChanged: (v) => setState(() => _shareNotes = v ?? false),
          unitColor: unitColor,
          textColor: textColor,
          subtextColor: subtextColor,
        ),
        const SizedBox(height: 22),

        // Action Buttons
        if (isEditing) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _cancelConfiguringShare,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: subtextColor,
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("CANCELAR",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving
                      ? null
                      : () => _saveShareInstance(isUpdating: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: unitColor,
                    foregroundColor:
                        widget.isDarkMode ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text("GUARDAR CAMBIOS",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ] else ...[
          if (_activeShares.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cancelConfiguringShare,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: subtextColor,
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text("CANCELAR",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.share_rounded, size: 20),
                    label: Text(
                      _isSaving ? "GUARDANDO..." : "COMPARTIR",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isDarkMode
                          ? Colors.orangeAccent
                          : const Color(0xFFEA580C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      disabledBackgroundColor: widget.isDarkMode
                          ? Colors.white12
                          : const Color(0xFFE2E8F0),
                      disabledForegroundColor: subtextColor,
                    ),
                    onPressed: (_selectedCandidate == null || _isSaving)
                        ? null
                        : () => _saveShareInstance(isUpdating: false),
                  ),
                ),
              ],
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.share_rounded, size: 20),
                label: Text(
                  _isSaving ? "GUARDANDO..." : "COMENZAR A COMPARTIR",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.isDarkMode
                      ? Colors.orangeAccent
                      : const Color(0xFFEA580C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  disabledBackgroundColor: widget.isDarkMode
                      ? Colors.white12
                      : const Color(0xFFE2E8F0),
                  disabledForegroundColor: subtextColor,
                ),
                onPressed: (_selectedCandidate == null || _isSaving)
                    ? null
                    : () => _saveShareInstance(isUpdating: false),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildPrivacyAdvisoryCard(
      Color unitColor, Color textColor, Color subtextColor) {
    final Color advisoryBg = widget.isDarkMode
        ? const Color(0xFF0F172A)
        : const Color(0xFFF0F9FF);
    final Color advisoryBorder = widget.isDarkMode
        ? unitColor.withAlpha(80)
        : const Color(0xFFBAE6FD);
    final Color titleColor = widget.isDarkMode
        ? unitColor
        : const Color(0xFF0369A1);
    final Color bodyColor = widget.isDarkMode
        ? const Color(0xFFE2E8F0)
        : const Color(0xFF334155);
    final Color bulletIconColor = widget.isDarkMode
        ? Colors.greenAccent
        : const Color(0xFF059669);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: advisoryBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: advisoryBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: titleColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Privacidad y Control de Datos",
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildPrivacyItem(
            bulletIconColor,
            "Acceso Específico:",
            " El Ingeniero de Unidad ÚNICAMENTE podrá visualizar los campos que marques como activos.",
            bodyColor,
          ),
          const SizedBox(height: 6),
          _buildPrivacyItem(
            bulletIconColor,
            "Garantía Salarial:",
            " Sueldos, tarifas por hora, cálculos de horas extras y pagos de nómina NUNCA se comparten.",
            bodyColor,
          ),
          const SizedBox(height: 6),
          _buildPrivacyItem(
            bulletIconColor,
            "Retiro Automático:",
            " Al expirar la vigencia o tras las 2 semanas adicionales de consulta, los datos se eliminan automáticamente.",
            bodyColor,
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyItem(
      Color iconColor, String title, String description, Color bodyColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(Icons.check_circle_outline_rounded,
              size: 14, color: iconColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: bodyColor, fontSize: 12, height: 1.35),
              children: [
                TextSpan(
                  text: title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: description),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
    required Color unitColor,
    required Color textColor,
    required Color subtextColor,
  }) {
    return CheckboxListTile(
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: subtextColor, fontSize: 12),
      ),
      value: value,
      activeColor: unitColor,
      checkColor: widget.isDarkMode ? Colors.black : Colors.white,
      onChanged: onChanged,
      dense: true,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _buildActiveBadge(String label, IconData icon, Color color) {
    final bool isDark = widget.isDarkMode;
    final Color badgeText;
    final Color badgeBg;
    final Color badgeBorder;

    final bool isGreen = color == Colors.greenAccent ||
        color == Colors.green ||
        color == const Color(0xFF15803D);
    final bool isOrange = color == Colors.orangeAccent ||
        color == Colors.orange ||
        color == const Color(0xFFC2410C);

    if (isDark) {
      badgeText = color;
      badgeBg = color.withAlpha(35);
      badgeBorder = color.withAlpha(90);
    } else {
      if (isGreen) {
        badgeText = const Color(0xFF15803D);
        badgeBg = const Color(0xFFDCFCE7);
        badgeBorder = const Color(0xFF16A34A);
      } else if (isOrange) {
        badgeText = const Color(0xFFC2410C);
        badgeBg = const Color(0xFFFFEDD5);
        badgeBorder = const Color(0xFFEA580C);
      } else {
        badgeText = const Color(0xFF0284C7);
        badgeBg = const Color(0xFFE0F2FE);
        badgeBorder = const Color(0xFF0284C7);
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeBorder, width: isDark ? 1.0 : 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: badgeText),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: badgeText,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}


