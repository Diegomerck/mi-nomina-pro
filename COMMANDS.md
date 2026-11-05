# Guía de Comandos Frecuentes: Proyectos Web & Apps

Este documento contiene los comandos esenciales y el flujo de trabajo recomendado para desarrollo local, pruebas y publicación a producción.

---

## 1. Desarrollo Local y Vista Previa (Preview)

### A. Bitácora Producciones (React + Vite)
Para iniciar el servidor de desarrollo local en `http://localhost:3000/` con recarga rápida:

```bash
npm run dev
```

- **Compilar y validar producción**:
  ```bash
  npm run build
  ```
- **Previsualizar compilación localmente**:
  ```bash
  npm run preview
  ```
- **Publicar en vivo (Hosting)**:
  ```bash
  npm run build
  firebase deploy --only hosting
  ```
  > **URL de Producción**: [https://bitacora-tel.web.app](https://bitacora-tel.web.app)

---

### B. Mi Nómina Pro (Flutter Web)
Para iniciar la aplicación en tu navegador con recarga rápida (**Hot Reload**):

```bash
flutter run -d chrome
```

#### Controles en la terminal mientras corre Flutter:
| Tecla | Acción |
| :--- | :--- |
| `r` | **Hot Reload**: Actualiza los cambios en la UI de inmediato sin perder el estado actual. |
| `R` | **Hot Restart**: Reinicia la aplicación por completo (útil si cambiaste variables iniciales o el `initState`). |
| `q` | **Salir**: Detiene el servidor de desarrollo y cierra la sesión. |

---

## 2. Flujo de Publicación ("Publicar nueva versión")

Existen dos comandos rápidos reconocidos para desplegar a producción:

### A. `PUSH TO LIVE` (Lanzamiento Oficial con Notificación al Usuario)
Utilízalo cuando desees que los usuarios vean la campana de notificación y conozcan las novedades de la aplicación:
1. **Notificación en App**: Actualiza `_changelogTitles` y `_changelogByVersion` en `lib/main.dart` con lenguaje sencillo, amable y comprensible para todos los usuarios.
2. **Notas de Versión**: Registra los cambios y sube la versión en `PROJECT_OVERVIEW.md` y `blueprint.md`.
3. **Respaldo en GitHub**:
   ```bash
   git add .
   git commit -m "feat/fix: descripción del cambio"
   git push origin master
   ```
4. **Compilación y Despliegue en Vivo**:
   ```bash
   flutter build web
   firebase deploy --only hosting
   ```

### B. `PUSH DISCRETE` (Despliegue Silencioso / Mantenimiento)
Utilízalo para parches internos, ajustes silenciosos o cambios de infraestructura sin interrumpir a los usuarios:
1. **Sin Notificación en App**: **NO** altera `_changelogTitles` ni `_changelogByVersion` en `lib/main.dart` (los usuarios no reciben badge ni modal de notificación).
2. **Notas de Versión**: Actualiza la documentación interna (`PROJECT_OVERVIEW.md` y `blueprint.md`).
3. **Respaldo en GitHub**:
   ```bash
   git add .
   git commit -m "chore/fix: descripción del cambio silencioso"
   git push origin master
   ```
4. **Compilación y Despliegue en Vivo**:
   ```bash
   flutter build web
   firebase deploy --only hosting
   ```

> **URL de Producción**: [https://nomina-televisa-v2.web.app](https://nomina-televisa-v2.web.app)

---

## 3. Comprobaciones y Calidad de Código

Antes de compilar o cuando quieras verificar que no haya errores de sintaxis o tipo:

```bash
flutter analyze
```

Si en algún momento el caché de Flutter genera inconsistencias o problemas extraños:
```bash
flutter clean
flutter pub get
```

---

## 4. Gestión de Cuenta en Firebase CLI

Si necesitas cambiar de cuenta o reautenticarte:

- **Cerrar sesión actual**:
  ```bash
  firebase logout
  ```

- **Iniciar sesión**:
  ```bash
  firebase login
  ```

- **Ver usuario activo**:
  ```bash
  firebase login:list
  ```

---

## 5. Cargar Rutas de Terminal (si no se encuentra flutter o firebase)

Si abres una terminal nueva y te indica `command not found: flutter` o `command not found: firebase`:

```bash
source ~/.zprofile
```

---

## 6. Flujo de Trabajo en Sesión Única (Single Conversation Workflow)

Para optimizar el uso de créditos y tokens sin perder contexto histórico, todo el trabajo (planeación e implementación) se gestiona en **un único hilo de conversación**.

### Modos y Disparadores (Workflow Triggers)

| Disparador | Modo | Comportamiento del Agente |
| :--- | :--- | :--- |
| *(Sin prefijo)* | **PLANNING (Por defecto)** | **Cero edición de código**. Solo análisis, discusión de requerimientos, diseño, evaluación de casos borde y estimación de tier. No ejecuta builds ni tests modificadores. |
| `IMPLEMENTATION` | **IMPLEMENTACIÓN** | Despacha automáticamente un **subagente** en el nivel evaluado (`flash` o `pro`), aplica los cambios, verifica el build (`npm run build` en Bitácora / `flutter analyze` en Nómina), y entrega un resumen conciso. |
| `QUICK FIX` | **CORRECCIÓN RÁPIDA** | Aplica cambios mínimos directamente (1 línea, typo, estilo puntual) sin necesidad de subagente. |
| `PUSH TO LIVE` | **LANZAMIENTO PÚBLICO** | Ejecuta el flujo oficial completo: changelog y novedades amables en `lib/main.dart`, documentación, respaldo git, compilación web y deploy a Hosting. |
| `PUSH DISCRETE` | **LANZAMIENTO SILENCIOSO** | Ejecuta el despliegue a producción sin alterar el changelog ni notificar a los usuarios en la app: documentación, respaldo git, build web y deploy a Hosting. |

---

### Evaluación Automática de Complejidad (Tiers)
Durante la fase de **PLANNING**, el agente evalúa la complejidad y asigna el subagente correspondiente:
- **Standard Tier (`Model: "flash"`)**: Tareas de 1-2 archivos, ajustes de UI, estilos, componentes o widgets simples. Ahorro máximo de cuota.
- **High Tier (`Model: "pro"`)**: Refactorizaciones multi-archivo, reglas de Firestore, sincronización de estado, recálculos complejos en cascada o lógica de negocio crítica.
- **Modelos Costosos**: Nunca se utilizarán modelos de costo elevado (como Argon) a menos que se soliciten explícitamente por su nombre en el prompt.

---

## 7. Comandos Slash Recomendados (Slash Commands)

- `/compact`: **Esencial para optimizar costos.** Ejecútalo periódicamente o tras finalizar una funcionalidad importante para compactar el historial y reducir el consumo de tokens por turno sin perder decisiones previas.
- `/plan`: Genera un plan estructurado paso a paso para arquitecturas complejas.
- `/goal`: Modo de trabajo exhaustivo y autónomo para hitos largos.

---

## 8. Trucos para Nombrar Conversaciones (Cheat Sheet)

Antigravity nombra las conversaciones basándose en las **primeras dos líneas del mensaje inicial**:

```markdown
# [Nombre del Proyecto] - [Módulo o Función]
TASK: [Descripción breve del objetivo]
```
