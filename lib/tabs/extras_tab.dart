part of '../main.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _ExtrasTabExt on _TelevisaAppState {
  Widget _buildExtrasTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SECTION 1: LINKS
          Text("LINKS",
              style: TextStyle(
                  color: _isDarkMode ? Colors.orange : const Color(0xFFC2410C),
                  fontWeight: FontWeight.bold,
                  fontSize: 20)),
          const SizedBox(height: 15),
          _buildShareAppTile(),
          const SizedBox(height: 10),
          _buildLinkTile("Portal Televisa", Icons.work,
              "https://tuportaldevacaciones.televisaunivision.com/portaltv/inicio.aspx"),
          const SizedBox(height: 10),
          _buildLinkTile("Monedero Chedraui", Icons.shopping_bag,
              "https://monederodespensa.chedraui.com.mx/home"),
          const SizedBox(height: 25),
          Divider(
              color: _isDarkMode ? Colors.white24 : const Color(0xFFCBD5E1)),

          // SECTION 2: REDES WI-FI
          const SizedBox(height: 25),
          Text("REDES WI-FI",
              style: TextStyle(
                  color: _isDarkMode ? Colors.orange : const Color(0xFFC2410C),
                  fontWeight: FontWeight.bold,
                  fontSize: 20)),
          const SizedBox(height: 15),

          // Televisa San Angel
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.white.withAlpha(10) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: _isDarkMode
                  ? Border.all(color: Colors.orange.withAlpha(50))
                  : Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Televisa San Angel",
                    style: TextStyle(
                        color: _isDarkMode
                            ? Colors.white
                            : const Color(0xFF0F172A),
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                _buildWifiTile("TUGuest", r"4N1V$sI0N*TvsA",
                    note: "(Tiene acceso a Portal Televisa)"),
                Divider(
                    color:
                        _isDarkMode ? Colors.white24 : const Color(0xFFE2E8F0),
                    height: 20),
                _buildWifiTile("#tvsauniv", r"welcome.2021"),
                Divider(
                    color:
                        _isDarkMode ? Colors.white24 : const Color(0xFFE2E8F0),
                    height: 20),
                _buildWifiTile("SSID FORO-1", r"7oR0_$%1"),
                Divider(
                    color:
                        _isDarkMode ? Colors.white24 : const Color(0xFFE2E8F0),
                    height: 20),
                _buildWifiTile("SSID FORO-2", r"S4g_F0%2"),
                Divider(
                    color:
                        _isDarkMode ? Colors.white24 : const Color(0xFFE2E8F0),
                    height: 20),
                _buildWifiTile("SSID FORO-4", r"4_$%5gT3I3"),
                Divider(
                    color:
                        _isDarkMode ? Colors.white24 : const Color(0xFFE2E8F0),
                    height: 20),
                _buildWifiTile("SSID FORO-5", r"T3I3@F0r0_5"),
                Divider(
                    color:
                        _isDarkMode ? Colors.white24 : const Color(0xFFE2E8F0),
                    height: 20),
                _buildWifiTile("SSID FORO-6", r"SNG_$6/For0"),
                Divider(
                    color:
                        _isDarkMode ? Colors.white24 : const Color(0xFFE2E8F0),
                    height: 20),
                _buildWifiTile("SSID FORO-8", r"f0r0_53I/8",
                    note: "(Clave vieja, nos compartes la nueva?)"),
                Divider(
                    color:
                        _isDarkMode ? Colors.white24 : const Color(0xFFE2E8F0),
                    height: 20),
                _buildWifiTile("SSID FORO-9", r"9@_T3I3v*",
                    note: "(Clave vieja, nos compartes la nueva?)"),
                Divider(
                    color:
                        _isDarkMode ? Colors.white24 : const Color(0xFFE2E8F0),
                    height: 20),
                _buildWifiTile("SSID FORO-11", r"t3@v1s4/11"),
                Divider(
                    color:
                        _isDarkMode ? Colors.white24 : const Color(0xFFE2E8F0),
                    height: 20),
                _buildWifiTile("SSID FORO-12", r"T31e$srlJ"),
                Divider(
                    color:
                        _isDarkMode ? Colors.white24 : const Color(0xFFE2E8F0),
                    height: 20),
                _buildWifiTile("SSID FORO-14", r"14_@S4g/vI5a"),
                Divider(
                    color:
                        _isDarkMode ? Colors.white24 : const Color(0xFFE2E8F0),
                    height: 20),
                _buildWifiTile("SSID FORO-15", r"Sg3L/T3v15"),
              ],
            ),
          ),

          const SizedBox(height: 15),
          // Televisa Chapultepec (placeholder)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.white.withAlpha(5) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: _isDarkMode
                  ? Border.all(color: Colors.white24)
                  : Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Televisa Chapultepec",
                    style: TextStyle(
                        color: _isDarkMode
                            ? Colors.white70
                            : const Color(0xFF0F172A),
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                Text("Información no disponible",
                    style: TextStyle(
                        color: _isDarkMode
                            ? Colors.white38
                            : const Color(0xFF64748B),
                        fontSize: 14)),
              ],
            ),
          ),

          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isDarkMode
                  ? Colors.orange.withAlpha(20)
                  : const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: _isDarkMode
                      ? Colors.orange.withAlpha(60)
                      : const Color(0xFFFED7AA),
                  width: 1.2),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color:
                        _isDarkMode ? Colors.orange : const Color(0xFFC2410C),
                    size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Las redes pueden cambiar sin previo aviso, en caso de que quieras contribuir, favor de enviarnos un correo en Ajustes > Información. Ayudanos a encontrar las claves de las redes faltantes! :D",
                    style: TextStyle(
                        color: _isDarkMode
                            ? Colors.orangeAccent
                            : const Color(0xFF9A3412),
                        fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),
          Divider(
              color: _isDarkMode ? Colors.white24 : const Color(0xFFCBD5E1)),

          // SECTION 3: INFORMACIÓN GENERAL
          const SizedBox(height: 25),
          Text("INFORMACIÓN GENERAL",
              style: TextStyle(
                  color: _isDarkMode ? Colors.orange : const Color(0xFFC2410C),
                  fontWeight: FontWeight.bold,
                  fontSize: 20)),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.white.withAlpha(5) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: _isDarkMode
                  ? Border.all(color: Colors.white24)
                  : Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
            ),
            child: Center(
              child: Text(
                "Próximamente...",
                style: TextStyle(
                    color: _isDarkMode
                        ? Colors.white38
                        : const Color(0xFF64748B),
                    fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTile(String title, IconData icon, String url) {
    return ListTile(
      leading: Icon(icon,
          color: _isDarkMode ? Colors.orange : const Color(0xFFC2410C),
          size: 28),
      title: Text(title,
          style: TextStyle(
              color: _isDarkMode ? Colors.white : const Color(0xFF1E293B),
              fontSize: 16,
              fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.open_in_new,
          color:
              _isDarkMode ? Colors.orangeAccent : const Color(0xFFC2410C),
          size: 20),
      tileColor: _isDarkMode ? Colors.white.withAlpha(10) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: _isDarkMode
            ? BorderSide(color: Colors.orange.withAlpha(30))
            : const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
      ),
      onTap: () async {
        final Uri uri = Uri.parse(url);
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("No se pudo abrir: $url")),
            );
          }
        }
      },
    );
  }

  Widget _buildShareAppTile() {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _isDarkMode
              ? Colors.green.withAlpha(30)
              : const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: _isDarkMode
                  ? Colors.green.withAlpha(80)
                  : const Color(0xFF86EFAC)),
        ),
        child: Icon(Icons.share,
            color: _isDarkMode
                ? Colors.greenAccent
                : const Color(0xFF15803D),
            size: 28),
      ),
      title: Text("Compartir App",
          style: TextStyle(
              color: _isDarkMode ? Colors.white : const Color(0xFF1E293B),
              fontSize: 16,
              fontWeight: FontWeight.w500)),
      subtitle: Text("¡Invita a tus compañeros utilizando este boton!",
          style: TextStyle(
              color: _isDarkMode ? Colors.white54 : const Color(0xFF64748B),
              fontSize: 12)),
      trailing: Icon(Icons.arrow_forward_ios,
          color: _isDarkMode
              ? Colors.greenAccent
              : const Color(0xFF15803D),
          size: 18),
      tileColor: _isDarkMode ? Colors.white.withAlpha(10) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: _isDarkMode
            ? BorderSide(color: Colors.green.withAlpha(50))
            : const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
      ),
      onTap: () async {
        const String appUrl = 'https://nomina-televisa-v2.web.app/';
        const String shareMessage =
            '¡Hola! Te invito a usar Mi Nómina Pro, la app para llevar el control de tus horas y nómina de Televisa. '
            'Es muy útil y fácil de usar. ¡Utilizala con esta liga!\n\n'
            '$appUrl';

        await Share.share(
          shareMessage,
          subject: '¡Te invito a usar Mi Nómina Pro!',
        );
      },
    );
  }

  Widget _buildWifiTile(String ssid, String password, {String? note}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(" $ssid",
                      style: TextStyle(
                          color: _isDarkMode
                              ? Colors.white
                              : const Color(0xFF1E293B),
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  if (note != null)
                    Text(note,
                        style: TextStyle(
                            color: _isDarkMode
                                ? Colors.orangeAccent.withAlpha(180)
                                : const Color(0xFFC2410C),
                            fontSize: 11)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text("Contraseña: ",
                          style: TextStyle(
                              color: _isDarkMode
                                  ? Colors.white70
                                  : const Color(0xFF475569),
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                      Text(password,
                          style: TextStyle(
                              color: _isDarkMode
                                  ? Colors.greenAccent
                                  : const Color(0xFF15803D),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace')),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.copy,
                  color:
                      _isDarkMode ? Colors.orange : const Color(0xFFC2410C),
                  size: 22),
              onPressed: () {
                // Copy password to clipboard
                Clipboard.setData(ClipboardData(text: password));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Contraseña copiada: $password"),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              tooltip: "Copiar contraseña",
            ),
          ],
        ),
      ],
    );
  }


}
