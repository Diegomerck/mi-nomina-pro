part of '../main.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _SettingsTabExt on _TelevisaAppState {
  Widget _buildSettingsTab() {
    final activeContract = _getContractForDate(DateTime.now());
    final String activeContractName =
        (activeContract['name'] ?? 'Contrato Base').toString();
    final double activeFomento =
        (activeContract['fomento'] as num?)?.toDouble() ?? 2.0;
    final double activeCuota =
        (activeContract['cuota'] as num?)?.toDouble() ?? 2.0;
    final String activeRatesSummary =
        "Fomento ${activeFomento.toStringAsFixed(1)}% • Cuota ${activeCuota.toStringAsFixed(1)}%";

    final double horizontalPadding =
        MediaQuery.of(context).size.width < 380 ? 12.0 : 20.0;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("MI PERFIL",
              style: TextStyle(
                  color: _isDarkMode ? Colors.orange : const Color(0xFFC2410C),
                  fontWeight: FontWeight.bold,
                  fontSize: 20)),
          const SizedBox(height: 15),
          _buildSettTextField(_firstNameController, "Nombre"),
          _buildSettTextField(_lastNameController, "Apellido"),
          _buildSettTextField(_userEmpNoController, "No. Empleado"),
          _buildSettTextField(
              _recoveryEmailController, "Correo de Recuperación",
              hint: "Para restablecer contraseña"),
          Divider(
              color: _isDarkMode ? Colors.white24 : const Color(0xFFCBD5E1),
              height: 40),
          Text("AJUSTES DE NÓMINA",
              style: TextStyle(
                  color: _isDarkMode ? Colors.orange : const Color(0xFFC2410C),
                  fontWeight: FontWeight.bold,
                  fontSize: 20)),
          const SizedBox(height: 8),
          Text(
            "Toca cualquier ajuste para consultar o registrar su historial de vigencias por rango de fechas.",
            style: TextStyle(
              color: _isDarkMode ? Colors.white60 : const Color(0xFF1E293B),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),

          // 0. Plantillas de Contrato
          _buildNumericSettingCard(
            title: "Plantillas de Contrato",
            valueDisplay: activeContractName,
            subtitle: activeRatesSummary,
            periodCount: _contractHistory.length,
            icon: Icons.badge_rounded,
            isNew: true,
            onTap: () => _navigateToContractPresetsScreen(),
          ),

          // 1. Sueldo Diario Base
          _buildNumericSettingCard(
            title: "Sueldo Diario Base",
            valueDisplay: "\$ ${_getSalaryForDate(DateTime.now()).toStringAsFixed(2)}",
            periodCount: _salaryHistory.length,
            icon: Icons.attach_money,
            onTap: () => _navigateToParamHistory(
              title: "Sueldo Diario Base",
              unitPrefix: "\$ ",
              unitSuffix: "",
              controller: _salaryController,
              history: _salaryHistory,
              icon: Icons.attach_money,
              isSalary: true,
              onSave: (updatedHistory, newBaseValue) async {
                _rebuild(() {
                  _salaryHistory = updatedHistory;
                  if (newBaseValue != null) {
                    _salaryController.text = newBaseValue.toStringAsFixed(2);
                  }
                  _syncWorkDayStatics();
                });
                await _saveData(checkSalaryChange: false);
              },
            ),
          ),

          // 2. Horas Base Diarias (Jornada)
          _buildNumericSettingCard(
            title: "Horas Base Diarias (Jornada)",
            valueDisplay: "${_getJornadaForDate(DateTime.now()).toStringAsFixed(1)} hrs",
            periodCount: _jornadaHistory.length,
            icon: Icons.access_time_rounded,
            onTap: () => _navigateToParamHistory(
              title: "Horas Base Diarias (Jornada)",
              unitPrefix: "",
              unitSuffix: " hrs",
              controller: _baseHoursController,
              history: _jornadaHistory,
              icon: Icons.access_time_rounded,
              onSave: (updatedHistory, newBaseValue) async {
                _rebuild(() {
                  _jornadaHistory = updatedHistory;
                  if (newBaseValue != null) {
                    _baseHoursController.text = newBaseValue.toString();
                  }
                  _syncWorkDayStatics();
                });
                await _saveData(checkSalaryChange: false);
              },
            ),
          ),

          // 3. Días de Descanso
          _buildNumericSettingCard(
            title: "Días de Descanso",
            valueDisplay:
                _formatRestDaysDisplay(_getRestDaysForDate(DateTime.now())),
            periodCount: _restDaysHistory.length,
            subtitle: _restDaysHistory.isEmpty
                ? "Sin historial (días base fijos)"
                : null,
            icon: Icons.calendar_month_rounded,
            onTap: () => _navigateToRestDaysHistory(),
          ),

          // 3. Retención I.S.R. (%)
          _buildNumericSettingCard(
            title: "Retención I.S.R.",
            valueDisplay: "${_getRetentionForDate(DateTime.now()).toStringAsFixed(2)} %",
            periodCount: _retentionHistory.length,
            icon: Icons.percent,
            onTap: () => _navigateToParamHistory(
              title: "Retención I.S.R.",
              unitPrefix: "",
              unitSuffix: " %",
              controller: _retentionController,
              history: _retentionHistory,
              icon: Icons.percent,
              onSave: (updatedHistory, newBaseValue) async {
                _rebuild(() {
                  _retentionHistory = updatedHistory;
                  if (newBaseValue != null) {
                    _retentionController.text = newBaseValue.toString();
                  }
                });
                await _saveData(checkSalaryChange: false);
              },
            ),
          ),

          // 4. Fomento Eficiencia (%)
          _buildNumericSettingCard(
            title: "Fomento a la Eficiencia",
            valueDisplay: "${_getFomentoForDate(DateTime.now()).toStringAsFixed(2)} %",
            periodCount: _fomentoHistory.length,
            icon: Icons.trending_up,
            onTap: () => _navigateToParamHistory(
              title: "Fomento a la Eficiencia",
              unitPrefix: "",
              unitSuffix: " %",
              controller: _fomentoController,
              history: _fomentoHistory,
              icon: Icons.trending_up,
              onSave: (updatedHistory, newBaseValue) async {
                _rebuild(() {
                  _fomentoHistory = updatedHistory;
                  if (newBaseValue != null) {
                    _fomentoController.text = newBaseValue.toString();
                  }
                });
                await _saveData(checkSalaryChange: false);
              },
            ),
          ),

          // 5. Cuota Sindical (%)
          _buildNumericSettingCard(
            title: "Cuota Sindical",
            valueDisplay: "${_getCuotaForDate(DateTime.now()).toStringAsFixed(2)} %",
            periodCount: _cuotaHistory.length,
            icon: Icons.groups_rounded,
            onTap: () => _navigateToParamHistory(
              title: "Cuota Sindical",
              unitPrefix: "",
              unitSuffix: " %",
              controller: _cuotaController,
              history: _cuotaHistory,
              icon: Icons.groups_rounded,
              onSave: (updatedHistory, newBaseValue) async {
                _rebuild(() {
                  _cuotaHistory = updatedHistory;
                  if (newBaseValue != null) {
                    _cuotaController.text = newBaseValue.toString();
                  }
                });
                await _saveData(checkSalaryChange: false);
              },
            ),
          ),

          // 6. Fondo de Ahorro (LISR Art. 27 Fracc. XI)
          _buildNumericSettingCard(
            title: "Fondo de Ahorro",
            valueDisplay: _fondoAhorroEnabled
                ? "${_fondoAhorroPct.toStringAsFixed(1)} %"
                : "Inactivo",
            periodCount: 0,
            subtitle: _fondoAhorroEnabled
                ? "Aportación 1:${_fondoAhorroMatchRatio == 1.0 ? '1' : _fondoAhorroMatchRatio.toStringAsFixed(1)} • Entrega Q${_fondoAhorroCutoffQuincena.toString().padLeft(2, '0')}"
                : "Inactivo • Configurar ahorro y aportación",
            icon: Icons.savings_rounded,
            isNew: true,
            onTap: () => _navigateToFondoAhorroSettings(),
          ),

          // 7. Vales de Fomento Cultural (Monedero Chedraui)
          _buildNumericSettingCard(
            title: "Vales de Fomento Cultural\n(Monedero Chedraui)",
            valueDisplay: (_valesFomentoCulturalEnabled &&
                    _valesFomentoCulturalAmount > 0)
                ? "\$ ${_valesFomentoCulturalAmount.toStringAsFixed(2)}"
                : "Inactivo",
            periodCount: 0,
            subtitle: (_valesFomentoCulturalEnabled &&
                    _valesFomentoCulturalAmount > 0)
                ? "Activo • 2da quincena de cada mes"
                : "Inactivo • Monedero Chedraui y control de saldo",
            icon: Icons.card_giftcard_rounded,
            isNew: true,
            valueColor: (_valesFomentoCulturalEnabled &&
                    _valesFomentoCulturalAmount > 0)
                ? null
                : (_isDarkMode ? Colors.white54 : const Color(0xFF64748B)),
            onTap: () => _navigateToValesChedrauiSettings(),
          ),

          const SizedBox(height: 20),
          OutlinedButton(
              style: OutlinedButton.styleFrom(
                  backgroundColor:
                      _isDarkMode ? Colors.transparent : Colors.white,
                  side: BorderSide(
                      color: _isDarkMode
                          ? Colors.blueAccent
                          : const Color(0xFF2563EB),
                      width: 1.5),
                  minimumSize: const Size(double.infinity, 50)),
              onPressed: _showInfoDialog,
              child: Text("INFORMACIÓN",
                  style: TextStyle(
                      color: _isDarkMode
                          ? Colors.blueAccent
                          : const Color(0xFF1D4ED8),
                      fontWeight: FontWeight.bold))),
          if (kIsWeb) ...[
            const SizedBox(height: 16),
            _buildDownloadApkCard(),
          ],
          if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                backgroundColor:
                    _isDarkMode ? Colors.transparent : Colors.white,
                side: BorderSide(
                  color: _isDarkMode
                      ? Colors.orangeAccent
                      : const Color(0xFFD97706),
                  width: 1.5,
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
              icon: Icon(
                Icons.system_update_rounded,
                color: _isDarkMode
                    ? Colors.orangeAccent
                    : const Color(0xFFB45309),
              ),
              onPressed: () => AppUpdateService.instance.checkForUpdates(
                context,
                currentVersion: _getLatestVersion(),
                isManual: true,
                isDarkMode: _isDarkMode,
              ),
              label: Text(
                "BUSCAR ACTUALIZACIÓN",
                style: TextStyle(
                  color: _isDarkMode
                      ? Colors.orangeAccent
                      : const Color(0xFFB45309),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          const SizedBox(height: 25),
          Divider(
              color: _isDarkMode ? Colors.white24 : const Color(0xFFCBD5E1)),
          const SizedBox(height: 25),
          _buildUnitShareNavigationCard(),
          const SizedBox(height: 25),
          Divider(
              color: _isDarkMode ? Colors.white24 : const Color(0xFFCBD5E1)),
          const SizedBox(height: 25),
          Text("MIGRACIÓN DE DATOS",
              style: TextStyle(
                  color: _isDarkMode ? Colors.orange : const Color(0xFFC2410C),
                  fontWeight: FontWeight.bold,
                  fontSize: 20)),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _exportData,
                  icon: Icon(Icons.upload_file,
                      color: _isDarkMode
                          ? Colors.green
                          : const Color(0xFF15803D)),
                  label: Text("EXPORTAR",
                      style: TextStyle(
                          color: _isDarkMode
                              ? Colors.green
                              : const Color(0xFF15803D),
                          fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                      backgroundColor:
                          _isDarkMode ? Colors.transparent : Colors.white,
                      side: BorderSide(
                          color: _isDarkMode
                              ? Colors.green
                              : const Color(0xFF16A34A),
                          width: 1.5)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _importData,
                  icon: Icon(Icons.download,
                      color: _isDarkMode
                          ? Colors.blue
                          : const Color(0xFF1D4ED8)),
                  label: Text("IMPORTAR",
                      style: TextStyle(
                          color: _isDarkMode
                              ? Colors.blue
                              : const Color(0xFF1D4ED8),
                          fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                      backgroundColor:
                          _isDarkMode ? Colors.transparent : Colors.white,
                      side: BorderSide(
                          color: _isDarkMode
                              ? Colors.blue
                              : const Color(0xFF2563EB),
                          width: 1.5)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildButton("CAMBIAR CONTRASEÑA",
              _isDarkMode ? Colors.orangeAccent : const Color(0xFFEA580C), () {
            _showChangePasswordDialog();
          }),
          const SizedBox(height: 12),
          _buildButton("RECUPERAR CONTRASEÑA",
              _isDarkMode ? Colors.blueAccent : const Color(0xFF2563EB), () {
            _showForgotPasswordFromSettingsDialog();
          }),
          if (isAppAdminUser(FirebaseAuth.instance.currentUser)) ...[
            Divider(
                color: _isDarkMode ? Colors.white24 : const Color(0xFFCBD5E1),
                height: 40),
            Text(
              "ADMINISTRACIÓN",
              style: TextStyle(
                color: _isDarkMode ? Colors.amber : const Color(0xFFB45309),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 12),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) =>
                          AdminAccountMergeScreen(isDarkMode: _isDarkMode),
                    ),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: _isDarkMode
                        ? const Color(0xFF262626)
                        : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.amber.withAlpha(_isDarkMode ? 120 : 180),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.withAlpha(_isDarkMode ? 40 : 50),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.admin_panel_settings_rounded,
                            color: Colors.amber, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Panel de Administración",
                              style: TextStyle(
                                color: _isDarkMode
                                    ? Colors.white
                                    : const Color(0xFF92400E),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              "Fusión y gestión de cuentas de usuario",
                              style: TextStyle(
                                color: _isDarkMode
                                    ? Colors.white60
                                    : const Color(0xFFB45309),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded,
                          color: _isDarkMode
                              ? Colors.white54
                              : const Color(0xFF92400E),
                          size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 30),
          _buildButton("CERRAR SESIÓN",
              _isDarkMode ? Colors.redAccent : const Color(0xFFDC2626), () {
            _confirmSignOut(context);
          }),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          scrollable: true,
          backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: _isDarkMode ? Colors.white12 : const Color(0xFFCBD5E1),
              width: 1.5,
            ),
          ),
          title: Text(
            "¿Cerrar sesión?",
            style: TextStyle(
                color: _isDarkMode ? Colors.orange : const Color(0xFFC2410C),
                fontWeight: FontWeight.bold),
          ),
          content: Text(
            "¿Estás seguro de que deseas cerrar sesión?",
            style: TextStyle(
                color: _isDarkMode ? Colors.white : Colors.black),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                "Cancelar",
                style: TextStyle(
                    color: _isDarkMode
                        ? Colors.white54
                        : const Color(0xFF1E293B)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isDarkMode ? Colors.redAccent : const Color(0xFFDC2626),
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _handleSignOut();
              },
              child: const Text(
                "Cerrar sesión",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
  // =========================================================================
  // UNIT SHARE ("COMPARTIR CON") SETTINGS & NAVIGATION
  // =========================================================================
  // UNIT SHARE SETTINGS & CACHE HELPERS
  // =========================================================================

  Map<String, dynamic> _sanitizeUnitShareMap(Map<String, dynamic> data) {
    return sanitizeUnitShareMapForCache(data);
  }

  Future<void> _loadUnitShareSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'active_unit_share_cache_${user.uid}';
    final cached = prefs.getString(cacheKey);
    if (cached != null) {
      try {
        final Map<String, dynamic> c = jsonDecode(cached);
        bool hasActive = false;
        final rawShares = c['shares'];
        if (rawShares is Map && rawShares.isNotEmpty) {
          for (final val in rawShares.values) {
            if (val is Map) {
              final activeUntil = parseUnitShareDate(val['active_sharing_until']);
              final isExpired =
                  activeUntil != null && DateTime.now().isAfter(activeUntil);
              if (val['is_active'] != false && !isExpired) {
                hasActive = true;
                break;
              }
            }
          }
        } else {
          final activeUntil = parseUnitShareDate(c['active_sharing_until']);
          final isExpired =
              activeUntil != null && DateTime.now().isAfter(activeUntil);
          if (c['is_active'] == true && !isExpired) {
            hasActive = true;
          }
        }

        if (hasActive) {
          if (mounted) {
            _rebuild(() {
              _isUnitShareActive = true;
              _activeUnitShareData = _sanitizeUnitShareMap(c);
            });
          }
        }
      } catch (e) {
        debugPrint("Error reading cached unit share: $e");
      }
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('unit_share')
          .get();

      if (doc.exists && doc.data() != null) {
        final d = doc.data()!;
        final sanitizedDoc = _sanitizeUnitShareMap(d);
        bool hasActive = false;
        final rawShares = sanitizedDoc['shares'];
        if (rawShares is Map && rawShares.isNotEmpty) {
          for (final val in rawShares.values) {
            if (val is Map) {
              final activeUntil = parseUnitShareDate(val['active_sharing_until']);
              final isExpired =
                  activeUntil != null && DateTime.now().isAfter(activeUntil);
              if (val['is_active'] != false && !isExpired) {
                hasActive = true;
                break;
              }
            }
          }
        } else {
          final activeUntil = parseUnitShareDate(sanitizedDoc['active_sharing_until']);
          final isExpired =
              activeUntil != null && DateTime.now().isAfter(activeUntil);
          if (sanitizedDoc['is_active'] == true && !isExpired) {
            hasActive = true;
          }
        }

        if (hasActive) {
          await prefs.setString(
            cacheKey,
            jsonEncode(sanitizedDoc),
          );

          if (mounted) {
            _rebuild(() {
              _isUnitShareActive = true;
              _activeUnitShareData = sanitizedDoc;
            });
          }
          // Self-heal: ensure remote manager docs hold strictly filtered shifts
          _syncShiftsToUnitManager();
          return;
        } else {
          await prefs.remove(cacheKey);
        }
      } else {
        await prefs.remove(cacheKey);
      }

      if (mounted) {
        _rebuild(() {
          _isUnitShareActive = false;
          _activeUnitShareData = null;
        });
      }
    } catch (e) {
      debugPrint("Error loading unit share settings: $e");
    }
  }

  bool _isDateInUnitShareRange(DateTime date, String mode) {
    if (_activeUnitShareData == null) return false;
    final activeUntil = parseUnitShareDate(_activeUnitShareData!['active_sharing_until']);
    return isDateSharedUnderUnitShare(
      date: date,
      mode: mode,
      activeUntil: activeUntil,
    );
  }

  Map<String, Map<String, dynamic>> _getActiveShareGrants() {
    if (!_isUnitShareActive || _activeUnitShareData == null) return {};
    return extractActiveSharesFromMap(_activeUnitShareData!);
  }

  bool _isDateSharedWithSpecificManager(
    String mgrKey,
    Map<String, dynamic> grant,
    DateTime date, {
    String? shiftId,
  }) {
    final activeUntil = parseUnitShareDate(grant['active_sharing_until']);
    final isExpired =
        activeUntil != null && DateTime.now().isAfter(activeUntil);
    if (grant['is_active'] == false || isExpired) return false;
    final mode =
        (grant['mode'] ?? grant['duration'] ?? 'Esta Semana').toString();
    final customDates = parseUnitShareStringSet(grant['custom_dates']);
    final excludedDates = parseUnitShareStringSet(grant['excluded_dates']);
    return isDateSharedUnderUnitShare(
      date: date,
      shiftId: shiftId,
      mode: mode,
      activeUntil: activeUntil,
      customDates: customDates,
      excludedDates: excludedDates,
    );
  }

  bool _isDateSharedWithManager(DateTime date, {String? shiftId}) {
    if (!_isUnitShareActive || _activeUnitShareData == null) return false;
    final activeGrants = _getActiveShareGrants();
    if (activeGrants.isNotEmpty) {
      for (final entry in activeGrants.entries) {
        if (_isDateSharedWithSpecificManager(
          entry.key,
          entry.value,
          date,
          shiftId: shiftId,
        )) {
          return true;
        }
      }
      return false;
    }

    final mode = (_activeUnitShareData?['mode'] ??
            _activeUnitShareData?['duration'] ??
            _activeUnitShareData?['timeframe'] ??
            '')
        .toString();
    final excludedDates =
        parseUnitShareStringSet(_activeUnitShareData!['excluded_dates']);
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    if (excludedDates.contains(dateKey) ||
        (shiftId != null &&
            shiftId.isNotEmpty &&
            excludedDates.contains(shiftId))) {
      return false;
    }

    if (mode == 'Yo Decido') {
      final customDates =
          parseUnitShareStringSet(_activeUnitShareData!['custom_dates']);
      if (customDates.isEmpty) return false;
      return customDates.contains(dateKey) ||
          (shiftId != null &&
              shiftId.isNotEmpty &&
              customDates.contains(shiftId));
    }

    return _isDateInUnitShareRange(date, mode);
  }

  Future<void> _toggleUnitShareForDate({
    required DateTime date,
    String? shiftId,
    bool? share,
    String? managerKey,
    Map<String, bool>? perManagerShare,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _activeUnitShareData == null) return;
    final dateKey = DateFormat('yyyy-MM-dd').format(date);

    final rawShares = _activeUnitShareData!['shares'];
    final Map<String, dynamic> updatedShares = {};
    if (rawShares is Map && rawShares.isNotEmpty) {
      for (final entry in rawShares.entries) {
        updatedShares[entry.key.toString()] =
            Map<String, dynamic>.from(entry.value as Map);
      }
    } else {
      final activeGrants = extractActiveSharesFromMap(_activeUnitShareData!);
      for (final entry in activeGrants.entries) {
        updatedShares[entry.key] = Map<String, dynamic>.from(entry.value);
      }
    }

    if (updatedShares.isNotEmpty) {
      for (final entry in updatedShares.entries) {
        final mgrKey = entry.key;
        final grant = Map<String, dynamic>.from(entry.value as Map);
        bool? targetShare;
        if (perManagerShare != null) {
          if (perManagerShare.containsKey(mgrKey)) {
            targetShare = perManagerShare[mgrKey];
          }
        } else if (managerKey != null) {
          if (mgrKey == managerKey) {
            targetShare = share;
          }
        } else {
          targetShare = share;
        }

        if (targetShare != null) {
          final mode = (grant['mode'] ?? grant['duration'] ?? '').toString();
          List<dynamic> grantExcluded =
              List<dynamic>.from(grant['excluded_dates'] ?? []);
          List<dynamic> grantCustom =
              List<dynamic>.from(grant['custom_dates'] ?? []);

          if (mode == 'Yo Decido') {
            if (targetShare) {
              if (!grantCustom.contains(dateKey)) grantCustom.add(dateKey);
              if (shiftId != null && !grantCustom.contains(shiftId)) {
                grantCustom.add(shiftId);
              }
              grantExcluded.removeWhere((e) =>
                  e.toString() == dateKey ||
                  (shiftId != null && e.toString() == shiftId));
            } else {
              grantCustom.removeWhere((e) =>
                  e.toString() == dateKey ||
                  (shiftId != null && e.toString() == shiftId));
              if (!grantExcluded.contains(dateKey)) grantExcluded.add(dateKey);
              if (shiftId != null && !grantExcluded.contains(shiftId)) {
                grantExcluded.add(shiftId);
              }
            }
          } else {
            if (targetShare) {
              grantExcluded.removeWhere((e) =>
                  e.toString() == dateKey ||
                  (shiftId != null && e.toString() == shiftId));
            } else {
              if (!grantExcluded.contains(dateKey)) grantExcluded.add(dateKey);
              if (shiftId != null && !grantExcluded.contains(shiftId)) {
                grantExcluded.add(shiftId);
              }
            }
          }

          grant['excluded_dates'] = grantExcluded;
          grant['custom_dates'] = grantCustom;
          updatedShares[mgrKey] = grant;
        }
      }
    }

    final mode = (_activeUnitShareData?['mode'] ??
            _activeUnitShareData?['duration'] ??
            _activeUnitShareData?['timeframe'] ??
            '')
        .toString();

    List<dynamic> currentExcluded = List<dynamic>.from(
        (_activeUnitShareData!['excluded_dates'] as List<dynamic>?) ?? []);
    List<dynamic> currentCustom = List<dynamic>.from(
        (_activeUnitShareData!['custom_dates'] as List<dynamic>?) ?? []);

    final bool effectiveTopShare = share ??
        (perManagerShare != null
            ? perManagerShare.values.any((v) => v)
            : updatedShares.entries.any((e) =>
                _isDateSharedWithSpecificManager(
                    e.key, e.value as Map<String, dynamic>, date,
                    shiftId: shiftId)));

    if (mode == 'Yo Decido') {
      if (effectiveTopShare) {
        if (!currentCustom.contains(dateKey)) currentCustom.add(dateKey);
        if (shiftId != null && !currentCustom.contains(shiftId)) {
          currentCustom.add(shiftId);
        }
        currentExcluded.removeWhere((e) =>
            e.toString() == dateKey ||
            (shiftId != null && e.toString() == shiftId));
      } else {
        currentCustom.removeWhere((e) =>
            e.toString() == dateKey ||
            (shiftId != null && e.toString() == shiftId));
        if (!currentExcluded.contains(dateKey)) currentExcluded.add(dateKey);
        if (shiftId != null && !currentExcluded.contains(shiftId)) {
          currentExcluded.add(shiftId);
        }
      }
    } else {
      if (effectiveTopShare) {
        currentExcluded.removeWhere((e) =>
            e.toString() == dateKey ||
            (shiftId != null && e.toString() == shiftId));
      } else {
        if (!currentExcluded.contains(dateKey)) currentExcluded.add(dateKey);
        if (shiftId != null && !currentExcluded.contains(shiftId)) {
          currentExcluded.add(shiftId);
        }
      }
    }

    final cleanShares = sanitizeSharesMapForFirestore(updatedShares);

    final Map<String, dynamic> updatedMap = {
      ..._activeUnitShareData!,
      'excluded_dates': currentExcluded,
      'custom_dates': currentCustom,
    };
    if (cleanShares.isNotEmpty) {
      updatedMap['shares'] = cleanShares;
      updatedMap['managers'] = cleanShares.values.toList();
    }

    final updatedData = _sanitizeUnitShareMap(updatedMap);

    if (mounted) {
      _rebuild(() {
        _activeUnitShareData = updatedData;
      });
    }

    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'active_unit_share_cache_${user.uid}';
    await prefs.setString(cacheKey, jsonEncode(updatedData));

    try {
      final firestoreUpdate = <String, dynamic>{
        'excluded_dates': currentExcluded,
        'custom_dates': currentCustom,
        'updated_at': FieldValue.serverTimestamp(),
      };
      if (cleanShares.isNotEmpty) {
        firestoreUpdate['shares'] = cleanShares;
        firestoreUpdate['managers'] = cleanShares.values.toList();
      }
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('unit_share')
          .set(firestoreUpdate, SetOptions(merge: true));

      await _syncShiftsToUnitManager();
    } catch (e) {
      debugPrint("Error updating unit share preferences: $e");
    }
  }

  Widget _buildHoyManagerShareTile(DateTime date, {String? shiftId}) {
    if (!_isUnitShareActive || _activeUnitShareData == null) {
      return const SizedBox.shrink();
    }

    final activeGrants = _getActiveShareGrants();
    if (activeGrants.isEmpty) {
      return const SizedBox.shrink();
    }

    final Color primaryColor =
        _isDarkMode ? Colors.cyanAccent : const Color(0xFF0284C7);
    final Color cardBg = _isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final Color borderColor =
        _isDarkMode ? Colors.white12 : const Color(0xFFCBD5E1);
    final Color textColor =
        _isDarkMode ? Colors.white : Colors.black;
    final Color subtextColor =
        _isDarkMode ? Colors.white54 : const Color(0xFF1E293B);

    if (activeGrants.length == 1) {
      final entry = activeGrants.entries.first;
      final mgrKey = entry.key;
      final grant = entry.value;
      final isShared = _isDateSharedWithSpecificManager(
        mgrKey,
        grant,
        date,
        shiftId: shiftId,
      );
      final String managerName =
          (grant['manager_name'] ?? 'Ingeniero de Unidad').toString();
      final String mode =
          (grant['mode'] ?? grant['duration'] ?? '').toString();

      final Color singleBorderColor = isShared
          ? (_isDarkMode
              ? Colors.cyanAccent.withAlpha(90)
              : const Color(0xFF0284C7).withAlpha(120))
          : borderColor;

      final String statusSubtitle = isShared
          ? "Visible para $managerName"
          : (mode == 'Yo Decido'
              ? "Oculto para $managerName (Modo Yo Decido)"
              : "Excluido para $managerName");

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: singleBorderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(_isDarkMode ? 30 : 8),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isShared
                    ? primaryColor.withAlpha(_isDarkMode ? 40 : 25)
                    : (_isDarkMode
                        ? Colors.white.withAlpha(12)
                        : const Color(0xFFF1F5F9)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isShared ? Icons.share_rounded : Icons.visibility_off_outlined,
                color: isShared
                    ? primaryColor
                    : (_isDarkMode ? Colors.white38 : const Color(0xFF94A3B8)),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "Compartir turno de hoy",
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isShared
                              ? Colors.green.withAlpha(_isDarkMode ? 40 : 30)
                              : Colors.grey.withAlpha(_isDarkMode ? 40 : 30),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isShared ? "COMPARTIDO" : "NO COMPARTIDO",
                          style: TextStyle(
                            color: isShared
                                ? (_isDarkMode
                                    ? Colors.greenAccent
                                    : const Color(0xFF15803D))
                                : (_isDarkMode
                                    ? Colors.white60
                                    : const Color(0xFF1E293B)),
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    statusSubtitle,
                    style: TextStyle(
                      color: subtextColor,
                      fontSize: 11.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: isShared,
              activeColor: primaryColor,
              onChanged: (val) async {
                await _toggleUnitShareForDate(
                  date: date,
                  shiftId: shiftId,
                  managerKey: mgrKey,
                  share: val,
                );
              },
            ),
          ],
        ),
      );
    }

    // Multiple active managers
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(_isDarkMode ? 30 : 8),
            blurRadius: 6,
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
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: primaryColor.withAlpha(_isDarkMode ? 40 : 25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.share_rounded,
                  color: primaryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Compartir turno de hoy",
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                    Text(
                      "Visibilidad por supervisor (${activeGrants.length} activos)",
                      style: TextStyle(
                        color: subtextColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(
            height: 1,
            color: _isDarkMode ? Colors.white12 : const Color(0xFFF1F5F9),
          ),
          const SizedBox(height: 8),
          ...activeGrants.entries.map((entry) {
            final mgrKey = entry.key;
            final grant = entry.value;
            final isShared = _isDateSharedWithSpecificManager(
              mgrKey,
              grant,
              date,
              shiftId: shiftId,
            );
            final String mgrName =
                (grant['manager_name'] ?? 'Ingeniero').toString();
            final String mgrEmp = (grant['manager_emp'] ?? '').toString();
            final String initial = mgrName.isNotEmpty
                ? mgrName.substring(0, 1).toUpperCase()
                : 'I';

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: isShared
                        ? primaryColor.withAlpha(_isDarkMode ? 45 : 30)
                        : (_isDarkMode
                            ? Colors.white12
                            : const Color(0xFFE2E8F0)),
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: isShared
                            ? primaryColor
                            : (_isDarkMode
                                ? Colors.white60
                                : const Color(0xFF1E293B)),
                        fontWeight: FontWeight.bold,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                mgrName,
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: isShared
                                    ? Colors.green
                                        .withAlpha(_isDarkMode ? 40 : 30)
                                    : Colors.grey
                                        .withAlpha(_isDarkMode ? 40 : 30),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isShared ? "COMPARTIDO" : "NO COMPARTIDO",
                                style: TextStyle(
                                  color: isShared
                                      ? (_isDarkMode
                                          ? Colors.greenAccent
                                          : const Color(0xFF15803D))
                                      : subtextColor,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (mgrEmp.isNotEmpty)
                          Text(
                            "No. Emp: $mgrEmp",
                            style: TextStyle(
                              color: subtextColor,
                              fontSize: 10.5,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: isShared,
                    activeColor: primaryColor,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (val) async {
                      await _toggleUnitShareForDate(
                        date: date,
                        shiftId: shiftId,
                        managerKey: mgrKey,
                        share: val,
                      );
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildUnitShareNavigationCard() {
    final Color unitColor =
        _isDarkMode ? Colors.cyanAccent : const Color(0xFF0284C7);
    final Color cardBg = _isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final Color borderColor =
        _isDarkMode ? Colors.white12 : const Color(0xFFCBD5E1);
    final Color textColor = _isDarkMode ? Colors.white : Colors.black;
    final Color subtextColor =
        _isDarkMode ? Colors.white54 : const Color(0xFF1E293B);

    final bool isActive = _isUnitShareActive && _activeUnitShareData != null;
    final String managerName =
        (_activeUnitShareData?['manager_name'] ?? '').toString();
    final String mode = (_activeUnitShareData?['mode'] ??
            _activeUnitShareData?['duration'] ??
            'Esta Semana')
        .toString();
    final rawShares = _activeUnitShareData?['shares'];
    final rawManagers = _activeUnitShareData?['managers'];
    final int managersCount = (rawShares is Map && rawShares.isNotEmpty)
        ? rawShares.length
        : ((rawManagers is List && rawManagers.isNotEmpty)
            ? rawManagers.length
            : (managerName.isNotEmpty ? 1 : 0));

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? unitColor.withAlpha(_isDarkMode ? 120 : 140)
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UnitShareScreen(
                  isDarkMode: _isDarkMode,
                  weeklyHistory: _weeklyHistory,
                ),
              ),
            );
            _loadUnitShareSettings();
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: unitColor.withAlpha(_isDarkMode ? 35 : 25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.supervisor_account_rounded,
                    color: unitColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            "COMPARTIR CON",
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          _buildNewBadge(),
                          if (isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green
                                    .withAlpha(_isDarkMode ? 40 : 25),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.green.withAlpha(90)),
                              ),
                              child: const Text(
                                "ACTIVO",
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isActive
                            ? (managersCount > 1
                                ? "Compartiendo con $managersCount ingenieros de unidad"
                                : "Compartiendo con $managerName ($mode)")
                            : "Comparte tus horarios de forma segura. Tú decides qué datos mostrar y cuándo dejar de compartir.",
                        style: TextStyle(
                          color: subtextColor,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: subtextColor,
                  size: 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _syncShiftsToUnitManager() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (!_isUnitShareActive || _activeUnitShareData == null) return;

    final now = DateTime.now();

    // Find last clock out
    Timestamp? lastClockOut;
    final completed = _weeklyHistory
        .where((d) => !d.isInProgress && !d.esFalta)
        .toList();
    if (completed.isNotEmpty) {
      completed.sort((a, b) => b.salida.compareTo(a.salida));
      lastClockOut = Timestamp.fromDate(completed.first.salida);
    }

    final String memberName =
        "${_firstNameController.text.trim()} ${_lastNameController.text.trim()}"
            .trim();
    final String memberEmp = _userEmpNoController.text.trim();

    try {
      // 1. Independent shares structure
      final rawShares = _activeUnitShareData!['shares'];
      if (rawShares is Map && rawShares.isNotEmpty) {
        for (final entry in rawShares.entries) {
          final grant = Map<String, dynamic>.from(entry.value as Map);
          final activeUntil = parseUnitShareDate(grant['active_sharing_until']);
          final isExpired =
              activeUntil != null && now.isAfter(activeUntil);
          if (grant['is_active'] == false || isExpired) continue;

          final String mUid =
              (grant['manager_uid'] ?? entry.key).toString().trim();
          final String mDocId =
              (grant['manager_doc_id'] ?? '').toString().trim();
          final String mEmp = (grant['manager_emp'] ?? '').toString().trim();
          if (mUid.isEmpty && mDocId.isEmpty && mEmp.isEmpty) continue;

          final String mode =
              (grant['mode'] ?? grant['duration'] ?? 'Esta Semana').toString();
          final bool shareEntry = grant['share_entry'] ?? true;
          final bool shareExit = grant['share_exit'] ?? true;
          final bool shareRealEntry = grant['share_real_entry'] == true;
          final bool shareNotes = grant['share_notes'] == true;
          final customDates = parseUnitShareStringSet(grant['custom_dates']);
          final excludedDates = parseUnitShareStringSet(grant['excluded_dates']);

          final List<WorkDay> relevantShifts = filterWorkDaysForUnitShare(
            _weeklyHistory,
            mode: mode,
            activeUntil: activeUntil,
            customDates: customDates,
            excludedDates: excludedDates,
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

          final memberData = {
            'member_name': memberName.isNotEmpty
                ? memberName
                : (user.displayName ?? 'Sin nombre'),
            'member_emp': memberEmp,
            'mode': mode,
            'duration': mode,
            'timeframe': mode,
            'active_sharing_until': activeUntil != null
                ? Timestamp.fromDate(activeUntil)
                : null,
            'share_entry': shareEntry,
            'share_exit': shareExit,
            'share_real_entry': shareRealEntry,
            'share_notes': shareNotes,
            'shifts': sanitizedShifts,
            'last_clock_out': lastClockOut,
            'last_synced_at': FieldValue.serverTimestamp(),
          };

          if (mUid.isNotEmpty) {
            await FirebaseFirestore.instance
                .collection('unit_shares')
                .doc(mUid)
                .collection('members')
                .doc(user.uid)
                .set(memberData, SetOptions(merge: true));
          }
          if (mDocId.isNotEmpty && mDocId != mUid) {
            await FirebaseFirestore.instance
                .collection('unit_shares')
                .doc(mDocId)
                .collection('members')
                .doc(user.uid)
                .set(memberData, SetOptions(merge: true));
          }
          if (mEmp.isNotEmpty && mEmp != mUid && mEmp != mDocId) {
            await FirebaseFirestore.instance
                .collection('unit_shares')
                .doc(mEmp)
                .collection('members')
                .doc(user.uid)
                .set(memberData, SetOptions(merge: true));
          }
        }
        return;
      }

      // 2. Fallback legacy structure
      final rawUntil = _activeUnitShareData!['active_sharing_until'];
      final activeUntil = parseUnitShareDate(rawUntil);
      if (activeUntil != null && now.isAfter(activeUntil)) {
        return;
      }

      final List<Map<String, dynamic>> targetManagers = [];
      final rawManagers = _activeUnitShareData!['managers'];
      if (rawManagers is List && rawManagers.isNotEmpty) {
        for (final m in rawManagers) {
          if (m is Map) {
            targetManagers.add(Map<String, dynamic>.from(m));
          }
        }
      }
      if (targetManagers.isEmpty) {
        final legacyUid = (_activeUnitShareData!['manager_uid'] ??
                _activeUnitShareData!['uid'] ??
                '')
            .toString()
            .trim();
        final legacyDocId =
            (_activeUnitShareData!['manager_doc_id'] ?? '').toString().trim();
        final legacyEmp =
            (_activeUnitShareData!['manager_emp'] ?? '').toString().trim();
        final legacyName =
            (_activeUnitShareData!['manager_name'] ?? '').toString().trim();
        if (legacyUid.isNotEmpty ||
            legacyDocId.isNotEmpty ||
            legacyEmp.isNotEmpty) {
          targetManagers.add({
            'uid': legacyUid,
            'doc_id': legacyDocId,
            'emp': legacyEmp,
            'name': legacyName,
          });
        }
      }

      if (targetManagers.isEmpty) return;

      final bool shareEntry = _activeUnitShareData!['share_entry'] ?? true;
      final bool shareExit = _activeUnitShareData!['share_exit'] ?? true;
      final bool shareRealEntry =
          _activeUnitShareData!['share_real_entry'] == true;
      final bool shareNotes = _activeUnitShareData!['share_notes'] == true;
      final String mode = (_activeUnitShareData!['mode'] ??
              _activeUnitShareData!['duration'] ??
              _activeUnitShareData!['timeframe'] ??
              'Esta Semana')
          .toString();

      final excludedDates =
          parseUnitShareStringSet(_activeUnitShareData!['excluded_dates']);
      final customDates =
          parseUnitShareStringSet(_activeUnitShareData!['custom_dates']);

      final List<WorkDay> relevantShifts = filterWorkDaysForUnitShare(
        _weeklyHistory,
        mode: mode,
        activeUntil: activeUntil,
        customDates: customDates,
        excludedDates: excludedDates,
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

      final memberData = {
        'member_name': memberName.isNotEmpty
            ? memberName
            : (user.displayName ?? 'Sin nombre'),
        'member_emp': memberEmp,
        'mode': mode,
        'duration': mode,
        'timeframe': mode,
        'active_sharing_until': activeUntil != null
            ? Timestamp.fromDate(activeUntil)
            : null,
        'share_entry': shareEntry,
        'share_exit': shareExit,
        'share_real_entry': shareRealEntry,
        'share_notes': shareNotes,
        'shifts': sanitizedShifts,
        'last_clock_out': lastClockOut,
        'last_synced_at': FieldValue.serverTimestamp(),
      };

      for (final mgr in targetManagers) {
        final String mUid = (mgr['uid'] ?? '').toString().trim();
        final String mDocId = (mgr['doc_id'] ?? '').toString().trim();
        final String mEmp =
            (mgr['emp'] ?? mgr['employee_number'] ?? '').toString().trim();

        if (mUid.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('unit_shares')
              .doc(mUid)
              .collection('members')
              .doc(user.uid)
              .set(memberData, SetOptions(merge: true));
        }

        if (mDocId.isNotEmpty && mDocId != mUid) {
          await FirebaseFirestore.instance
              .collection('unit_shares')
              .doc(mDocId)
              .collection('members')
              .doc(user.uid)
              .set(memberData, SetOptions(merge: true));
        }

        if (mEmp.isNotEmpty && mEmp != mUid && mEmp != mDocId) {
          await FirebaseFirestore.instance
              .collection('unit_shares')
              .doc(mEmp)
              .collection('members')
              .doc(user.uid)
              .set(memberData, SetOptions(merge: true));
        }
      }
    } catch (e) {
      debugPrint("Error in _syncShiftsToUnitManager: $e");
    }
  }

  Future<void> _navigateToFondoAhorroSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FondoAhorroScreen(
          appState: this,
        ),
      ),
    );
    _rebuild(() {});
  }

  Future<void> _navigateToValesChedrauiSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ValesChedrauiScreen(
          appState: this,
        ),
      ),
    );
    _rebuild(() {});
  }

  Future<void> _navigateToContractPresetsScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ContractPresetsScreen(
          appState: this,
        ),
      ),
    );
    _rebuild(() {});
  }

  Widget _buildDownloadApkCard() {
    const Color accentColor = Color(0xFF16A34A);
    final Color cardBg = _isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final Color textColor =
        _isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final Color subtextColor =
        _isDarkMode ? Colors.white70 : const Color(0xFF475569);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isDarkMode
              ? accentColor.withAlpha(90)
              : const Color(0xFF86EFAC),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(_isDarkMode ? 30 : 8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _showDownloadApkDialog,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accentColor.withAlpha(_isDarkMode ? 45 : 30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.android_rounded,
                        color: Color(0xFF16A34A),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Aplicación para Android",
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            "Instala Mi Nómina Pro en tu teléfono para mayor rapidez y acceso sin conexión",
                            style: TextStyle(
                              color: subtextColor,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.download_rounded, size: 20),
                    label: const Text(
                      "DESCARGAR APK PARA ANDROID",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    onPressed: _showDownloadApkDialog,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDownloadApkDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        const Color accentColor = Color(0xFF16A34A);
        final Color textColor =
            _isDarkMode ? Colors.white : const Color(0xFF0F172A);
        final Color subtextColor =
            _isDarkMode ? Colors.white70 : const Color(0xFF334155);

        return AlertDialog(
          scrollable: true,
          backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: _isDarkMode ? Colors.white12 : const Color(0xFFCBD5E1),
              width: 1.5,
            ),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(_isDarkMode ? 45 : 30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.android_rounded,
                  color: Color(0xFF16A34A),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Instalar en Android",
                  style: TextStyle(
                    color: _isDarkMode ? Colors.orange : const Color(0xFFC2410C),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
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
                "Sigue estos 3 sencillos pasos para instalar la aplicación en tu celular Android:",
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              _buildApkInstallStep(
                stepNumber: "1",
                title: "Descarga el archivo APK",
                description:
                    "Presiona 'DESCARGAR AHORA' para ir a GitHub Releases y descargar el archivo 'app-release.apk' más reciente.",
              ),
              const SizedBox(height: 14),
              _buildApkInstallStep(
                stepNumber: "2",
                title: "Permite la instalación",
                description:
                    "Si tu navegador (Chrome u otro) te solicita permiso para 'Instalar apps de fuentes desconocidas', acéptalo en los ajustes de tu teléfono.",
              ),
              const SizedBox(height: 14),
              _buildApkInstallStep(
                stepNumber: "3",
                title: "Abre e instala",
                description:
                    "Abre la descarga desde tus notificaciones o carpeta de Descargas y presiona 'Instalar'. ¡Listo!",
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isDarkMode
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        _isDarkMode ? Colors.white12 : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 20,
                      color: _isDarkMode
                          ? Colors.orangeAccent
                          : const Color(0xFFD97706),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Es un archivo 100% seguro y oficial. Android muestra esta advertencia estándar para apps instaladas fuera de Google Play Store.",
                        style: TextStyle(
                          color: subtextColor,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                "CERRAR",
                style: TextStyle(
                  color:
                      _isDarkMode ? Colors.white60 : const Color(0xFF64748B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                elevation: 0,
              ),
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text(
                "DESCARGAR AHORA",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final uri = Uri.parse(
                    'https://github.com/Diegomerck/mi-nomina-pro/releases/latest');
                try {
                  if (!await launchUrl(uri,
                      mode: LaunchMode.externalApplication)) {
                    debugPrint("Could not launch $uri");
                  }
                } catch (e) {
                  debugPrint("Error launching $uri: $e");
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildApkInstallStep({
    required String stepNumber,
    required String title,
    required String description,
  }) {
    const Color accentColor = Color(0xFF16A34A);
    final Color textColor =
        _isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final Color subtextColor =
        _isDarkMode ? Colors.white70 : const Color(0xFF475569);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: accentColor.withAlpha(_isDarkMode ? 40 : 25),
            shape: BoxShape.circle,
            border: Border.all(
              color: accentColor,
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            stepNumber,
            style: TextStyle(
              color: _isDarkMode
                  ? const Color(0xFF4ADE80)
                  : const Color(0xFF15803D),
              fontWeight: FontWeight.bold,
              fontSize: 12.5,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: subtextColor,
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

