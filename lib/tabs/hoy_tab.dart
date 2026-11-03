part of '../main.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _HoyTabExt on _TelevisaAppState {
  Widget _buildHoyTab() {
    final now = DateTime.now();
    final WorkDay? todayRecord = _weeklyHistory.cast<WorkDay?>().firstWhere(
          (d) =>
              d != null &&
              d.entrada.year == now.year &&
              d.entrada.month == now.month &&
              d.entrada.day == now.day &&
              !d.isInProgress,
          orElse: () => null,
        );

    if (todayRecord != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 30),
            Text(_dateString,
                style: TextStyle(
                    color:
                        _isDarkMode ? Colors.white70 : Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w600)),
            Text(_timeString,
                style: TextStyle(
                    color:
                        _isDarkMode ? Colors.orange : const Color(0xFFC2410C),
                    fontSize: 32,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildTodaySummaryCard(todayRecord),
            if (_isUnitShareActive)
              _buildHoyManagerShareTile(DateTime.now(),
                  shiftId: todayRecord.id),
            const SizedBox(height: 30),
          ],
        ),
      );
    }
    bool hasTodayFalta = _weeklyHistory.any((d) =>
        d.entrada.year == now.year &&
        d.entrada.month == now.month &&
        d.entrada.day == now.day &&
        d.esFalta);
    bool hasTodayVacaciones = _weeklyHistory.any((d) =>
        d.entrada.year == now.year &&
        d.entrada.month == now.month &&
        d.entrada.day == now.day &&
        d.esVacaciones);
    bool hasTodayFestivo = _weeklyHistory.any((d) =>
        d.entrada.year == now.year &&
        d.entrada.month == now.month &&
        d.entrada.day == now.day &&
        d.esFestivo &&
        !d.festivoTrabajado);

    WorkDay? currentShift = _weeklyHistory.cast<WorkDay?>().firstWhere(
          (d) =>
              d?.id == _currentShiftId ||
              (d != null && d.isInProgress) ||
              (_entradaDateTime != null &&
                  d != null &&
                  d.entrada == _entradaDateTime),
          orElse: () => null,
        );

    DateTime? effectiveEntrada = _entradaDateTime ?? currentShift?.entrada;
    DateTime? effectiveEntradaReal =
        _entradaRealDateTime ?? currentShift?.entradaReal;

    bool hasRegisteredEntrada =
        _isClockedIn || _completedToday || _entradaDateTime != null;
    bool hasRegisteredSalida = _completedToday && _salidaDateTime != null;

    String entradaTimeString = _entradaDateTime != null
        ? DateFormat('hh:mm a').format(_entradaDateTime!)
        : (_entradaDisplay.contains(" - ")
            ? _entradaDisplay.split(" - ").last
            : (_entradaDisplay != "--/-- --:--" ? _entradaDisplay : "--:--"));
    String salidaTimeString = _salidaDateTime != null
        ? DateFormat('hh:mm a').format(_salidaDateTime!)
        : (_salidaDisplay.contains(" - ")
            ? _salidaDisplay.split(" - ").last
            : (_salidaDisplay != "--/-- --:--" ? _salidaDisplay : "--:--"));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 30),
          Text(_dateString,
              style: TextStyle(
                  color:
                      _isDarkMode ? Colors.white70 : Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w600)),
          Text(_timeString,
              style: TextStyle(
                  color:
                      _isDarkMode ? Colors.orange : const Color(0xFFC2410C),
                  fontSize: 32,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          // Consolidated side-by-side ENTRADA and SALIDA container
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.white.withAlpha(20) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _isDarkMode ? Colors.white12 : const Color(0xFFCBD5E1),
                width: _isDarkMode ? 1.0 : 1.5,
              ),
              boxShadow: _isDarkMode
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withAlpha(12),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- ENTRADA BOX ---
                  Expanded(
                    child: hasRegisteredEntrada
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 16),
                            decoration: BoxDecoration(
                              color: _isDarkMode
                                  ? Colors.green.withAlpha(25)
                                  : const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: _isDarkMode
                                      ? Colors.greenAccent.withAlpha(80)
                                      : const Color(0xFFA5D6A7)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.login,
                                            color: _isDarkMode
                                                ? Colors.greenAccent
                                                : const Color(0xFF2E7D32),
                                            size: 19),
                                        const SizedBox(width: 6),
                                        Text(
                                          "ENTRADA",
                                          style: TextStyle(
                                            color: _isDarkMode
                                                ? Colors.greenAccent
                                                : const Color(0xFF2E7D32),
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: Icon(Icons.edit,
                                          color: _isDarkMode
                                              ? Colors.greenAccent
                                              : const Color(0xFF2E7D32),
                                          size: 19),
                                      tooltip: "Editar hora entrada",
                                      onPressed: _isProcessing
                                          ? null
                                          : _editEntradaTime,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    entradaTimeString,
                                    style: TextStyle(
                                      color: _isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (effectiveEntradaReal != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    (effectiveEntrada != null &&
                                            effectiveEntradaReal
                                                .isAfter(effectiveEntrada))
                                        ? "Llegada: ${DateFormat('hh:mm a').format(effectiveEntradaReal)} (Tarde)"
                                        : "Llegada: ${DateFormat('hh:mm a').format(effectiveEntradaReal)}",
                                    style: TextStyle(
                                      color: (effectiveEntrada != null &&
                                              effectiveEntradaReal
                                                  .isAfter(effectiveEntrada))
                                          ? (_isDarkMode
                                              ? Colors.orangeAccent
                                              : const Color(0xFFB43403))
                                          : (_isDarkMode
                                              ? Colors.white54
                                              : Colors.black87),
                                      fontSize: 13,
                                      fontWeight: (effectiveEntrada != null &&
                                              effectiveEntradaReal
                                                  .isAfter(effectiveEntrada))
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ] else if (_entradaDateTime != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    DateFormat('dd/MM')
                                        .format(_entradaDateTime!),
                                    style: TextStyle(
                                      color: _isDarkMode
                                          ? Colors.white38
                                          : Colors.black87,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isDarkMode
                                      ? Colors.green.shade700
                                      : const Color(0xFF2E7D32),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 58),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14, horizontal: 8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  elevation: 2,
                                ),
                                onPressed: (_isProcessing ||
                                        hasTodayFalta ||
                                        hasTodayVacaciones ||
                                        hasTodayFestivo)
                                    ? null
                                    : () => _processRecord(
                                        "ENTRADA", DateTime.now()),
                                icon: const Icon(Icons.login, size: 22),
                                label: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "ENTRADA AHORA",
                                    style: TextStyle(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _isDarkMode
                                      ? Colors.greenAccent
                                      : const Color(0xFF2E7D32),
                                  minimumSize: const Size(double.infinity, 58),
                                  side: BorderSide(
                                    color: (_isProcessing ||
                                            hasTodayFalta ||
                                            hasTodayVacaciones ||
                                            hasTodayFestivo)
                                        ? (_isDarkMode
                                            ? Colors.white12
                                            : const Color(0xFFE5E7EB))
                                        : (_isDarkMode
                                            ? Colors.greenAccent.withAlpha(140)
                                            : const Color(0xFF2E7D32)),
                                    width: 1.2,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14, horizontal: 8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: (_isProcessing ||
                                        hasTodayFalta ||
                                        hasTodayVacaciones ||
                                        hasTodayFestivo)
                                    ? null
                                    : () async {
                                        DateTime now = DateTime.now();
                                        final TimeOfDay? picked =
                                            await _showScrollTimePicker(
                                          context,
                                          initialTime: TimeOfDay.now(),
                                          title: "¿A QUÉ HORA ENTRASTE HOY?",
                                        );
                                        if (picked != null && mounted) {
                                          DateTime manualTime = DateTime(
                                            now.year,
                                            now.month,
                                            now.day,
                                            picked.hour,
                                            picked.minute,
                                          );
                                          _processRecord(
                                              "ENTRADA", manualTime);
                                        }
                                      },
                                icon: Icon(Icons.edit,
                                    size: 22,
                                    color: _isDarkMode
                                        ? Colors.greenAccent
                                        : const Color(0xFF2E7D32)),
                                label: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "ENTRADA MANUAL",
                                    style: TextStyle(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(width: 14),

                  // --- SALIDA BOX ---
                  Expanded(
                    child: hasRegisteredSalida
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 16),
                            decoration: BoxDecoration(
                              color: _isDarkMode
                                  ? Colors.red.withAlpha(25)
                                  : const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: _isDarkMode
                                      ? Colors.redAccent.withAlpha(80)
                                      : const Color(0xFFEF9A9A)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.logout,
                                            color: _isDarkMode
                                                ? Colors.redAccent
                                                : const Color(0xFFC62828),
                                            size: 19),
                                        const SizedBox(width: 6),
                                        Text(
                                          "SALIDA",
                                          style: TextStyle(
                                            color: _isDarkMode
                                                ? Colors.redAccent
                                                : const Color(0xFFC62828),
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: Icon(Icons.edit,
                                          color: _isDarkMode
                                              ? Colors.redAccent
                                              : const Color(0xFFC62828),
                                          size: 19),
                                      tooltip: "Editar hora salida",
                                      onPressed: _isProcessing
                                          ? null
                                          : _editSalidaTime,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    salidaTimeString,
                                    style: TextStyle(
                                      color: _isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (_salidaDateTime != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    DateFormat('dd/MM')
                                        .format(_salidaDateTime!),
                                    style: TextStyle(
                                      color: _isDarkMode
                                          ? Colors.white38
                                          : Colors.black87,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : (_isClockedIn && !_completedToday)
                            ? Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isDarkMode
                                          ? Colors.redAccent.shade700
                                          : const Color(0xFFC62828),
                                      foregroundColor: Colors.white,
                                      minimumSize:
                                          const Size(double.infinity, 58),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14, horizontal: 8),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      elevation: 2,
                                    ),
                                    onPressed: _isProcessing
                                        ? null
                                        : () =>
                                            _executeSalida(DateTime.now()),
                                    icon: const Icon(Icons.logout, size: 22),
                                    label: const FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        "SALIDA AHORA",
                                        style: TextStyle(
                                          fontSize: 16.5,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _isDarkMode
                                          ? Colors.redAccent
                                          : const Color(0xFFB91C1C),
                                      minimumSize:
                                          const Size(double.infinity, 58),
                                      side: BorderSide(
                                        color: _isProcessing
                                            ? (_isDarkMode
                                                ? Colors.white12
                                                : const Color(0xFFE5E7EB))
                                            : (_isDarkMode
                                                ? Colors.redAccent
                                                    .withAlpha(140)
                                                : const Color(0xFFB91C1C)),
                                        width: _isDarkMode ? 1.2 : 1.8,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14, horizontal: 8),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                    onPressed: _isProcessing
                                        ? null
                                        : () async {
                                            DateTime now = DateTime.now();
                                            final TimeOfDay? picked =
                                                await _showScrollTimePicker(
                                              context,
                                              initialTime: TimeOfDay.now(),
                                              title:
                                                  "¿A QUÉ HORA SALISTE HOY?",
                                            );
                                            if (picked != null && mounted) {
                                              DateTime manualTime = DateTime(
                                                now.year,
                                                now.month,
                                                now.day,
                                                picked.hour,
                                                picked.minute,
                                              );
                                              await _executeSalida(manualTime);
                                            }
                                          },
                                    icon: Icon(Icons.edit,
                                        size: 22,
                                        color: _isDarkMode
                                            ? Colors.redAccent
                                            : const Color(0xFFB91C1C)),
                                    label: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        "SALIDA MANUAL",
                                        style: TextStyle(
                                          fontSize: 16.5,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                          color: _isDarkMode
                                              ? Colors.redAccent
                                              : const Color(0xFFB91C1C),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 16),
                                decoration: BoxDecoration(
                                  color: _isDarkMode
                                      ? Colors.white.withAlpha(8)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: _isDarkMode
                                          ? Colors.white10
                                          : const Color(0xFFCBD5E1),
                                      width: _isDarkMode ? 1.0 : 1.2),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.logout,
                                            color: _isDarkMode
                                                ? Colors.white24
                                                : const Color(0xFF64748B),
                                            size: 19),
                                        const SizedBox(width: 6),
                                        Text(
                                          "SALIDA",
                                          style: TextStyle(
                                            color: _isDarkMode
                                                ? Colors.white38
                                                : const Color(0xFF475569),
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        "--:--",
                                        style: TextStyle(
                                          color: _isDarkMode
                                              ? Colors.white24
                                              : const Color(0xFF64748B),
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "Pendiente",
                                      style: TextStyle(
                                        color: _isDarkMode
                                            ? Colors.white24
                                            : const Color(0xFF64748B),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                  ),
                ],
              ),
            ),
          ),
          if (_isUnitShareActive)
            _buildHoyManagerShareTile(DateTime.now(),
                shiftId: currentShift?.id),
          // Midnight & Recovery prompt if shift's entrada was from previous day
          if (_isShiftFromPreviousDay()) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _isDarkMode
                    ? Colors.amber.withAlpha(25)
                    : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _isDarkMode
                        ? Colors.amberAccent.withAlpha(120)
                        : const Color(0xFFFDE68A),
                    width: 1.5),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.nightlight_round,
                          color: _isDarkMode
                              ? Colors.amberAccent
                              : const Color(0xFFD97706),
                          size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Turno iniciado el ${DateFormat('dd/MM').format(_entradaDateTime!)}. Si olvidaste checar salida ayer:",
                          style: TextStyle(
                            color: _isDarkMode
                                ? Colors.white70
                                : Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isDarkMode
                          ? Colors.amber.shade800
                          : const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _showForgottenClockOutDialog,
                    icon: const Icon(Icons.restart_alt, size: 20),
                    label: const Text(
                      "REGISTRAR DÍA NUEVO",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 3-way shift rating selector (active when clocked in or completed today)
          if ((_isClockedIn || _completedToday) && currentShift != null) ...[
            const SizedBox(height: 16),
            _buildShiftRatingSelector(currentShift),
          ],

          // Time remaining or overtime message
          if (_timeRemainingMessage.isNotEmpty) ...[
            Builder(builder: (context) {
              Color boxBg;
              Color boxBorder;
              Color boxAccent;
              Color textC;

              if (_timeRemainingMessage.contains("acompleta otra media hora")) {
                boxBg = _isDarkMode
                    ? Colors.yellow.withAlpha(40)
                    : const Color(0xFFFEF9C3);
                boxBorder = _isDarkMode
                    ? Colors.yellowAccent.withAlpha(100)
                    : const Color(0xFFFDE047);
                boxAccent = _isDarkMode
                    ? Colors.yellowAccent
                    : const Color(0xFFCA8A04);
                textC = _isDarkMode
                    ? Colors.yellowAccent
                    : const Color(0xFF854D0E);
              } else if (_timeRemainingMessage.contains("tiempo extra")) {
                boxBg = _isDarkMode
                    ? Colors.orange.withAlpha(40)
                    : const Color(0xFFFFEDD5);
                boxBorder = _isDarkMode
                    ? Colors.orangeAccent.withAlpha(100)
                    : const Color(0xFFFDBA74);
                boxAccent = _isDarkMode
                    ? Colors.orangeAccent
                    : const Color(0xFFEA580C);
                textC = _isDarkMode
                    ? Colors.orangeAccent
                    : const Color(0xFF9A3412);
              } else {
                boxBg = _isDarkMode
                    ? Colors.blue.withAlpha(40)
                    : const Color(0xFFEFF6FF);
                boxBorder = _isDarkMode
                    ? Colors.blueAccent.withAlpha(100)
                    : const Color(0xFF93C5FD);
                boxAccent = _isDarkMode
                    ? Colors.blueAccent
                    : const Color(0xFF1E3A8A);
                textC = _isDarkMode
                    ? Colors.blueAccent
                    : const Color(0xFF1E3A8A);
              }

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: boxBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: boxBorder,
                    width: _isDarkMode ? 1.0 : 1.4,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _timeRemainingMessage
                              .contains("acompleta otra media hora")
                          ? Icons.access_time_filled
                          : (_timeRemainingMessage.contains("tiempo extra")
                              ? Icons.timer_outlined
                              : Icons.access_time),
                      color: boxAccent,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _timeRemainingMessage,
                        style: TextStyle(
                          color: textC,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          // Notes section for the active shift
          if ((_isClockedIn || _completedToday) && currentShift != null) ...[
            const SizedBox(height: 16),
            _buildNotesSection(currentShift),
          ],

          // Discard in-progress shift button (positioned at bottom of active shift)
          if (_isClockedIn) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isDarkMode
                    ? Colors.red.withAlpha(25)
                    : const Color(0xFFFEE2E2),
                foregroundColor: _isDarkMode
                    ? Colors.redAccent
                    : const Color(0xFF991B1B),
                elevation: _isDarkMode ? 0 : 1,
                side: BorderSide(
                  color: _isDarkMode
                      ? Colors.redAccent.withAlpha(140)
                      : const Color(0xFFDC2626),
                  width: _isDarkMode ? 1.4 : 1.6,
                ),
                minimumSize: const Size(double.infinity, 48),
                padding:
                    const EdgeInsets.symmetric(vertical: 13, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isProcessing ? null : _deleteTodayShift,
              icon: Icon(
                Icons.delete_outline,
                size: 21,
                color: _isDarkMode
                    ? Colors.redAccent
                    : const Color(0xFF991B1B),
              ),
              label: Text(
                "DESCARTAR TURNO EN PROGRESO",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                  letterSpacing: 0.8,
                  color: _isDarkMode
                      ? Colors.redAccent
                      : const Color(0xFF991B1B),
                ),
              ),
            ),
          ],
          // Bottom quick actions (only when not clocked in and not completed today)
          if (!_isClockedIn && !_completedToday) ...[
            const SizedBox(height: 24),
            Divider(
                color: _isDarkMode
                    ? Colors.white12
                    : const Color(0xFFD1D5DB)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildButton(
                      hasTodayVacaciones
                          ? "VACACIONES REGISTRADAS"
                          : "VACACIONES",
                      hasTodayVacaciones
                          ? Colors.grey
                          : Colors.lightGreen.shade700,
                      (hasTodayFalta ||
                              hasTodayVacaciones ||
                              hasTodayFestivo)
                          ? null
                          : () {
                              DateTime now = DateTime.now();
                              DateTime noon =
                                  DateTime(now.year, now.month, now.day, 12, 0);
                              final double salaryForDate =
                                  _getSalaryForDate(noon);

                              _addAndSortHistory(WorkDay(
                                  entrada: noon,
                                  salida: noon,
                                  sueldoBase: salaryForDate,
                                  baseHours: _getJornadaForDate(noon),
                                  esVacaciones: true));
                            },
                      isCompact: true),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildButton(
                      hasTodayFalta
                          ? "FALTA REGISTRADA"
                          : "NO LABORÉ HOY",
                      hasTodayFalta ? Colors.grey : Colors.red.shade900,
                      (hasTodayFalta ||
                              hasTodayVacaciones ||
                              hasTodayFestivo)
                          ? null
                          : () {
                              DateTime now = DateTime.now();
                              DateTime noon =
                                  DateTime(now.year, now.month, now.day, 12, 0);
                              final double salaryForDate =
                                  _getSalaryForDate(noon);

                              _addAndSortHistory(WorkDay(
                                  entrada: noon,
                                  salida: noon,
                                  sueldoBase: salaryForDate,
                                  baseHours: _getJornadaForDate(noon),
                                  esFalta: true));
                            },
                      isCompact: true),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildButton(
                hasTodayFestivo
                    ? "DÍA FESTIVO REGISTRADO"
                    : "DÍA FESTIVO (NO LABORADO)",
                hasTodayFestivo ? Colors.grey : Colors.purple.shade700,
                (hasTodayFalta ||
                        hasTodayVacaciones ||
                        hasTodayFestivo)
                    ? null
                    : () {
                        DateTime now = DateTime.now();
                        DateTime noon =
                            DateTime(now.year, now.month, now.day, 12, 0);
                        final double salaryForDate =
                            _getSalaryForDate(noon);

                        _addAndSortHistory(WorkDay(
                            entrada: noon,
                            salida: noon,
                            sueldoBase: salaryForDate,
                            baseHours: _getJornadaForDate(noon),
                            esFestivo: true,
                            festivoTrabajado: false));
                      },
                isCompact: true),
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }


}
