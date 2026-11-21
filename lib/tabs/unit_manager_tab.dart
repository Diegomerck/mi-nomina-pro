part of '../main.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _UnitManagerTabExt on _TelevisaAppState {
  Widget _buildUnitManagerTab() {
    final user = FirebaseAuth.instance.currentUser;
    final Color unitColor =
        _isDarkMode ? Colors.cyanAccent : const Color(0xFF0284C7);
    final Color cardBg = _isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final Color borderColor =
        _isDarkMode ? Colors.white12 : const Color(0xFFCBD5E1);
    final Color textColor = _isDarkMode ? Colors.white : Colors.black;
    final Color subtextColor =
        _isDarkMode ? Colors.white54 : const Color(0xFF1E293B);

    if (user == null) {
      return Center(
        child: Text(
          "Inicia sesión para ver la asistencia de tu unidad.",
          style: TextStyle(color: subtextColor),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        // Header Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(_isDarkMode ? 40 : 10),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: unitColor.withAlpha(_isDarkMode ? 35 : 20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.shield_rounded,
                        color: unitColor, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "ASISTENCIA DE UNIDAD",
                              style: TextStyle(
                                color: unitColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _isDarkMode
                                    ? Colors.green.withAlpha(35)
                                    : const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _isDarkMode
                                      ? Colors.green.withAlpha(120)
                                      : const Color(0xFF16A34A),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: _isDarkMode
                                          ? Colors.greenAccent
                                          : const Color(0xFF15803D),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    "EN VIVO",
                                    style: TextStyle(
                                      color: _isDarkMode
                                          ? Colors.greenAccent
                                          : const Color(0xFF15803D),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Supervisión y control de asistencia de los colaboradores asignados a tu unidad.",
                          style: TextStyle(color: subtextColor, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Stream of unit members
        StreamBuilder<List<DocumentSnapshot>>(
          stream: _getOrCreateUnitMembersStream(
              user.uid, _userEmpNoController.text.trim()),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(color: unitColor),
                ),
              );
            }

            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.redAccent, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Error al cargar colaboradores: ${snapshot.error}",
                        style: TextStyle(color: textColor, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              );
            }

            final now = DateTime.now();
            final allDocs = snapshot.data ?? [];
            final validMembers = allDocs.where((doc) {
              final d = doc.data() as Map<String, dynamic>?;
              if (d == null) return false;
              final rawRetention = d['data_retention_until'];
              DateTime? retentionUntil;
              if (rawRetention is Timestamp) {
                retentionUntil = rawRetention.toDate();
              } else if (rawRetention is String) {
                retentionUntil = DateTime.tryParse(rawRetention);
              }
              if (retentionUntil != null && now.isAfter(retentionUntil)) {
                return false;
              }
              return true;
            }).toList();

            if (validMembers.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 40, horizontal: 24),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: unitColor.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.shield_outlined,
                          color: unitColor, size: 40),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Sin colaboradores compartiendo asistencia",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Actualmente no tienes colaboradores compartiendo sus registros contigo. Cuando un colaborador ingrese tu No. de Empleado en su sección 'Compartir Con', sus horarios aparecerán aquí automáticamente.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: subtextColor, fontSize: 13),
                    ),
                  ],
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 12),
                  child: Row(
                    children: [
                      Text(
                        "COLABORADORES ACTIVOS",
                        style: TextStyle(
                          color: subtextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: unitColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: unitColor.withAlpha(90)),
                        ),
                        child: Text(
                          "${validMembers.length}",
                          style: TextStyle(
                            color: unitColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ...validMembers.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _UnitMemberAttendanceCard(
                      data: data,
                      isDarkMode: _isDarkMode,
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ],
    );
  }

  void _showChangelogDialog() {
    final currentVersion = _getLatestVersion();
    final lastSeen = _lastSeenVersion ?? "0.0.0";

    List<String> versionsToShow = _changelogByVersion.keys
        .where((v) => _compareVersions(v, lastSeen) > 0)
        .toList();

    if (versionsToShow.isEmpty) {
      versionsToShow = _changelogByVersion.keys.toList();
    }

    versionsToShow.sort((a, b) => _compareVersions(b, a));

    showModalBottomSheet(
      context: context,
      backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.new_releases,
                          color: _isDarkMode ? Colors.orange : const Color(0xFFC2410C),
                          size: 24),
                      const SizedBox(width: 8),
                      Text(
                        "Novedades",
                        style: TextStyle(
                          color: _isDarkMode ? Colors.orange : const Color(0xFFC2410C),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close,
                        color: _isDarkMode ? Colors.white54 : const Color(0xFF1E293B)),
                    onPressed: () => Navigator.pop(sheetContext),
                  ),
                ],
              ),
              Divider(color: _isDarkMode ? Colors.white24 : const Color(0xFFCBD5E1)),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: versionsToShow.length,
                  itemBuilder: (context, index) {
                    final ver = versionsToShow[index];
                    final notes = _changelogByVersion[ver] ?? [];
                    final verTitle = _changelogTitles[ver] ?? "Versión $ver";
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            verTitle,
                            style: TextStyle(
                              color: _isDarkMode ? Colors.orangeAccent : const Color(0xFFC2410C),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...notes.map(
                            (note) {
                              final colonIndex = note.indexOf(':');
                              final hasColon = colonIndex != -1;
                              final titlePart = hasColon ? note.substring(0, colonIndex + 1) : '';
                              final bodyPart = hasColon ? note.substring(colonIndex + 1) : note;

                              final trimmed = note.trim();
                              final startsWithAlphanumeric = RegExp(r'^[a-zA-Z0-9]').hasMatch(trimmed);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0, left: 2.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (startsWithAlphanumeric) ...[
                                      Text(
                                        "• ",
                                        style: TextStyle(
                                          color: _isDarkMode ? Colors.orange : const Color(0xFFC2410C),
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                    Expanded(
                                      child: Text.rich(
                                        TextSpan(
                                          children: [
                                            if (hasColon) ...[
                                              TextSpan(
                                                text: titlePart,
                                                style: TextStyle(
                                                  color: _isDarkMode ? Colors.white : Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  height: 1.35,
                                                ),
                                              ),
                                              TextSpan(
                                                text: bodyPart,
                                                style: TextStyle(
                                                  color: _isDarkMode ? Colors.white70 : const Color(0xFF1E293B),
                                                  fontWeight: FontWeight.normal,
                                                  fontSize: 14,
                                                  height: 1.35,
                                                ),
                                              ),
                                            ] else ...[
                                              TextSpan(
                                                text: note,
                                                style: TextStyle(
                                                  color: _isDarkMode ? Colors.white : Colors.black,
                                                  fontSize: 14,
                                                  height: 1.35,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_seen_version', currentVersion);
      if (mounted) {
        _rebuild(() {
          _lastSeenVersion = currentVersion;
        });
      }
    });
  }

  void _navigateToParamHistory({
    required String title,
    required String unitPrefix,
    required String unitSuffix,
    required TextEditingController controller,
    required List<Map<String, dynamic>> history,
    required IconData icon,
    required Function(List<Map<String, dynamic>> updatedHistory, double? newBaseValue) onSave,
    bool isSalary = false,
  }) async {
    final double currVal = double.tryParse(controller.text) ?? 0.0;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParameterHistoryScreen(
          title: title,
          unitPrefix: unitPrefix,
          unitSuffix: unitSuffix,
          currentValue: currVal,
          history: history,
          isDarkMode: _isDarkMode,
          icon: icon,
          isSalary: isSalary,
          onCommit: (updatedHistory, newActiveValue) async {
            await onSave(updatedHistory, newActiveValue);
          },
        ),
      ),
    );
  }

  Widget _buildNewBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF97316).withAlpha(60),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: const Text(
        '¡NUEVO!',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildNumericSettingCard({
    required String title,
    required String valueDisplay,
    required int periodCount,
    required VoidCallback onTap,
    required IconData icon,
    String? subtitle,
    Color? valueColor,
    bool isNew = false,
  }) {
    final Color accentColor =
        _isDarkMode ? Colors.orange : const Color(0xFFC2410C);
    final Color cardBg = _isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final Color borderColor =
        _isDarkMode ? Colors.white12 : const Color(0xFFCBD5E1);
    final Color textColor = _isDarkMode ? Colors.white : Colors.black;
    final Color subtextColor =
        _isDarkMode ? Colors.white54 : const Color(0xFF1E293B);
    final Color actualValueColor = valueColor ?? accentColor;
    final bool isLongValue = valueDisplay.length > 12;
    final String effectiveSubtitle = subtitle ??
        (periodCount == 0
            ? "Sin historial (valor base fijo)"
            : "$periodCount ${periodCount == 1 ? 'periodo configurado' : 'periodos configurados'}");

    Widget cardContent;
    if (title.contains('\n')) {
      final List<String> parts = title.split('\n');
      final String titlePart1 = parts[0];
      final String titlePart2 =
          parts.length > 1 ? parts.sublist(1).join('\n') : '';

      cardContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Tier: Icon (44x44) + 14px gap + Expanded Column
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(_isDarkMode ? 35 : 25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          titlePart1,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        if (isNew) _buildNewBadge(),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      titlePart2,
                      style: TextStyle(
                        color: subtextColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Divider: 10px spacing, subtle 1px divider line (white10 dark / black12 light), 10px spacing
          const SizedBox(height: 10),
          Container(
            height: 1,
            color: _isDarkMode ? Colors.white10 : Colors.black12,
          ),
          const SizedBox(height: 10),
          // Bottom Tier: Row with Expanded(subtitle, 12 fontSize), 8px gap, Text(valueDisplay, 16 bold actualValueColor), 4px gap, Icon(chevron_right, 18px)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  effectiveSubtitle,
                  style: TextStyle(
                    color: subtextColor,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                valueDisplay,
                style: TextStyle(
                  color: actualValueColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: _isDarkMode ? Colors.white38 : Colors.grey.shade400,
                size: 18,
              ),
            ],
          ),
        ],
      );
    } else {
      cardContent = Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withAlpha(_isDarkMode ? 35 : 25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (isNew) _buildNewBadge(),
                  ],
                ),
                if (isLongValue) ...[
                  const SizedBox(height: 3),
                  Text(
                    valueDisplay,
                    style: TextStyle(
                      color: actualValueColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 3),
                Text(
                  effectiveSubtitle,
                  style: TextStyle(
                    color: subtextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (!isLongValue) ...[
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(
                valueDisplay,
                style: TextStyle(
                  color: actualValueColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right,
            color: _isDarkMode ? Colors.white38 : Colors.grey.shade400,
            size: 20,
          ),
        ],
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: cardContent,
          ),
        ),
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    bool isLoading = false;

    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
      scrollable: true,
              backgroundColor: Colors.grey[900],
              title: const Column(
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: Colors.orange,
                    size: 48,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Cambiar Contraseña",
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Para cambiar tu contraseña, primero ingresa tu contraseña actual y luego la nueva contraseña.",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: currentPasswordController,
                        obscureText: true,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 18),
                        decoration: const InputDecoration(
                          labelText: "Contraseña Actual",
                          labelStyle: TextStyle(
                            color: Colors.orange,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.orange),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.orange, width: 2),
                          ),
                          prefixIcon: Icon(Icons.lock, color: Colors.orange),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa tu contraseña actual';
                          }
                          if (value.length < 6) {
                            return 'La contraseña debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: newPasswordController,
                        obscureText: true,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 18),
                        decoration: const InputDecoration(
                          labelText: "Nueva Contraseña",
                          labelStyle: TextStyle(
                            color: Colors.orange,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.orange),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.orange, width: 2),
                          ),
                          prefixIcon:
                              Icon(Icons.lock_outline, color: Colors.orange),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa la nueva contraseña';
                          }
                          if (value.length < 6) {
                            return 'La contraseña debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 18),
                        decoration: const InputDecoration(
                          labelText: "Confirmar Nueva Contraseña",
                          labelStyle: TextStyle(
                            color: Colors.orange,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.orange),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.orange, width: 2),
                          ),
                          prefixIcon:
                              Icon(Icons.lock_outline, color: Colors.orange),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Confirma la nueva contraseña';
                          }
                          if (value != newPasswordController.text) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.blueAccent.withAlpha(60)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.blueAccent, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "La nueva contraseña debe tener al menos 6 caracteres. Asegúrate de recordarla para tu próximo inicio de sesión.",
                                style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Forgot password option
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _showForgotPasswordFromSettingsDialog();
                        },
                        icon: const Icon(Icons.help_outline,
                            color: Colors.orangeAccent, size: 18),
                        label: const Text(
                          "¿Olvidaste tu contraseña actual?",
                          style: TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isLoading ? null : () => Navigator.pop(dialogContext),
                  child: const Text(
                    "CANCELAR",
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          setDialogState(() => isLoading = true);

                          try {
                            final user = FirebaseAuth.instance.currentUser;
                            final email = user?.email;

                            if (user == null || email == null) {
                              throw Exception("No hay usuario autenticado");
                            }

                            // Re-authenticate user with current password
                            final credential = EmailAuthProvider.credential(
                              email: email,
                              password: currentPasswordController.text.trim(),
                            );

                            await user.reauthenticateWithCredential(credential);

                            // Update password
                            await user.updatePassword(
                                newPasswordController.text.trim());

                            if (!context.mounted) return;
                            Navigator.pop(dialogContext);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text("Contraseña actualizada exitosamente"),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } on FirebaseAuthException catch (e) {
                            String errorMessage =
                                "Error al cambiar la contraseña";

                            if (e.code == 'wrong-password') {
                              errorMessage =
                                  "La contraseña actual es incorrecta";
                            } else if (e.code == 'weak-password') {
                              errorMessage = "La nueva contraseña es muy débil";
                            } else if (e.code == 'requires-recent-login') {
                              errorMessage =
                                  "Requiere inicio de sesión reciente. Cierra sesión y vuelve a entrar";
                            }

                            setDialogState(() => isLoading = false);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(errorMessage),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } catch (e) {
                            setDialogState(() => isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Error: ${e.toString()}"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "CAMBIAR CONTRASEÑA",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showForgotPasswordFromSettingsDialog() {
    final TextEditingController resetEmailController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
      scrollable: true,
              backgroundColor: Colors.grey[900],
              title: const Column(
                children: [
                  Icon(
                    Icons.lock_reset,
                    color: Colors.orange,
                    size: 48,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Recuperar Contraseña",
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Ingresa el correo de recuperación asociado a tu cuenta. Te enviaremos un enlace para restablecer tu contraseña.",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Email Field
                      TextFormField(
                        controller: resetEmailController,
                        keyboardType: TextInputType.emailAddress,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 18),
                        decoration: const InputDecoration(
                          labelText: "Correo Electrónico",
                          hintText: "El correo que registraste",
                          hintStyle:
                              TextStyle(color: Colors.white30, fontSize: 14),
                          labelStyle: TextStyle(
                            color: Colors.orange,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.orange),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.orange, width: 2),
                          ),
                          prefixIcon: Icon(Icons.email, color: Colors.orange),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu correo';
                          }
                          final emailRegex =
                              RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegex.hasMatch(value)) {
                            return 'Ingresa un correo válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.blueAccent.withAlpha(60)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.blueAccent, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Revisa tu bandeja de entrada y carpeta de spam. El enlace expira en 1 hora.",
                                style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    "CANCELAR",
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          setDialogState(() => isLoading = true);

                          final String email =
                              resetEmailController.text.trim().toLowerCase();
                          final user = FirebaseAuth.instance.currentUser;

                          if (user == null) {
                            setDialogState(() => isLoading = false);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    "No hay usuario autenticado. Inicia sesión nuevamente."),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          try {
                            // Get user document directly by UID (no query needed - avoids permission issues)
                            final userDoc = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .get();

                            if (!userDoc.exists) {
                              setDialogState(() => isLoading = false);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      "No se encontró información de recuperación"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            final userData =
                                userDoc.data() as Map<String, dynamic>;
                            final storedRecoveryEmail =
                                userData['recovery_email'] as String?;

                            if (storedRecoveryEmail == null ||
                                storedRecoveryEmail.isEmpty) {
                              setDialogState(() => isLoading = false);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      "No hay correo de recuperación configurado"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            if (storedRecoveryEmail.toLowerCase().trim() !=
                                email) {
                              setDialogState(() => isLoading = false);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      "El correo no coincide con el registrado"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            // DEBUG: Print what we're about to do
                            debugPrint(
                                'Sending password reset to: $storedRecoveryEmail');
                            debugPrint(
                                'Current user email in Auth: ${user.email}');

                            // NOTE: Firebase Auth can only send password resets to the user's primary email
                            // (the fake @televisa.com email), NOT to alternate/recovery emails stored in Firestore.
                            // The recovery email verification only works if it matches the Firebase Auth email.
                            //
                            // REAL FIX NEEDED: Create a Cloud Function that uses Firebase Admin SDK
                            // to generate a password reset link and send it via custom email to the recovery email.
                            //
                            // For now, we try sending to recovery email but it will only work if user
                            // manually set their Firebase Auth email to match recovery email in Firebase Console.

                            await FirebaseAuth.instance.sendPasswordResetEmail(
                              email: storedRecoveryEmail,
                            );

                            if (!context.mounted) return;
                            Navigator.pop(dialogContext);

                            // Show success dialog inline
                            await showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext successContext) {
                                return AlertDialog(
      scrollable: true,
                                  backgroundColor: Colors.grey[900],
                                  title: const Row(
                                    children: [
                                      Icon(Icons.check_circle,
                                          color: Colors.green, size: 32),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          "¡Enlace Enviado!",
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: Text(
                                    "Se ha enviado un enlace de recuperación a:\n$storedRecoveryEmail\n\nRevisa tu bandeja de entrada (incluyendo spam). El enlace expirará en 1 hora.",
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 14),
                                  ),
                                  actions: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                      ),
                                      onPressed: () =>
                                          Navigator.pop(successContext),
                                      child: const Text(
                                        "ENTENDIDO",
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          } on FirebaseAuthException catch (e) {
                            setDialogState(() => isLoading = false);
                            String errorMessage = "Error al enviar el correo";

                            if (e.code == 'user-not-found') {
                              errorMessage = "No existe cuenta con ese correo";
                            } else if (e.code == 'invalid-email') {
                              errorMessage = "Formato de correo inválido";
                            } else if (e.code == 'too-many-requests') {
                              errorMessage =
                                  "Demasiados intentos. Intenta más tarde";
                            }

                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(errorMessage),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } catch (e) {
                            setDialogState(() => isLoading = false);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Error: ${e.toString()}"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "ENVIAR ENLACE",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: _isDarkMode ? Colors.white12 : const Color(0xFFCBD5E1),
            width: 1.5,
          ),
        ),
        title: Text("INFORMACIÓN",
            style: TextStyle(
                color: _isDarkMode ? Colors.orange : const Color(0xFFC2410C),
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Mi Nómina Pro",
                style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            Text("Versión v.23.20.3 20/11/26",
                style: TextStyle(
                    color: _isDarkMode ? Colors.orangeAccent : const Color(0xFFC2410C),
                    fontSize: 14)),
            Divider(
                color: _isDarkMode ? Colors.white38 : const Color(0xFFCBD5E1),
                height: 25),
            Text(
                "Esta aplicación es una herramienta independiente creada con el objetivo de ayudar a los usuarios a estimar y visualizar cierta información de forma práctica.\n\nNo es una aplicación oficial ni está afiliada, respaldada o relacionada de ninguna manera con Televisa.\n\nLas cantidades, cálculos o resultados mostrados son estimaciones generadas con base en la información disponible al momento de su desarrollo. Estos valores pueden contener errores o variaciones, ya que Televisa puede modificar en cualquier momento sus métodos de cálculo, agregar conceptos adicionales o aplicar retenciones distintas sin previo aviso.\n\nPor lo tanto, la información proporcionada por esta aplicación debe considerarse únicamente como una referencia orientativa y no como un dato definitivo, oficial o garantizado.",
                style: TextStyle(
                    color: _isDarkMode ? Colors.white70 : Colors.black,
                    fontSize: 13)),
            Divider(
                color: _isDarkMode ? Colors.white38 : const Color(0xFFCBD5E1),
                height: 25),
            Text("Desarrollado por: MD",
                style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black,
                    fontSize: 16)),
            const SizedBox(height: 12),
            Text("Sugerencias y/o quejas a: minominapro@gmail.com",
                style: TextStyle(
                    fontSize: 14,
                    color: _isDarkMode ? Colors.white70 : Colors.black)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CERRAR",
                style: TextStyle(
                    color: _isDarkMode ? Colors.orange : const Color(0xFFC2410C))),
          )
        ],
      ),
    );
  }


}
