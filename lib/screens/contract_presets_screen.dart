part of '../main.dart';

class _ContractPresetsScreen extends StatefulWidget {
  final _TelevisaAppState appState;

  const _ContractPresetsScreen({
    required this.appState,
  });

  @override
  State<_ContractPresetsScreen> createState() => _ContractPresetsScreenState();
}

typedef ContractPresetsScreen = _ContractPresetsScreen;

class _ContractPresetsScreenState extends State<_ContractPresetsScreen> {
  _TelevisaAppState get _appState => widget.appState;
  bool get _isDarkMode => _appState._isDarkMode;

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
    final DateTime today = DateTime(now.year, now.month, now.day);

    final activeContract = _appState._getContractForDate(now);
    final String activeType =
        (activeContract['type'] ?? 'contrato_base').toString();
    final String activeName =
        (activeContract['name'] ?? 'Contrato Base').toString();

    final bool isContratoBase = (activeType == 'contrato_base');
    final bool isSindicalizado = (activeType == 'sindicalizado_2026');
    final bool isConfianza = (activeType == 'confianza');

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
          "Plantillas de Contrato",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: textColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Explanatory Header
            Container(
              width: double.infinity,
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withAlpha(_isDarkMode ? 35 : 25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.badge_rounded,
                      color: accentColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Esquemas y Plantillas Rápidas",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Selecciona un esquema predefinido para configurar automáticamente porcentajes y prestaciones de tu nómina. Puedes aplicarlo a todo tu historial o programar vigencias a partir de una fecha.",
                          style: TextStyle(
                            fontSize: 13,
                            color: subtextColor,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3 Preset Cards Section
            Text(
              "PLANTILLAS DISPONIBLES",
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            _buildPresetCard(
              title: "Contrato Base (2.0% / 2.0%)",
              subtitle: "Fomento 2.0% • Cuota 2.0% cada quincena",
              badgeText: "PREDETERMINADO",
              icon: Icons.badge_rounded,
              isSelected: isContratoBase,
              onTap: () => _showApplyContractPresetDialog(
                presetType: 'contrato_base',
                title: "Contrato Base (2.0% / 2.0%)",
                fomento: 2.0,
                cuota: 2.0,
                frequency: 'both',
                vales: _appState._valesFomentoCulturalAmount,
                valesEnabled: _appState._valesFomentoCulturalEnabled,
              ),
            ),
            _buildPresetCard(
              title: "Sindicalizado 2026 (4.6% / 4%)",
              subtitle: "Fomento 4.6% • Cuota 4.0% en 2da quincena",
              badgeText: "SINDICALIZADO 2026",
              icon: Icons.shield_rounded,
              isSelected: isSindicalizado,
              onTap: () => _showApplyContractPresetDialog(
                presetType: 'sindicalizado_2026',
                title: "Sindicalizado 2026 (4.6% / 4%)",
                fomento: 4.6,
                cuota: 4.0,
                frequency: 'second_only',
                vales: _appState._valesFomentoCulturalAmount,
                valesEnabled: _appState._valesFomentoCulturalEnabled,
              ),
            ),
            _buildPresetCard(
              title: "Confianza / Sin Sindicato (0% / 0%)",
              subtitle: "Fomento 0% • Cuota 0% • Sin cuota sindical",
              badgeText: "SIN SINDICATO",
              icon: Icons.person_outline_rounded,
              isSelected: isConfianza,
              onTap: () => _showApplyContractPresetDialog(
                presetType: 'confianza',
                title: "Confianza / Sin Sindicato (0% / 0%)",
                fomento: 0.0,
                cuota: 0.0,
                frequency: 'none',
                vales: _appState._valesFomentoCulturalAmount,
                valesEnabled: _appState._valesFomentoCulturalEnabled,
              ),
            ),

            Divider(
              color: borderColor,
              height: 40,
            ),

            // "VIGENCIAS Y PERIODOS DE CONTRATO" Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "VIGENCIAS Y PERIODOS DE CONTRATO",
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Historial de esquemas aplicados por rango de fechas",
                        style: TextStyle(
                          color: subtextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // "+ AGREGAR CAMBIO DE CONTRATO" Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size.fromHeight(46),
                elevation: 2,
              ),
              icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
              label: const Text(
                "+ AGREGAR CAMBIO DE CONTRATO",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
              onPressed: () async {
                final updated = await _showAddOrEditContractPeriodDialog();
                if (updated == true) {
                  setState(() {});
                }
              },
            ),
            const SizedBox(height: 16),

            // Itemized list or empty state card
            if (_appState._contractHistory.isEmpty)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.history_toggle_off_rounded,
                      size: 48,
                      color: _isDarkMode
                          ? Colors.white30
                          : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Sin vigencias adicionales registradas",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Actualmente aplica la plantilla global seleccionada ($activeName) para todo tu historial de cálculo.\n\nSi tuviste o tendrás un cambio de contrato a partir de una fecha específica, puedes agregarlo con el botón de arriba.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: subtextColor,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _appState._contractHistory.length,
                itemBuilder: (ctx, idx) {
                  final entry = _appState._contractHistory[idx];
                  final String title = (entry['name'] ??
                          entry['contract_type'] ??
                          entry['type'] ??
                          'Contrato')
                      .toString();
                  final double fomento =
                      (entry['fomento'] as num?)?.toDouble() ?? 2.0;
                  final double cuota =
                      (entry['cuota'] as num?)?.toDouble() ?? 2.0;
                  final String freq =
                      (entry['frequency'] ?? entry['cuota_frequency'] ?? 'both')
                          .toString();
                  final String freqText = freq == 'second_only'
                      ? '2da quincena'
                      : freq == 'none'
                          ? 'Sin cuota'
                          : 'Cada quincena';

                  final String? sDateStr = entry['start_date']?.toString();
                  final String? eDateStr = entry['end_date']?.toString();
                  final DateTime? sDate = sDateStr != null
                      ? DateTime.tryParse(sDateStr)
                      : null;
                  final DateTime? eDate = eDateStr != null &&
                          eDateStr.isNotEmpty &&
                          eDateStr != 'null'
                      ? DateTime.tryParse(eDateStr)
                      : null;

                  bool isVigente = false;
                  if (sDate != null) {
                    final normStart =
                        DateTime(sDate.year, sDate.month, sDate.day);
                    if (!today.isBefore(normStart)) {
                      if (eDate == null) {
                        isVigente = true;
                      } else {
                        final normEnd =
                            DateTime(eDate.year, eDate.month, eDate.day);
                        if (!today.isAfter(normEnd)) {
                          isVigente = true;
                        }
                      }
                    }
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isVigente
                            ? (_isDarkMode
                                ? Colors.greenAccent.withAlpha(120)
                                : const Color(0xFF16A34A))
                            : borderColor,
                        width: isVigente ? 1.5 : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(_isDarkMode ? 20 : 5),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: textColor,
                                ),
                              ),
                            ),
                            if (isVigente)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _isDarkMode
                                      ? Colors.green.withAlpha(40)
                                      : const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _isDarkMode
                                        ? Colors.greenAccent
                                        : const Color(0xFF16A34A),
                                  ),
                                ),
                                child: Text(
                                  "VIGENTE",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _isDarkMode
                                        ? Colors.greenAccent
                                        : const Color(0xFF15803D),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Fomento: ${fomento.toStringAsFixed(1)}% • Cuota: ${cuota.toStringAsFixed(1)}% ($freqText)",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "Desde: ${sDateStr ?? 'Inicio'}   Hasta: ${eDateStr ?? 'Presente (Indefinido)'}",
                          style: TextStyle(
                            fontSize: 11,
                            color: subtextColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              icon: const Icon(
                                Icons.edit_calendar_rounded,
                                size: 16,
                              ),
                              label: const Text(
                                "Editar",
                                style: TextStyle(fontSize: 12),
                              ),
                              onPressed: () async {
                                final updated =
                                    await _showAddOrEditContractPeriodDialog(
                                  existingPeriod: entry,
                                  editIndex: idx,
                                );
                                if (updated == true) {
                                  setState(() {});
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 16,
                              ),
                              label: const Text(
                                "Eliminar",
                                style: TextStyle(fontSize: 12),
                              ),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (dCtx) => Theme(
                                    data: (_isDarkMode
                                            ? ThemeData.dark()
                                            : ThemeData.light())
                                        .copyWith(
                                      colorScheme: (_isDarkMode
                                              ? const ColorScheme.dark()
                                              : const ColorScheme.light())
                                          .copyWith(
                                        surface: cardBg,
                                      ),
                                    ),
                                    child: AlertDialog(
                                      backgroundColor: cardBg,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      title: Text(
                                        "Eliminar vigencia",
                                        style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      content: Text(
                                        "¿Deseas eliminar el periodo de contrato '$title'?",
                                        style: TextStyle(color: subtextColor),
                                      ),
                                      actions: [
                                        TextButton(
                                          style: TextButton.styleFrom(
                                            foregroundColor: _isDarkMode
                                                ? Colors.white70
                                                : const Color(0xFF64748B),
                                          ),
                                          onPressed: () =>
                                              Navigator.pop(dCtx, false),
                                          child: const Text("CANCELAR"),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.redAccent,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: () =>
                                              Navigator.pop(dCtx, true),
                                          child: const Text("ELIMINAR"),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                                if (confirm == true) {
                                  _appState._contractHistory.removeAt(idx);
                                  await _appState._saveData(
                                      checkSalaryChange: false);
                                  setState(() {});
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetCard({
    required String title,
    required String subtitle,
    required String badgeText,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final Color accentColor =
        _isDarkMode ? Colors.orange : const Color(0xFFC2410C);
    final Color cardBg = _isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final Color borderColor = isSelected
        ? (_isDarkMode ? Colors.orange : const Color(0xFFC2410C))
        : (_isDarkMode ? Colors.white12 : const Color(0xFFCBD5E1));
    final Color textColor = _isDarkMode ? Colors.white : Colors.black;
    final Color subtextColor =
        _isDarkMode ? Colors.white60 : const Color(0xFF475569);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
          width: isSelected ? 2.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(_isDarkMode ? 30 : 10),
            blurRadius: 6,
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
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor.withAlpha(_isDarkMode ? 50 : 35)
                        : accentColor.withAlpha(_isDarkMode ? 25 : 15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isSelected ? Icons.check_circle_rounded : icon,
                    color: isSelected
                        ? (_isDarkMode
                            ? Colors.orangeAccent
                            : const Color(0xFFC2410C))
                        : accentColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (_isDarkMode
                                      ? Colors.green.withAlpha(40)
                                      : const Color(0xFFDCFCE7))
                                  : (_isDarkMode
                                      ? Colors.white10
                                      : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isSelected
                                    ? (_isDarkMode
                                        ? Colors.greenAccent
                                        : const Color(0xFF16A34A))
                                    : Colors.transparent,
                              ),
                            ),
                            child: Text(
                              isSelected ? "ACTIVO" : badgeText,
                              style: TextStyle(
                                color: isSelected
                                    ? (_isDarkMode
                                        ? Colors.greenAccent
                                        : const Color(0xFF15803D))
                                    : subtextColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: subtextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showApplyContractPresetDialog({
    required String presetType,
    required String title,
    required double fomento,
    required double cuota,
    required String frequency,
    required double vales,
    required bool valesEnabled,
  }) async {
    int applyScope = 0; // 0 = todo el historial, 1 = a partir de fecha
    DateTime selectedDate = DateTime.now();

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return Theme(
          data: (_isDarkMode ? ThemeData.dark() : ThemeData.light()).copyWith(
            colorScheme: (_isDarkMode
                    ? const ColorScheme.dark()
                    : const ColorScheme.light())
                .copyWith(
              surface: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
            ),
          ),
          child: StatefulBuilder(
            builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor:
                  _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.tune_rounded,
                      color:
                          _isDarkMode ? Colors.orange : const Color(0xFFC2410C)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "¿Cómo deseas aplicar esta plantilla de contrato?",
                      style: TextStyle(
                        color: _isDarkMode
                            ? Colors.white70
                            : const Color(0xFF475569),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Scope Option 1: Todo el historial
                    InkWell(
                      onTap: () => setDialogState(() => applyScope = 0),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: applyScope == 0
                              ? (_isDarkMode
                                  ? Colors.orange.withAlpha(30)
                                  : const Color(0xFFFFEDD5))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: applyScope == 0
                                ? (_isDarkMode
                                    ? Colors.orange
                                    : const Color(0xFFEA580C))
                                : (_isDarkMode
                                    ? Colors.white12
                                    : const Color(0xFFCBD5E1)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              applyScope == 0
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: applyScope == 0
                                  ? (_isDarkMode
                                      ? Colors.orange
                                      : const Color(0xFFC2410C))
                                  : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Aplicar a todo el historial",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: _isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    "Actualiza la configuración global para todos los cálculos pasados y futuros.",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _isDarkMode
                                          ? Colors.white60
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Scope Option 2: A partir de una fecha específica
                    InkWell(
                      onTap: () => setDialogState(() => applyScope = 1),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: applyScope == 1
                              ? (_isDarkMode
                                  ? Colors.orange.withAlpha(30)
                                  : const Color(0xFFFFEDD5))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: applyScope == 1
                                ? (_isDarkMode
                                    ? Colors.orange
                                    : const Color(0xFFEA580C))
                                : (_isDarkMode
                                    ? Colors.white12
                                    : const Color(0xFFCBD5E1)),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  applyScope == 1
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  color: applyScope == 1
                                      ? (_isDarkMode
                                          ? Colors.orange
                                          : const Color(0xFFC2410C))
                                      : Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "A partir de una fecha / quincena específica",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: _isDarkMode
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        "Registra una vigencia; los periodos anteriores conservan sus parámetros originales.",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _isDarkMode
                                              ? Colors.white60
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (applyScope == 1) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _isDarkMode
                                      ? const Color(0xFF0F172A)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _isDarkMode
                                        ? Colors.white24
                                        : const Color(0xFFCBD5E1),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_month_rounded,
                                            size: 16,
                                            color: _isDarkMode
                                                ? Colors.orange
                                                : const Color(0xFFC2410C)),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Vigencia desde: ${DateFormat('yyyy-MM-dd').format(selectedDate)}",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _isDarkMode
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: () async {
                                        final picked = await showDatePicker(
                                          context: ctx,
                                          initialDate: selectedDate,
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime(2035),
                                        );
                                        if (picked != null) {
                                          setDialogState(() {
                                            selectedDate = picked;
                                          });
                                        }
                                      },
                                      child: const Text("CAMBIAR",
                                          style: TextStyle(fontSize: 11)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Text(
                      "Parámetros a configurar:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: _isDarkMode
                            ? Colors.white70
                            : const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildPresetDetailRow(
                        "Fomento Eficiencia:", "${fomento.toStringAsFixed(1)} %"),
                    _buildPresetDetailRow(
                        "Cuota Sindical:",
                        "${cuota.toStringAsFixed(1)} % (${frequency == 'second_only' ? '2da Qna' : frequency == 'none' ? 'Sin cuota' : 'Cada Qna'})"),
                    _buildPresetDetailRow(
                        "Vales Fomento Cultural:",
                        valesEnabled && vales > 0
                            ? "\$ ${vales.toStringAsFixed(2)} (Sin cambio)"
                            : "Sin cambio"),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: _isDarkMode
                        ? Colors.white70
                        : const Color(0xFF64748B),
                  ),
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text("CANCELAR"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isDarkMode ? Colors.orange : const Color(0xFFC2410C),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text("APLICAR"),
                ),
              ],
            );
          },
        ),
      );
    },
  );

    if (confirm == true) {
      if (applyScope == 0) {
        // Global overwrite
        _appState._rebuild(() {
          _appState._contractHistory = [];
          _appState._fomentoController.text = fomento.toString();
          _appState._cuotaController.text = cuota.toString();
          _appState._fomentoHistory = [];
          _appState._cuotaHistory = [];
          _appState._valesFomentoCulturalAmount = vales;
          _appState._valesFomentoCulturalAmountController.text =
              vales > 0 ? vales.toStringAsFixed(2) : "";
          _appState._valesFomentoCulturalEnabled = valesEnabled;
        });
      } else {
        // Effective date based
        final String sDateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
        _appState._rebuild(() {
          if (_appState._contractHistory.isEmpty) {
            final double oldFom =
                double.tryParse(_appState._fomentoController.text) ?? 2.0;
            final double oldCuo =
                double.tryParse(_appState._cuotaController.text) ?? 2.0;
            String oldType = 'contrato_base';
            String oldFreq = 'both';
            if ((oldFom - 4.6).abs() < 0.05 && (oldCuo - 4.0).abs() < 0.05) {
              oldType = 'sindicalizado_2026';
              oldFreq = 'second_only';
            } else if (oldFom <= 0.001 && oldCuo <= 0.001) {
              oldType = 'confianza';
              oldFreq = 'none';
            }
            final DateTime dayBefore =
                selectedDate.subtract(const Duration(days: 1));
            _appState._contractHistory.add({
              'type': oldType,
              'contract_type': oldType,
              'fomento': oldFom,
              'cuota': oldCuo,
              'frequency': oldFreq,
              'cuota_frequency': oldFreq,
              'name': oldType == 'sindicalizado_2026'
                  ? 'Sindicalizado 2026'
                  : oldType == 'confianza'
                      ? 'Confianza / Sin Sindicato'
                      : 'Contrato Base',
              'start_date': '2026-01-01',
              'end_date': DateFormat('yyyy-MM-dd').format(dayBefore),
            });
          } else {
            final DateTime dayBefore =
                selectedDate.subtract(const Duration(days: 1));
            final String dayBeforeStr =
                DateFormat('yyyy-MM-dd').format(dayBefore);
            for (var entry in _appState._contractHistory) {
              final String s =
                  (entry['start_date'] ?? entry['effective_date'] ?? '')
                      .toString();
              final String? e = entry['end_date']?.toString();
              if ((e == null || e.isEmpty || e == 'null') &&
                  s.compareTo(sDateStr) < 0) {
                entry['end_date'] = dayBeforeStr;
              }
            }
          }

          _appState._contractHistory.add({
            'type': presetType,
            'contract_type': presetType,
            'fomento': fomento,
            'cuota': cuota,
            'frequency': frequency,
            'cuota_frequency': frequency,
            'name': title,
            'start_date': sDateStr,
            'end_date': null,
          });

          _appState._contractHistory.sort((a, b) => (a['start_date'] ?? '')
              .toString()
              .compareTo((b['start_date'] ?? '').toString()));

          final DateTime today = DateTime.now();
          if (!selectedDate
              .isAfter(DateTime(today.year, today.month, today.day))) {
            _appState._fomentoController.text = fomento.toString();
            _appState._cuotaController.text = cuota.toString();
          }
        });
      }

      await _appState._saveData(checkSalaryChange: false);
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Plantilla '$title' configurada correctamente."),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<bool?> _showAddOrEditContractPeriodDialog({
    Map<String, dynamic>? existingPeriod,
    int? editIndex,
  }) async {
    String selectedType = existingPeriod?['type'] ??
        existingPeriod?['contract_type'] ??
        'contrato_base';
    DateTime startDate = existingPeriod?['start_date'] != null
        ? (DateTime.tryParse(existingPeriod!['start_date'].toString()) ??
            DateTime.now())
        : DateTime.now();
    DateTime? endDate = (existingPeriod?['end_date'] != null &&
            existingPeriod!['end_date'].toString().isNotEmpty &&
            existingPeriod['end_date'] != 'null')
        ? DateTime.tryParse(existingPeriod['end_date'].toString())
        : null;

    double fomento = (existingPeriod?['fomento'] as num?)?.toDouble() ??
        (selectedType == 'sindicalizado_2026'
            ? 4.6
            : selectedType == 'confianza'
                ? 0.0
                : 2.0);
    double cuota = (existingPeriod?['cuota'] as num?)?.toDouble() ??
        (selectedType == 'sindicalizado_2026'
            ? 4.0
            : selectedType == 'confianza'
                ? 0.0
                : 2.0);
    String frequency = existingPeriod?['frequency'] ??
        (selectedType == 'sindicalizado_2026'
            ? 'second_only'
            : selectedType == 'confianza'
                ? 'none'
                : 'both');

    return showDialog<bool>(
      context: context,
      builder: (dlgCtx) {
        return Theme(
          data: (_isDarkMode ? ThemeData.dark() : ThemeData.light()).copyWith(
            colorScheme: (_isDarkMode
                    ? const ColorScheme.dark()
                    : const ColorScheme.light())
                .copyWith(
              surface: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
            ),
          ),
          child: StatefulBuilder(
            builder: (sbCtx, setDlgState) {
            void updateTypePreset(String t) {
              setDlgState(() {
                selectedType = t;
                if (t == 'contrato_base') {
                  fomento = 2.0;
                  cuota = 2.0;
                  frequency = 'both';
                } else if (t == 'sindicalizado_2026') {
                  fomento = 4.6;
                  cuota = 4.0;
                  frequency = 'second_only';
                } else if (t == 'confianza') {
                  fomento = 0.0;
                  cuota = 0.0;
                  frequency = 'none';
                }
              });
            }

            return AlertDialog(
              backgroundColor:
                  _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.calendar_month_rounded,
                      color: _isDarkMode
                          ? Colors.orange
                          : const Color(0xFFC2410C)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      editIndex != null
                          ? "Editar periodo de contrato"
                          : "Nuevo periodo de contrato",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: _isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Plantilla de Contrato:",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _isDarkMode
                                ? Colors.white70
                                : const Color(0xFF334155))),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      isExpanded: true,
                      dropdownColor: _isDarkMode
                          ? const Color(0xFF1E293B)
                          : Colors.white,
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black87,
                        fontSize: 14,
                      ),
                      iconEnabledColor:
                          _isDarkMode ? Colors.white70 : Colors.black54,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'contrato_base',
                          child: Text(
                            "Contrato Base (2.0% / 2.0%)",
                            style: TextStyle(
                              color:
                                  _isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'sindicalizado_2026',
                          child: Text(
                            "Sindicalizado 2026 (4.6% / 4%)",
                            style: TextStyle(
                              color:
                                  _isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'confianza',
                          child: Text(
                            "Confianza / Sin Sindicato (0% / 0%)",
                            style: TextStyle(
                              color:
                                  _isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) updateTypePreset(val);
                      },
                    ),
                    const SizedBox(height: 14),
                    Text(
                      "Fomento: ${fomento.toStringAsFixed(1)}% • Cuota: ${cuota.toStringAsFixed(1)}% (${frequency == 'second_only' ? '2da quincena' : frequency == 'none' ? 'Sin cuota' : 'Cada quincena'})",
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: _isDarkMode
                            ? Colors.white60
                            : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text("Fecha de inicio:",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _isDarkMode
                                ? Colors.white70
                                : const Color(0xFF334155))),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: dlgCtx,
                          initialDate: startDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setDlgState(() => startDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _isDarkMode
                                ? Colors.white24
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('yyyy-MM-dd').format(startDate),
                              style: TextStyle(
                                  color: _isDarkMode
                                      ? Colors.white
                                      : Colors.black87),
                            ),
                            Icon(Icons.calendar_today,
                                size: 16,
                                color: _isDarkMode
                                    ? Colors.orange
                                    : const Color(0xFFC2410C)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text("Fecha de término (opcional):",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _isDarkMode
                                ? Colors.white70
                                : const Color(0xFF334155))),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: dlgCtx,
                          initialDate: endDate ?? startDate,
                          firstDate: startDate,
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setDlgState(() => endDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _isDarkMode
                                ? Colors.white24
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              endDate != null
                                  ? DateFormat('yyyy-MM-dd').format(endDate!)
                                  : "Indefinido / Vigente",
                              style: TextStyle(
                                color: endDate != null
                                    ? (_isDarkMode
                                        ? Colors.white
                                        : Colors.black87)
                                    : (_isDarkMode
                                        ? Colors.white38
                                        : const Color(0xFF94A3B8)),
                              ),
                            ),
                            if (endDate != null)
                              InkWell(
                                onTap: () => setDlgState(() => endDate = null),
                                child: Icon(
                                  Icons.clear,
                                  size: 18,
                                  color: _isDarkMode
                                      ? Colors.white70
                                      : const Color(0xFF64748B),
                                ),
                              )
                            else
                              Icon(Icons.calendar_today,
                                  size: 16,
                                  color: _isDarkMode
                                      ? Colors.orange
                                      : const Color(0xFFC2410C)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: _isDarkMode
                        ? Colors.white70
                        : const Color(0xFF64748B),
                  ),
                  onPressed: () => Navigator.pop(dlgCtx, false),
                  child: const Text("CANCELAR"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isDarkMode ? Colors.orange : const Color(0xFFC2410C),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final String titleName = selectedType ==
                            'sindicalizado_2026'
                        ? 'Sindicalizado 2026'
                        : selectedType == 'confianza'
                            ? 'Confianza / Sin Sindicato'
                            : 'Contrato Base';

                    final newEntry = {
                      'type': selectedType,
                      'contract_type': selectedType,
                      'fomento': fomento,
                      'cuota': cuota,
                      'frequency': frequency,
                      'cuota_frequency': frequency,
                      'name': titleName,
                      'start_date': DateFormat('yyyy-MM-dd').format(startDate),
                      'end_date': endDate != null
                          ? DateFormat('yyyy-MM-dd').format(endDate!)
                          : null,
                    };

                    _appState._rebuild(() {
                      if (editIndex != null &&
                          editIndex < _appState._contractHistory.length) {
                        _appState._contractHistory[editIndex] = newEntry;
                      } else {
                        _appState._contractHistory.add(newEntry);
                      }

                      _appState._contractHistory.sort((a, b) =>
                          (a['start_date'] ?? '')
                              .toString()
                              .compareTo((b['start_date'] ?? '').toString()));
                    });

                    await _appState._saveData(checkSalaryChange: false);
                    if (dlgCtx.mounted) {
                      Navigator.pop(dlgCtx, true);
                    }
                  },
                  child: const Text("GUARDAR"),
                ),
              ],
            );
          },
        ),
      );
    },
  );
  }

  Widget _buildPresetDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: _isDarkMode ? Colors.white70 : const Color(0xFF334155),
                  fontSize: 13)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _isDarkMode ? Colors.white : Colors.black,
                  fontSize: 13)),
        ],
      ),
    );
  }
}
