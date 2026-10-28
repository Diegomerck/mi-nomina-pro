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

Siempre que vayas a publicar una nueva versión en producción, el proceso consta de dos partes: **respaldo en GitHub** y **despliegue en Firebase Hosting**.

### Paso 1: Respaldo en GitHub
```bash
git add .
git commit -m "feat/fix: descripción del cambio"
git push origin master
```

### Paso 2: Compilación y Despliegue en Vivo
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

## 6. Antigravity: Trucos para Nombrar Conversaciones (Cheat Sheet)

Antigravity nombra las conversaciones de manera automática basándose en las **primeras dos líneas del mensaje inicial** que envías. Si no especificas un encabezado claro, el modelo asignará un título genérico o impredecible.

### Formato para Forzar el Nombre de la Conversación:
Coloca siempre un encabezado Markdown `#` seguido de una línea `TASK:` al inicio exacto de tu primer prompt:

```markdown
# [Nombre Exacto del Proyecto] - [Rol o Función de la Sesión]
TASK: [Descripción breve de la tarea inicial]
```

### Plantillas Listas para Usar:

#### A. Agente de Planeación y Arquitectura (Thinking / Partner Mode)
> Úsalo con **Gemini 3.8 Flash** en **Planning Mode (Medium reasoning)** para dialogar ideas, revisar impactos y armar especificaciones sin alterar código prematuramente.

```markdown
# Bitácora - Planning & Architecture Agent
TASK: Initialize Bitácora Producciones Planning Agent Session
```

#### B. Agente de Implementación (Fast / Turbo Mode)
> Úsalo con **Gemini 3.8 Flash** en **Fast Mode (High reasoning)** para ejecutar cambios de archivos, builds y terminal de forma directa sobre planes aprobados.

```markdown
# Bitácora - Implementation Agent
TASK: Initialize Bitácora Producciones Implementation Agent Session
```

#### C. Sesión de Depuración o Corrección Puntual (Bugfix)
```markdown
# [Proyecto] - Bugfix: [Nombre del Bug o Módulo]
TASK: Investigar y corregir [error o comportamiento específico]
```

---

### ¿Por qué mantener 2 conversaciones separadas? (Planning vs. Implementation)
1. **Socio de Pensamiento (Planning)**: Te escucha, analiza pros y contras, detecta casos borde (ej. reglas de fechas, cuotas de Firebase) y te sugiere alternativas antes de tocar código.
2. **Constructor Enfocado (Implementation)**: Se concentra en diffs exactos y comandos de terminal sin distraerse en debates teóricos.
3. **Ahorro de Créditos / Ventana de Contexto**: Los diffs y salidas de terminal llenan el historial rápidamente; al separarlos, la conversación de planeación se mantiene ligera, económica y sin pérdida de memoria de las reglas del proyecto.
