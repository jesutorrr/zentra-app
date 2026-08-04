const concepts = [
  {
    id: "guide",
    name: "Guía diaria",
    tagline:
      "Zentra elige contigo la siguiente acción y mantiene el resto disponible sin convertirlo en ruido.",
    score: "9.6",
    recommended: true,
    palette: ["#F8F6F0", "#2F8177", "#DCEDE8", "#E9A66F", "#1B2523"],
    thesis:
      "La versión más directa de Calma precisa. Hoy responde qué sigue, cuánto avanzaste y cómo entrar en foco.",
    principles: [
      "Una siguiente acción recomendada, nunca una orden.",
      "Color de categoría visible en hábitos y recompensas.",
      "Notas, hábitos y enfoque comparten el mismo hilo de acción.",
      "iPhone comprime y iPad compone, nunca estira.",
      "Calendario y perfil tienen accesos persistentes.",
    ],
    tradeoff:
      "Es la propuesta más fácil de entender, pero debe evitar decidir demasiado por el usuario o esconder opciones avanzadas.",
    lens:
      "Ordena cada pantalla alrededor del siguiente paso sin perder acceso al sistema completo.",
    summary: "La más clara y equilibrada.",
    evolutionTitle: "Modelo: siguiente acción",
    evolutionCopy:
      "Conviene si Zentra quiere reducir decisiones y ayudar a empezar rápido. La persona mantiene control y puede cambiar la sugerencia.",
  },
  {
    id: "timeline",
    name: "Agenda viva",
    tagline:
      "Hábitos, notas, recordatorios y bloques de enfoque conviven en una línea temporal sencilla.",
    score: "9.3",
    recommended: false,
    palette: ["#F8F6F0", "#356F77", "#DDECEF", "#D98A5B", "#1B2523"],
    thesis:
      "Calma precisa organizada por tiempo. El calendario deja de ser una pantalla aislada y se vuelve el marco del día.",
    principles: [
      "Fecha y calendario siempre visibles.",
      "El día se lee de arriba hacia abajo.",
      "Las tareas sin hora conservan una zona flexible.",
      "Reprogramar no se presenta como fracaso.",
      "Notas y enfoque pueden ocupar un bloque de agenda.",
    ],
    tradeoff:
      "Puede sentirse demasiado planificadora para quien sólo quiere marcar hábitos. La agenda debe aceptar días incompletos.",
    lens:
      "Relaciona cada acción con el momento en que puede ocurrir y mantiene el calendario a un toque.",
    summary: "La mejor para tiempo y calendario.",
    evolutionTitle: "Modelo: línea temporal",
    evolutionCopy:
      "Conviene si Calendario será una superficie central y el valor principal es visualizar cómo cabe Zentra en el día real.",
  },
  {
    id: "playful",
    name: "Progreso vivo",
    tagline:
      "La constancia desbloquea colecciones, colores y pequeños logros sin castigar días difíciles.",
    score: "9.4",
    recommended: false,
    palette: ["#FBF7F0", "#2F8177", "#E9A66F", "#7D72B8", "#1B2523"],
    thesis:
      "Calma precisa con más juego. Las categorías crean un mundo de color y el perfil se convierte en un espacio que da gusto visitar.",
    principles: [
      "XP por constancia, no por tiempo dentro de la app.",
      "Retos opcionales y recuperables.",
      "Coleccionables visuales sin cajas sorpresa.",
      "Cada categoría conserva un color reconocible.",
      "Celebraciones breves y compatibles con Reduced Motion.",
    ],
    tradeoff:
      "Es la opción con más riesgo de ruido y presión. Requiere límites estrictos para no convertir bienestar en obligación.",
    lens:
      "Hace visible la diversión y convierte el avance en una colección personal, no en una tabla de estadísticas.",
    summary: "La más cálida y gamificada.",
    evolutionTitle: "Modelo: colección y progreso",
    evolutionCopy:
      "Conviene si la personalidad y la retención emocional son tan importantes como la simplicidad operativa.",
  },
  {
    id: "companion",
    name: "Compañera Zentra",
    tagline:
      "La app interpreta el contexto local y propone un plan amable que la persona puede ajustar.",
    score: "9.0",
    recommended: false,
    palette: ["#F7F6F1", "#4B7C68", "#DDEADF", "#E69B71", "#202821"],
    thesis:
      "Calma precisa como acompañamiento. El tono explica por qué sugiere algo y evita fingir inteligencia que no existe.",
    principles: [
      "Sugerencias explicables y descartables.",
      "Lenguaje humano sin personificar en exceso.",
      "Todo cálculo puede ejecutarse localmente.",
      "La app aprende preferencias, no diagnostica emociones.",
      "Un ajuste nunca cambia datos sin confirmación.",
    ],
    tradeoff:
      "El lenguaje puede cansar o sentirse condescendiente. Las sugerencias necesitan controles y una razón visible.",
    lens:
      "Explica cómo se conectan los datos y ofrece un plan flexible en lugar de mostrar sólo listas.",
    summary: "La más cercana y adaptable.",
    evolutionTitle: "Modelo: acompañamiento explicable",
    evolutionCopy:
      "Conviene si Zentra quiere diferenciarse por orientación personal sin depender de una nube o de IA generativa.",
  },
  {
    id: "studio",
    name: "Estudio modular",
    tagline:
      "Un espacio configurable que aprovecha iPad y web con paneles de hábitos, notas, agenda y enfoque.",
    score: "8.9",
    recommended: false,
    palette: ["#F4F6F4", "#2D6F68", "#CBDDD8", "#6678A8", "#18211F"],
    thesis:
      "Calma precisa como espacio de trabajo. En iPhone los módulos se apilan y en iPad se convierten en un tablero de verdad.",
    principles: [
      "Mismos datos y rutas en todos los tamaños.",
      "Paneles reordenables sólo cuando aportan valor.",
      "List-detail para Notas, Hábitos y Calendario.",
      "Atajos visibles para teclado y puntero.",
      "El teléfono nunca hereda densidad de escritorio.",
    ],
    tradeoff:
      "Es la más costosa y puede abrumar en móvil. La personalización debe llegar después de validar buenos defaults.",
    lens:
      "Usa cada ancho para mostrar relaciones reales entre hábitos, notas, calendario y progreso.",
    summary: "La mejor para iPad, web y usuarios intensivos.",
    evolutionTitle: "Modelo: espacio de trabajo",
    evolutionCopy:
      "Conviene si el futuro web y tablet debe ser una superficie productiva completa, no una aplicación de teléfono ampliada.",
  },
];

const screens = [
  {
    id: "splash",
    name: "Inicio",
    icon: "leaf",
    caption: "Marca y primera impresión",
    reason:
      "El arranque comunica calma sin bloquear. El logo respira sobre una superficie limpia y conserva su transparencia.",
  },
  {
    id: "auth",
    name: "Acceso",
    icon: "lock",
    caption: "Cuenta opcional y modo local",
    reason:
      "Usar Zentra en este dispositivo es el camino principal, restaurar un respaldo es una ruta completa y Google sólo se comunica como capacidad futura hasta que funcione de verdad.",
  },
  {
    id: "onboarding",
    name: "Bienvenida",
    icon: "spark",
    caption: "Tour y permisos",
    reason:
      "Una idea por paso. El permiso se explica en contexto y la acción siguiente nunca compite con contenido secundario.",
  },
  {
    id: "today",
    name: "Hoy",
    icon: "home",
    caption: "Hábitos y foco del día",
    reason:
      "Hoy responde qué sigue, cuánto avancé y cómo entro a enfoque. Crear un hábito nuevo permanece visible dentro de su propio contexto.",
  },
  {
    id: "habit-form",
    name: "Nuevo hábito",
    icon: "plus",
    caption: "Identidad, frecuencia y recordatorio",
    reason:
      "Nombre, categoría, frecuencia y recordatorio forman un flujo completo. La vista previa cambia con las decisiones y no elimina capacidades que ya existen.",
  },
  {
    id: "habits",
    name: "Hábitos",
    icon: "list",
    caption: "Biblioteca y estados",
    reason:
      "Los hábitos se leen como acciones, no como configuración. Frecuencia y racha acompañan sin dominar.",
  },
  {
    id: "notes",
    name: "Notas",
    icon: "note",
    caption: "Biblioteca de ideas activas",
    reason:
      "Las notas se organizan por lo que puede hacerse con ellas. Recordar y enfocar son acciones visibles, no opciones enterradas.",
  },
  {
    id: "note-editor",
    name: "Editar nota",
    icon: "edit",
    caption: "Captura y contexto",
    reason:
      "El editor mantiene una superficie tranquila. El recordatorio y la sesión de enfoque enriquecen la nota sin competir con la escritura.",
  },
  {
    id: "reminder",
    name: "Recordatorio",
    icon: "bell",
    caption: "Regreso oportuno",
    reason:
      "La programación se expresa en lenguaje humano y muestra exactamente qué aparecerá en la notificación antes de guardar.",
  },
  {
    id: "pomodoro",
    name: "Pomodoro",
    icon: "timer",
    caption: "Enfoque rápido y ciclo",
    reason:
      "Dos caminos visibles, título y vínculo realmente opcionales, y un dial de 5 a 60 minutos. Enfoque funciona sin depender de hábitos, notas o tareas.",
  },
  {
    id: "focus-active",
    name: "En curso",
    icon: "focus",
    caption: "Sesión activa",
    reason:
      "Durante el enfoque desaparece casi toda la interfaz. El usuario ve tiempo, intención y burbujas de categoría que se vuelven estáticas con Reduced Motion.",
  },
  {
    id: "progress",
    name: "Progreso",
    icon: "chart",
    caption: "Métricas y tendencias",
    reason:
      "Primero cuenta una historia semanal. Las cifras de detalle aparecen después, evitando un tablero lleno de números aislados.",
  },
  {
    id: "system",
    name: "Sistema",
    icon: "layers",
    caption: "Live Activity y widgets",
    reason:
      "Zentra reduce aperturas: muestra el foco activo y el progreso diario desde las superficies del sistema con privacidad por defecto.",
  },
  {
    id: "calendar",
    name: "Calendario",
    icon: "calendar",
    caption: "Tiempo, contexto y constancia",
    reason:
      "El calendario muestra intensidad y contexto del día seleccionado. También tiene acceso persistente desde el encabezado y el rail de iPad.",
  },
  {
    id: "history",
    name: "Historial",
    icon: "history",
    caption: "Actividad reciente",
    reason:
      "Una línea temporal une hábitos y sesiones de enfoque. Los filtros son rápidos y no esconden la cronología.",
  },
  {
    id: "profile",
    name: "Perfil",
    icon: "user",
    caption: "Identidad, colección y progreso",
    reason:
      "El perfil celebra continuidad con nivel, retos opcionales, colección y color por categoría. Cuenta y preferencias quedan subordinadas.",
  },
  {
    id: "settings",
    name: "Ajustes",
    icon: "sliders",
    caption: "Preferencias y permisos",
    reason:
      "Las opciones se agrupan por resultado para el usuario. Notificaciones muestra su estado real y no solo un interruptor ambiguo.",
  },
  {
    id: "about",
    name: "Ayuda",
    icon: "info",
    caption: "Soporte, privacidad y app",
    reason:
      "Soporte y confianza son más importantes que la versión. Las rutas de ayuda quedan visibles y la información legal baja de nivel.",
  },
];

const state = {
  conceptIndex: 0,
  screenIndex: 3,
  viewport: "phone",
  focusMinutes: 25,
  pomodoroMode: "quick",
  completedHabit: false,
  noteReminderEnabled: true,
  focusContextOpen: false,
  habitCategory: "sleep",
  habitFrequency: "daily",
  habitReminderEnabled: true,
  habitDays: ["L", "M", "X", "J", "V", "S", "D"],
  authMode: "choices",
  onboardingMode: "new",
  onboardingStep: 0,
  onboardingTalisman: "compass",
  onboardingIntent: "organize",
  onboardingHabitTitle: "Revisar mis prioridades",
  onboardingHabitCustomized: false,
  onboardingHabitSkipped: false,
  onboardingReminderEnabled: null,
  onboardingReminderTime: "09:00",
  onboardingPermission: "notDetermined",
};

const conceptNav = document.querySelector("#concept-nav");
const screenNav = document.querySelector("#screen-nav");
const mockup = document.querySelector("#mockup");
const device = document.querySelector("#device");
const dialLayer = document.querySelector("#dial-layer");
const minuteRange = document.querySelector("#minute-range");
const onboardingPermissionStates = [
  "notDetermined",
  "requesting",
  "granted",
  "denied",
  "error",
];
let onboardingPermissionTimer = null;

function icon(name, className = "") {
  const paths = {
    leaf: '<path d="M20 4c-7 0-12 3-12 9 0 2 1 4 3 5 2-6 6-9 9-11-2 3-5 8-10 10-2 1-4 1-6 1 2 2 5 3 8 2 7-2 9-9 8-16Z"/>',
    lock: '<rect x="5" y="10" width="14" height="10" rx="3"/><path d="M8 10V7a4 4 0 0 1 8 0v3"/>',
    spark: '<path d="m12 3 1.4 4.1L17.5 8.5l-4.1 1.4L12 14l-1.4-4.1-4.1-1.4 4.1-1.4L12 3Z"/><path d="m18 14 .8 2.2L21 17l-2.2.8L18 20l-.8-2.2L15 17l2.2-.8L18 14Z"/>',
    home: '<path d="m3 11 9-8 9 8"/><path d="M5 10v10h14V10M9 20v-6h6v6"/>',
    plus: '<path d="M12 5v14M5 12h14"/>',
    list: '<rect x="4" y="4" width="16" height="16" rx="3"/><path d="M8 9h8M8 13h8M8 17h5"/>',
    timer: '<circle cx="12" cy="13" r="8"/><path d="M9 2h6M12 13l3-3"/>',
    chart: '<path d="M4 19V9M10 19V5M16 19v-7M22 19V3"/>',
    calendar: '<rect x="3" y="5" width="18" height="16" rx="3"/><path d="M7 3v4M17 3v4M3 10h18"/>',
    history: '<path d="M3 12a9 9 0 1 0 3-6.7L3 8"/><path d="M3 3v5h5M12 7v5l3 2"/>',
    user: '<circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/>',
    sliders: '<path d="M4 6h7M15 6h5M4 12h3M11 12h9M4 18h9M17 18h3"/><circle cx="13" cy="6" r="2"/><circle cx="9" cy="12" r="2"/><circle cx="15" cy="18" r="2"/>',
    info: '<circle cx="12" cy="12" r="9"/><path d="M12 11v6M12 7h.01"/>',
    check: '<path d="m5 12 4 4L19 6"/>',
    mail: '<rect x="3" y="5" width="18" height="14" rx="3"/><path d="m4 7 8 6 8-6"/>',
    bell: '<path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9M10 21h4"/>',
    moon: '<path d="M20 15a8 8 0 1 1-11-11 7 7 0 0 0 11 11Z"/>',
    droplet: '<path d="M12 3S6 9.3 6 14a6 6 0 0 0 12 0c0-4.7-6-11-6-11Z"/><path d="M9 15.5a3.2 3.2 0 0 0 3 1.8"/>',
    focus: '<circle cx="12" cy="12" r="3"/><path d="M4 9V5a1 1 0 0 1 1-1h4M15 4h4a1 1 0 0 1 1 1v4M20 15v4a1 1 0 0 1-1 1h-4M9 20H5a1 1 0 0 1-1-1v-4"/>',
    repeat: '<path d="m17 2 4 4-4 4"/><path d="M3 11V9a3 3 0 0 1 3-3h15M7 22l-4-4 4-4"/><path d="M21 13v2a3 3 0 0 1-3 3H3"/>',
    edit: '<path d="m4 16-1 5 5-1L19 9l-4-4L4 16ZM13 7l4 4"/>',
    shield: '<path d="M12 3 4 6v6c0 5 3 8 8 10 5-2 8-5 8-10V6l-8-3Z"/><path d="m9 12 2 2 4-4"/>',
    palette: '<path d="M12 3a9 9 0 0 0 0 18h2a2 2 0 0 0 0-4h-1a2 2 0 0 1 0-4h4a4 4 0 0 0 4-4c0-3-4-6-9-6Z"/><path d="M7 10h.01M9 6h.01M14 6h.01M17 9h.01"/>',
    arrow: '<path d="m9 18 6-6-6-6"/>',
    book: '<path d="M4 4h6a3 3 0 0 1 3 3v13a3 3 0 0 0-3-3H4V4ZM20 4h-4a3 3 0 0 0-3 3v13a3 3 0 0 1 3-3h4V4Z"/>',
    sun: '<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/>',
    note: '<path d="M6 3h9l4 4v14H6V3Z"/><path d="M14 3v5h5M9 12h6M9 16h6"/>',
    layers: '<path d="m12 3 9 5-9 5-9-5 9-5Z"/><path d="m3 12 9 5 9-5M3 16l9 5 9-5"/>',
    pin: '<path d="M9 3h6l-1 5 3 3v2H7v-2l3-3-1-5ZM12 13v8"/>',
    pause: '<path d="M8 5v14M16 5v14"/>',
    play: '<path d="m8 5 11 7-11 7V5Z"/>',
    archive: '<path d="M4 7h16v14H4V7ZM3 3h18v4H3V3ZM9 11h6"/>',
    link: '<path d="M10 13a5 5 0 0 0 7.5.5l2-2a5 5 0 0 0-7-7l-1.2 1.2M14 11a5 5 0 0 0-7.5-.5l-2 2a5 5 0 0 0 7 7l1.2-1.2"/>',
    eyeOff: '<path d="M3 3l18 18M10.6 10.6A2 2 0 0 0 13.4 13.4M9.9 4.2A10.8 10.8 0 0 1 12 4c5.5 0 9 8 9 8a17.4 17.4 0 0 1-2.1 3.2M6.6 6.6C4.2 8.2 3 12 3 12s3.5 8 9 8c1.4 0 2.7-.5 3.8-1.2"/>',
  };
  return `<svg class="${className}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${paths[name] || paths.spark}</svg>`;
}

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function appHeader(title, subtitle, actions = true) {
  return `
    <header class="app-header">
      <div>
        <h1 class="app-title">${title}</h1>
        ${subtitle ? `<p class="app-kicker">${subtitle}</p>` : ""}
      </div>
      ${
        actions
          ? `<div class="app-actions">
              <button class="icon-button" type="button" aria-label="Notificaciones">${icon("bell")}</button>
              <button class="icon-button calendar-quick" data-screen="calendar" type="button" aria-label="Abrir Calendario">
                ${icon("calendar")}<span>25</span>
              </button>
              <button class="icon-button profile-quick" data-screen="profile" type="button" aria-label="Abrir Perfil">
                ${icon("spark")}
              </button>
            </div>`
          : ""
      }
    </header>
  `;
}

function bottomNav(active = "today") {
  const items = [
    ["today", "Hoy", "home"],
    ["habits", "Hábitos", "list"],
    ["notes", "Notas", "note"],
    ["pomodoro", "Enfoque", "timer"],
    ["progress", "Progreso", "chart"],
  ];
  return `
    <nav class="bottom-nav" aria-label="Navegación principal">
      ${items
        .map(
          ([screen, label, iconName]) => `
            <button class="bottom-item ${active === screen ? "active" : ""}" data-screen="${screen}" type="button">
              ${icon(iconName)}
              <span>${label}</span>
            </button>
          `,
        )
        .join("")}
    </nav>
  `;
}

function tabletRail(active = "today") {
  const items = [
    ["today", "home"],
    ["habits", "list"],
    ["notes", "note"],
    ["pomodoro", "timer"],
    ["progress", "chart"],
    ["calendar", "calendar"],
    ["profile", "user"],
  ];
  return `
    <nav class="tablet-rail" aria-label="Navegación para iPad">
      <span class="rail-mark">Z</span>
      ${items
        .map(
          ([screen, iconName]) => `
            <button class="rail-button ${active === screen ? "active" : ""}" data-screen="${screen}" type="button" aria-label="${screen}">
              ${icon(iconName)}
            </button>
          `,
        )
        .join("")}
    </nav>
  `;
}

function appPage({
  title,
  subtitle,
  active,
  content,
  actions = true,
  navigation = true,
}) {
  return `
    <div class="app-page has-rail">
      ${navigation ? tabletRail(active) : ""}
      ${appHeader(title, subtitle, actions)}
      <main class="app-content">${content}</main>
      ${navigation ? bottomNav(active) : ""}
    </div>
  `;
}

function habitRows() {
  const rows = [
    ["Revisar metas del día", "Organización · Todos los días", "focus", "study"],
    ["Caminar 20 minutos", "Movimiento · 5 días esta semana", "sun", "move"],
    ["Preparar descanso", "Descanso · Lunes a viernes", "moon", "rest"],
  ];
  return `
    <div class="habit-list">
      ${rows
        .map(
          ([title, subtitle, iconName, category], index) => `
            <article class="habit-row category-${category}">
              <span class="habit-icon category-${category}">${icon(iconName)}</span>
              <span><strong>${title}</strong><small>${subtitle}</small></span>
              <button class="check-button ${state.completedHabit && index === 0 ? "done" : ""}" data-action="complete-habit" type="button" aria-label="Completar hábito">
                ${state.completedHabit && index === 0 ? icon("check") : ""}
              </button>
            </article>
          `,
        )
        .join("")}
    </div>
  `;
}

function renderSplash() {
  const concept = concepts[state.conceptIndex];
  const copy = {
    guide: "Una acción clara a la vez.",
    timeline: "Tu día, en un solo lugar.",
    playful: "Avanzar también puede sentirse bien.",
    companion: "Un plan amable que se adapta contigo.",
    studio: "Tu espacio personal de hábitos y enfoque.",
  }[concept.id];
  return `
    <div class="app-page splash-page">
      <div class="splash-orbit"></div>
      <div class="splash-lockup">
        <span class="splash-mark">${icon("leaf")}</span>
        <h1>Zentra</h1>
        <p>${copy}</p>
      </div>
    </div>
  `;
}

function renderAuthEntry() {
  if (state.authMode === "existing") {
    return `
      <section class="auth-entry-card auth-detail" aria-label="Entrar con usuario local">
        <button class="auth-back" data-action="auth-choices" type="button">
          ${icon("arrow")} <span>Formas de empezar</span>
        </button>
        <p class="eyebrow">Usuario de este dispositivo</p>
        <h2>Vuelve a tu espacio.</h2>
        <p class="auth-detail-copy">Usa las credenciales locales que ya tenías en esta instalación.</p>
        <label class="auth-field">
          <span>Correo</span>
          <span class="auth-input">${icon("mail")} <span>uri@example.com</span></span>
        </label>
        <label class="auth-field">
          <span>Contraseña</span>
          <span class="auth-input">${icon("lock")} <span>••••••••</span></span>
        </label>
        <button class="auth-primary-action" type="button">Entrar a Zentra</button>
        <p class="auth-inline-help">Este acceso no envía tus datos a una cuenta en línea.</p>
      </section>
    `;
  }

  if (state.authMode === "backup") {
    return `
      <section class="auth-entry-card auth-detail" aria-label="Restaurar respaldo">
        <button class="auth-back" data-action="auth-choices" type="button">
          ${icon("arrow")} <span>Formas de empezar</span>
        </button>
        <p class="eyebrow">Recuperación local</p>
        <h2>Recupera lo que ya construiste.</h2>
        <p class="auth-detail-copy">Elige un respaldo de Zentra. Antes de restaurarlo verás qué contiene.</p>
        <button class="auth-backup-picker" type="button">
          <span class="auth-path-icon">${icon("archive")}</span>
          <span><strong>Elegir respaldo</strong><small>Archivo .json creado por Zentra</small></span>
          ${icon("arrow")}
        </button>
        <div class="auth-safety-note">
          ${icon("shield")}
          <span><strong>Nada se reemplaza sin confirmar.</strong><small>Mostraremos usuario, fecha, hábitos, notas y sesiones primero.</small></span>
        </div>
      </section>
    `;
  }

  return `
    <section class="auth-entry-card" aria-label="Formas de empezar">
      <div class="auth-entry-heading">
        <p class="eyebrow">Elige cómo empezar</p>
        <h2>Tu espacio comienza aquí.</h2>
      </div>
      <div class="auth-paths">
        <button class="auth-path local" data-screen="onboarding" type="button">
          <span class="auth-path-icon">${icon("shield")}</span>
          <span><strong>Usar en este dispositivo</strong><small>Sin cuenta. Todas las funciones.</small></span>
          ${icon("arrow")}
        </button>
        <button class="auth-path backup" data-action="auth-backup" type="button">
          <span class="auth-path-icon">${icon("archive")}</span>
          <span><strong>Restaurar un respaldo</strong><small>Recupera hábitos, notas y progreso.</small></span>
          ${icon("arrow")}
        </button>
      </div>
      <button class="auth-existing-link" data-action="auth-existing" type="button">
        Ya tengo un usuario en este dispositivo
      </button>
      <div class="auth-future-note" aria-label="Google próximamente">
        <span class="auth-google-mark">G</span>
        <span><strong>Vincular con Google</strong><small>Podrás hacerlo después sin perder tu historial.</small></span>
        <span class="auth-soon">Próximamente</span>
      </div>
      <p class="auth-privacy-note">${icon("shield")} Tus datos permanecen locales hasta que tú decidas vincularlos.</p>
    </section>
  `;
}

function renderAuth() {
  return `
    <div class="app-page auth-page">
      <div class="auth-color-field" aria-hidden="true">
        <span class="auth-bubble study"></span>
        <span class="auth-bubble move"></span>
        <span class="auth-bubble rest"></span>
        <span class="auth-bubble health"></span>
      </div>
      <section class="auth-copy refreshed auth-story">
        <span class="auth-brand-mark">${icon("leaf")}</span>
        <p class="eyebrow">Privado por diseño</p>
        <h1>Empieza a tu manera.</h1>
        <p>Zentra funciona completa sin cuenta. Tú decides si tus datos salen de este dispositivo.</p>
        <div class="auth-trust-points" aria-label="Compromisos de privacidad">
          <span>${icon("shield")} Sin nube obligatoria</span>
          <span>${icon("archive")} Respaldo exportable</span>
          <span>${icon("spark")} Sin perder funciones</span>
        </div>
      </section>
      ${renderAuthEntry()}
    </div>
  `;
}

const onboardingTalismans = {
  compass: {
    name: "Brújula Serena",
    icon: "spark",
    copy: "Celebra dirección, incluso cuando el paso sea pequeño.",
  },
  leaf: {
    name: "Hoja Constante",
    icon: "leaf",
    copy: "Hace visible el crecimiento que ocurre con calma.",
  },
  moon: {
    name: "Luna Amable",
    icon: "moon",
    copy: "Recuerda que descansar también sostiene tu avance.",
  },
};

const onboardingIntents = {
  organize: {
    label: "Organizarme",
    icon: "focus",
    category: "study",
    habit: "Revisar mis prioridades",
  },
  move: {
    label: "Moverme",
    icon: "sun",
    category: "move",
    habit: "Moverme 10 minutos",
  },
  rest: {
    label: "Descansar",
    icon: "moon",
    category: "rest",
    habit: "Preparar mi descanso",
  },
  focus: {
    label: "Enfocarme",
    icon: "timer",
    category: "note",
    habit: "Hacer un bloque de enfoque",
  },
  explore: {
    label: "Explorar",
    icon: "spark",
    category: "health",
    habit: "Elegir una acción para hoy",
  },
};

const onboardingConceptCopy = {
  guide: {
    eyebrow: "CALMA PRECISA",
    title: "Un paso claro. Luego el siguiente.",
    detail: "Zentra mantiene visible lo que sigue sin convertir tu día en una lista de presión.",
    scene: "Una siguiente acción, siempre ajustable.",
  },
  timeline: {
    eyebrow: "TU DÍA, CON ESPACIO",
    title: "Hazle espacio a lo que importa.",
    detail: "Hábitos, notas y enfoque pueden convivir en tu día sin exigir que todo tenga una hora.",
    scene: "El tiempo orienta, no manda.",
  },
  playful: {
    eyebrow: "PROGRESO VIVO",
    title: "Tu constancia también puede sentirse bien.",
    detail: "El color, tu talismán y pequeñas recompensas celebran continuidad sin castigar días difíciles.",
    scene: "Jugar sin convertir el bienestar en obligación.",
  },
  companion: {
    eyebrow: "A TU RITMO",
    title: "Avanza con una guía amable.",
    detail: "Zentra propone un siguiente paso y siempre explica por qué. Tú decides qué conservar.",
    scene: "Sugerencias locales, claras y descartables.",
  },
  studio: {
    eyebrow: "TU ESPACIO",
    title: "Un lugar claro para lo que quieres construir.",
    detail: "Hábitos, notas, agenda y enfoque comparten una estructura que crece contigo.",
    scene: "Simple en iPhone, compuesto de verdad en iPad.",
  },
};

function renderOnboardingBranchSwitch() {
  return `
    <div class="onboarding-branch-switch" role="group" aria-label="Ruta simulada en UX Lab">
      <button
        class="${state.onboardingMode === "new" ? "active" : ""}"
        data-action="onboarding-mode"
        data-mode="new"
        type="button"
        aria-pressed="${state.onboardingMode === "new"}"
      >Primera vez</button>
      <button
        class="${state.onboardingMode === "restore" ? "active" : ""}"
        data-action="onboarding-mode"
        data-mode="restore"
        type="button"
        aria-pressed="${state.onboardingMode === "restore"}"
      >Restauración</button>
    </div>
  `;
}

function renderOnboardingProgress() {
  return `
    <div class="onboarding-progress" aria-label="Paso ${state.onboardingStep + 1} de 4">
      <strong>Paso ${state.onboardingStep + 1} de 4</strong>
      <div class="onboarding-progress-track" aria-hidden="true">
        ${[0, 1, 2, 3]
          .map(
            (step) =>
              `<span class="${step <= state.onboardingStep ? "active" : ""}"></span>`,
          )
          .join("")}
      </div>
    </div>
  `;
}

function renderOnboardingScene(conceptCopy) {
  const talisman = onboardingTalismans[state.onboardingTalisman];
  const intent = onboardingIntents[state.onboardingIntent];
  const sceneIcon = [
    "spark",
    talisman.icon,
    state.onboardingHabitSkipped ? "leaf" : intent.icon,
    "bell",
  ][state.onboardingStep];
  const labels = [
    conceptCopy.scene,
    talisman.name,
    state.onboardingHabitSkipped
      ? "Puedes empezar sin configurar nada más."
      : "Tu primer paso ya tiene forma.",
    state.onboardingReminderEnabled
      ? `Vista previa · ${state.onboardingReminderTime}`
      : "Tú decides cuándo volver.",
  ];
  return `
    <aside class="onboarding-scene" aria-label="${escapeHtml(labels[state.onboardingStep])}">
      <div class="onboarding-scene-glow" aria-hidden="true">
        <span class="onboarding-category-orb study"></span>
        <span class="onboarding-category-orb move"></span>
        <span class="onboarding-category-orb rest"></span>
        <span class="onboarding-category-orb health"></span>
        <span class="onboarding-talisman-mark">${icon(sceneIcon)}</span>
      </div>
      <div class="onboarding-scene-caption">
        <strong>${escapeHtml(labels[state.onboardingStep])}</strong>
        <small>${escapeHtml(conceptCopy.eyebrow)}</small>
      </div>
    </aside>
  `;
}

function renderOnboardingPromise(conceptCopy) {
  return `
    <section class="onboarding-panel" aria-labelledby="onboarding-title">
      <p class="eyebrow">${conceptCopy.eyebrow}</p>
      <h1 id="onboarding-title" tabindex="-1">${conceptCopy.title}</h1>
      <p class="onboarding-lead">Hábitos, notas y enfoque en un espacio hecho para darte claridad.</p>
      <p class="onboarding-detail">${conceptCopy.detail}</p>
      <div class="onboarding-trust-list" aria-label="Compromisos de Zentra">
        <span>${icon("shield")} <strong>Completa sin cuenta</strong></span>
        <span>${icon("archive")} <strong>Respaldo exportable</strong></span>
        <span>${icon("focus")} <strong>Sin suscripciones</strong></span>
      </div>
    </section>
  `;
}

function renderOnboardingPersonalization() {
  const talisman = onboardingTalismans[state.onboardingTalisman];
  return `
    <section class="onboarding-panel" aria-labelledby="onboarding-title">
      <p class="eyebrow">HAZLO TUYO</p>
      <h1 id="onboarding-title" tabindex="-1">Haz que Zentra se sienta tuya.</h1>
      <p class="onboarding-lead">Tu talismán celebra constancia. Tu intención ayuda a proponer un primer paso.</p>

      <fieldset class="onboarding-fieldset">
        <legend>Elige tu talismán</legend>
        <div class="onboarding-talisman-options" role="radiogroup" aria-label="Talismán">
          ${Object.entries(onboardingTalismans)
            .map(
              ([id, option]) => `
                <button
                  class="onboarding-talisman-option ${state.onboardingTalisman === id ? "active" : ""}"
                  data-action="onboarding-talisman"
                  data-value="${id}"
                  type="button"
                  role="radio"
                  aria-checked="${state.onboardingTalisman === id}"
                  aria-label="${option.name}"
                  tabindex="${state.onboardingTalisman === id ? "0" : "-1"}"
                >
                  <span>${icon(option.icon)}</span>
                  <strong>${option.name}</strong>
                </button>
              `,
            )
            .join("")}
        </div>
        <p class="onboarding-selection-copy">${talisman.copy}</p>
      </fieldset>

      <fieldset class="onboarding-fieldset">
        <legend>¿Qué quieres cuidar primero?</legend>
        <div class="onboarding-intent-options" role="radiogroup" aria-label="Intención inicial">
          ${Object.entries(onboardingIntents)
            .map(
              ([id, option]) => `
                <button
                  class="onboarding-intent-option category-${option.category} ${state.onboardingIntent === id ? "active" : ""}"
                  data-action="onboarding-intent"
                  data-value="${id}"
                  type="button"
                  role="radio"
                  aria-checked="${state.onboardingIntent === id}"
                  tabindex="${state.onboardingIntent === id ? "0" : "-1"}"
                >
                  ${icon(option.icon)}
                  <span>${option.label}</span>
                </button>
              `,
            )
            .join("")}
        </div>
      </fieldset>
    </section>
  `;
}

function renderOnboardingFirstHabit() {
  const intent = onboardingIntents[state.onboardingIntent];
  return `
    <section class="onboarding-panel" aria-labelledby="onboarding-title">
      <p class="eyebrow">EMPIEZA PEQUEÑO</p>
      <h1 id="onboarding-title" tabindex="-1">Dale forma a tu primer paso.</h1>
      <p class="onboarding-lead">Puedes editar esta sugerencia o entrar a Zentra sin crear nada todavía.</p>

      <div class="onboarding-habit-choice" role="radiogroup" aria-label="Decisión sobre el primer hábito">
        <button
          class="${!state.onboardingHabitSkipped ? "active" : ""}"
          data-action="onboarding-habit-choice"
          data-value="create"
          type="button"
          role="radio"
          aria-checked="${!state.onboardingHabitSkipped}"
          tabindex="${!state.onboardingHabitSkipped ? "0" : "-1"}"
        >Crear este hábito</button>
        <button
          class="${state.onboardingHabitSkipped ? "active" : ""}"
          data-action="onboarding-habit-choice"
          data-value="skip"
          type="button"
          role="radio"
          aria-checked="${state.onboardingHabitSkipped}"
          tabindex="${state.onboardingHabitSkipped ? "0" : "-1"}"
        >Empezar sin hábito</button>
      </div>

      <label class="onboarding-habit-field category-${intent.category}">
        <span class="onboarding-habit-icon">${icon(intent.icon)}</span>
        <span class="onboarding-habit-input-wrap">
          <strong>Mi primer hábito</strong>
          <input
            data-onboarding-habit-input
            type="text"
            value="${escapeHtml(state.onboardingHabitTitle)}"
            aria-label="Nombre del primer hábito"
            ${state.onboardingHabitSkipped ? "disabled" : ""}
          />
          <small>Todos los días · podrás ajustar frecuencia y categoría</small>
        </span>
      </label>

      <div class="onboarding-reward-preview" aria-label="Cómo funciona la recompensa">
        <span class="onboarding-reward-icon">${icon("spark")}</span>
        <span>
          <strong>Cada check suma semillas de calma.</strong>
          <small>Un día difícil no borra lo avanzado. Tu talismán crece con constancia, no con perfección.</small>
        </span>
        <b>+10</b>
      </div>
    </section>
  `;
}

function renderOnboardingPermissionState() {
  const states = {
    notDetermined: {
      icon: "bell",
      title: "Todavía no le preguntamos al sistema.",
      copy: "Primero eliges el recordatorio. El diálogo aparece sólo después de tu confirmación.",
    },
    requesting: {
      icon: "bell",
      title: "Esperando respuesta del sistema.",
      copy: "En la app real, iOS o Android mostraría aquí su diálogo nativo.",
    },
    granted: {
      icon: "check",
      title: "Recordatorios activados.",
      copy: "Zentra podrá avisarte a la hora elegida. Puedes cambiarlo después.",
    },
    denied: {
      icon: "shield",
      title: "Continuamos sin notificaciones.",
      copy: "Zentra funciona completa. Podrás activarlas desde Ajustes cuando las necesites.",
    },
    error: {
      icon: "info",
      title: "No pudimos confirmar el permiso.",
      copy: "No se perdió ninguna elección. Puedes entrar a Hoy e intentarlo más tarde.",
    },
  };
  const current = states[state.onboardingPermission];
  return `
    <div class="onboarding-permission-state state-${state.onboardingPermission}" role="status" aria-live="polite" tabindex="-1">
      <span>${icon(current.icon)}</span>
      <div><strong>${current.title}</strong><small>${current.copy}</small></div>
    </div>
    ${
      state.onboardingPermission === "requesting"
        ? `
            <button class="onboarding-timeout-fallback" data-action="onboarding-timeout" type="button">
              Simular timeout ahora
            </button>
            <p class="onboarding-timeout-note">UX Lab resolverá automáticamente como error en 3 segundos. En producción manda la respuesta real del sistema.</p>
          `
        : ""
    }
    <fieldset class="onboarding-permission-lab">
      <legend>UX Lab · simular respuesta del sistema</legend>
      <div role="radiogroup" aria-label="Estado simulado del permiso">
        ${onboardingPermissionStates
          .map(
            (permissionState) => `
              <button
                class="${state.onboardingPermission === permissionState ? "active" : ""}"
                data-action="onboarding-permission-state"
                data-value="${permissionState}"
                type="button"
                role="radio"
                aria-checked="${state.onboardingPermission === permissionState}"
                tabindex="${state.onboardingPermission === permissionState ? "0" : "-1"}"
              >${
                {
                  notDetermined: "Sin decidir",
                  requesting: "Solicitando",
                  granted: "Concedido",
                  denied: "Denegado",
                  error: "Error",
                }[permissionState]
              }</button>
            `,
          )
          .join("")}
      </div>
    </fieldset>
  `;
}

function renderOnboardingReminder() {
  const permissionResolved = ["granted", "denied", "error"].includes(
    state.onboardingPermission,
  );
  return `
    <section class="onboarding-panel" aria-labelledby="onboarding-title">
      <p class="eyebrow">VUELVE CUANDO TÚ DECIDAS</p>
      <h1 id="onboarding-title" tabindex="-1">¿Quieres que Zentra te lo recuerde?</h1>
      <p class="onboarding-lead">Es opcional. No pediremos permiso hasta que elijas recibir este aviso.</p>

      <div class="onboarding-reminder-preview">
        <span class="onboarding-reminder-time">${state.onboardingReminderTime}</span>
        <span><strong>${escapeHtml(state.onboardingHabitSkipped ? "Un momento para ti" : state.onboardingHabitTitle)}</strong><small>Recordatorio local · contenido privado</small></span>
        ${icon("bell")}
      </div>

      <div class="onboarding-reminder-choice" role="radiogroup" aria-label="Configurar recordatorio">
        <button
          class="${state.onboardingReminderEnabled === true ? "active" : ""}"
          data-action="onboarding-reminder"
          data-value="yes"
          type="button"
          role="radio"
          aria-checked="${state.onboardingReminderEnabled === true}"
          tabindex="${state.onboardingReminderEnabled !== false ? "0" : "-1"}"
        >
          ${icon("bell")}
          <span><strong>Sí, avisarme</strong><small>Una vez al día a la hora elegida</small></span>
        </button>
        <button
          class="${state.onboardingReminderEnabled === false ? "active" : ""}"
          data-action="onboarding-reminder"
          data-value="no"
          type="button"
          role="radio"
          aria-checked="${state.onboardingReminderEnabled === false}"
          tabindex="${state.onboardingReminderEnabled === false ? "0" : "-1"}"
        >
          ${icon("shield")}
          <span><strong>Ahora no</strong><small>La app funciona completa sin avisos</small></span>
        </button>
      </div>

      ${
        state.onboardingReminderEnabled
          ? `
              <label class="onboarding-time-field">
                <span>Hora del recordatorio</span>
                <input data-onboarding-reminder-time type="time" value="${state.onboardingReminderTime}" />
              </label>
              ${renderOnboardingPermissionState()}
            `
          : ""
      }

      ${
        state.onboardingReminderEnabled === false || permissionResolved
          ? `
              <div class="onboarding-ready-summary">
                ${icon("spark")}
                <span><strong>Todo listo para tu primer paso.</strong><small>${
                  state.onboardingReminderEnabled === false
                    ? "Entrarás sin recordatorios."
                    : state.onboardingPermission === "granted"
                      ? `Te avisaremos a las ${state.onboardingReminderTime}.`
                      : "Entrarás sin bloquearte por el permiso."
                }</small></span>
              </div>
            `
          : ""
      }
    </section>
  `;
}

function renderOnboardingRestore() {
  return `
    <div class="app-page onboarding-page onboarding-v2 onboarding-restore onboarding-concept-${concepts[state.conceptIndex].id}">
      <header class="onboarding-topbar">
        <div><span class="onboarding-brand">ZENTRA</span><small>Ruta restaurada</small></div>
        ${renderOnboardingBranchSwitch()}
      </header>
      <div class="onboarding-layout">
        <aside class="onboarding-scene restore" aria-label="Respaldo restaurado de forma segura">
          <div class="onboarding-scene-glow" aria-hidden="true">
            <span class="onboarding-talisman-mark">${icon("archive")}</span>
          </div>
          <div class="onboarding-scene-caption"><strong>Todo sigue aquí.</strong><small>Respaldo local verificado</small></div>
        </aside>
        <main class="onboarding-body">
          <section class="onboarding-panel" aria-labelledby="onboarding-title">
            <p class="eyebrow">RESTAURACIÓN COMPLETA</p>
            <h1 id="onboarding-title" tabindex="-1">Tu espacio volvió contigo.</h1>
            <p class="onboarding-lead">Recuperamos tu historial sin reemplazarlo con un tour para usuarios nuevos.</p>
            <div class="onboarding-restore-summary" aria-label="Contenido restaurado">
              <span><strong>8</strong><small>hábitos</small></span>
              <span><strong>14</strong><small>notas</small></span>
              <span><strong>36</strong><small>sesiones</small></span>
            </div>
            <div class="onboarding-restore-safety">
              ${icon("shield")}
              <span><strong>Conservamos tus decisiones.</strong><small>Talismán, categorías, recordatorios y progreso no se reinician.</small></span>
            </div>
          </section>
        </main>
      </div>
      <footer class="onboarding-footer">
        <button class="onboarding-secondary" data-action="onboarding-mode" data-mode="new" type="button">Ver primera apertura</button>
        <button class="primary-button" data-screen="today" type="button">Revisar mi espacio ${icon("arrow")}</button>
      </footer>
    </div>
  `;
}

function renderOnboardingFooter() {
  if (state.onboardingStep === 0) {
    return `
      <button class="onboarding-secondary" data-screen="today" type="button">Configurar después</button>
      <button class="primary-button" data-action="onboarding-next" type="button">Hacerlo mío ${icon("arrow")}</button>
    `;
  }
  if (state.onboardingStep === 1) {
    return `
      <button class="onboarding-secondary" data-action="onboarding-back" type="button">${icon("arrow")} Atrás</button>
      <button class="primary-button" data-action="onboarding-next" type="button">Continuar ${icon("arrow")}</button>
    `;
  }
  if (state.onboardingStep === 2) {
    return `
      <button class="onboarding-secondary" data-action="onboarding-back" type="button">${icon("arrow")} Atrás</button>
      <button class="primary-button" data-action="onboarding-confirm-habit" type="button">${
        state.onboardingHabitSkipped ? "Continuar sin hábito" : "Crear y continuar"
      } ${icon("arrow")}</button>
    `;
  }

  let action = `<button class="primary-button" data-screen="today" type="button">Ir a Hoy ${icon("arrow")}</button>`;
  if (
    state.onboardingReminderEnabled === true &&
    state.onboardingPermission === "notDetermined"
  ) {
    action = `<button class="primary-button" data-action="onboarding-request-permission" type="button">Continuar con permiso ${icon("bell")}</button>`;
  }
  if (
    state.onboardingReminderEnabled === true &&
    state.onboardingPermission === "requesting"
  ) {
    action = `<button class="primary-button" type="button" disabled aria-disabled="true">Esperando al sistema</button>`;
  }
  return `
    <button class="onboarding-secondary" data-action="onboarding-back" type="button">${icon("arrow")} Atrás</button>
    ${action}
  `;
}

function renderOnboarding() {
  if (state.onboardingMode === "restore") return renderOnboardingRestore();

  const concept = concepts[state.conceptIndex];
  const conceptCopy = onboardingConceptCopy[concept.id];
  const content = [
    renderOnboardingPromise(conceptCopy),
    renderOnboardingPersonalization(),
    renderOnboardingFirstHabit(),
    renderOnboardingReminder(),
  ][state.onboardingStep];

  return `
    <div class="app-page onboarding-page onboarding-v2 onboarding-step-${state.onboardingStep + 1} onboarding-concept-${concept.id}">
      <header class="onboarding-topbar">
        ${renderOnboardingProgress()}
        ${renderOnboardingBranchSwitch()}
      </header>
      <div class="onboarding-layout">
        ${renderOnboardingScene(conceptCopy)}
        <main class="onboarding-body">${content}</main>
      </div>
      <footer class="onboarding-footer">
        ${renderOnboardingFooter()}
      </footer>
    </div>
  `;
}

function renderToday() {
  const todayRenderers = {
    guide: renderGuideToday,
    timeline: renderTimelineToday,
    playful: renderPlayfulToday,
    companion: renderCompanionToday,
    studio: renderStudioToday,
  };
  return (todayRenderers[concepts[state.conceptIndex].id] || renderGuideToday)();
}

function renderGuideToday() {
  return appPage({
    title: "Hoy",
    subtitle: "Sábado, 25 de julio",
    active: "today",
    content: `
      <section class="calm-day-hero">
        <div class="day-copy">
          <span class="overline">Tu ritmo de hoy</span>
          <h2>Un paso claro. Luego el siguiente.</h2>
          <p>Dos hábitos y una nota esperan tu atención.</p>
        </div>
        <button class="talisman-mini" data-screen="profile" type="button" aria-label="Abrir perfil, nivel 7">
          <span class="talisman-orbit"></span>
          ${icon("spark")}
          <small>Nivel 7</small>
        </button>
      </section>

      <div class="adaptive-columns calm-today-grid">
        <div>
          <button class="next-gesture" data-screen="reminder" type="button">
            <span class="gesture-time">18:30</span>
            <span class="gesture-copy">
              <small>Siguiente actividad</small>
              <strong>Repasar Álgebra lineal</strong>
              <span>Nota activa · examen del lunes</span>
            </span>
            ${icon("arrow")}
          </button>

          <section class="surface-card calm-habits-card">
            <div class="section-action-head">
              <span><strong>Hábitos de hoy</strong><small>1 de 3 · buen ritmo</small></span>
              <button class="inline-create" data-screen="habit-form" type="button">
                ${icon("plus")} Nuevo hábito
              </button>
            </div>
            ${habitRows()}
          </section>
        </div>

        <aside>
          <section class="calm-focus-card">
            <span class="calm-focus-icon">${icon("timer")}</span>
            <div>
              <small>Espacio para actuar</small>
              <strong>25 min de enfoque</strong>
              <span>Con tu nota de Álgebra</span>
            </div>
            <button data-screen="pomodoro" type="button" aria-label="Configurar enfoque">
              ${icon("play")}
            </button>
          </section>

          <section class="surface-card calm-note-preview tablet-support">
            <div class="card-label">
              <strong>Idea que vale volver a ver</strong>
              <span>Nota fijada</span>
            </div>
            <p>Una transformación conserva la suma y el producto por escalares.</p>
            <button class="text-button" data-screen="note-editor" type="button">
              Abrir nota
            </button>
          </section>
        </aside>
      </div>
    `,
  });
}

function renderTimelineToday() {
  const entries = [
    ["08:30", "Revisar metas del día", "Organización", "study", "focus"],
    ["12:00", "Caminar 20 minutos", "Movimiento", "move", "sun"],
    ["18:30", "Repasar Álgebra lineal", "Nota con recordatorio", "note", "note"],
  ];
  return appPage({
    title: "Agenda",
    subtitle: "Sábado, 25 de julio",
    active: "today",
    content: `
      <button class="calendar-discovery" data-screen="calendar" type="button">
        <span>${icon("calendar")}</span>
        <span><strong>Julio 2026</strong><small>Ver calendario completo</small></span>
        ${icon("arrow")}
      </button>
      <div class="week-strip" aria-label="Semana actual">
        ${[
          ["L", "21"],
          ["M", "22"],
          ["X", "23"],
          ["J", "24"],
          ["V", "25"],
          ["S", "26"],
          ["D", "27"],
        ].map(([day, date], index) => `<button class="${index === 4 ? "active" : ""}" type="button"><small>${day}</small><strong>${date}</strong></button>`).join("")}
      </div>
      <section class="timeline-day">
        <div class="section-action-head timeline-head">
          <span><strong>Tu día</strong><small>1 de 3 completado</small></span>
          <button class="inline-create" data-screen="habit-form" type="button">
            ${icon("plus")} Hábito
          </button>
        </div>
        ${entries.map(([time, title, category, categoryClass, iconName]) => `
          <button class="schedule-entry category-${categoryClass}" type="button">
            <time>${time}</time>
            <span class="schedule-dot"></span>
            <span class="schedule-icon category-${categoryClass}">${icon(iconName)}</span>
            <span><strong>${title}</strong><small>${category}</small></span>
            <span class="check-button"></span>
          </button>
        `).join("")}
        <button class="schedule-entry flexible" data-screen="pomodoro" type="button">
          <time>Libre</time><span class="schedule-dot"></span>
          <span class="schedule-icon">${icon("timer")}</span>
          <span><strong>Bloque de enfoque</strong><small>Colócalo donde mejor te funcione</small></span>
          ${icon("arrow")}
        </button>
      </section>
    `,
  });
}

function renderPlayfulToday() {
  return appPage({
    title: "Hoy",
    subtitle: "Tu progreso está tomando forma",
    active: "today",
    content: `
      <section class="playful-level-hero">
        <button class="playful-avatar" data-screen="profile" type="button">${icon("spark")}</button>
        <span><small>Nivel 7</small><h2>Explorador constante</h2><p>420 de 500 XP</p></span>
        <span class="playful-xp-ring">84%</span>
      </section>
      <section class="weekly-challenge">
        <div class="challenge-top"><span>${icon("sun")}</span><span><small>Reto opcional de la semana</small><strong>Muévete 5 días</strong></span><b>4/5</b></div>
        <div class="challenge-track"><i></i></div>
        <p>Recompensa: color Cielo de verano para tu perfil.</p>
      </section>
      <div class="quest-grid">
        <button class="quest-card category-study" type="button">
          <span class="quest-icon">${icon("focus")}</span><small>Organización</small><strong>Revisar metas</strong><span>+10 XP</span>
        </button>
        <button class="quest-card category-move" type="button">
          <span class="quest-icon">${icon("sun")}</span><small>Movimiento</small><strong>Caminar 20 min</strong><span>+15 XP</span>
        </button>
        <button class="quest-card category-rest" type="button">
          <span class="quest-icon">${icon("moon")}</span><small>Descanso</small><strong>Preparar descanso</strong><span>+10 XP</span>
        </button>
        <button class="quest-card category-note" data-screen="reminder" type="button">
          <span class="quest-icon">${icon("note")}</span><small>Nota activa</small><strong>Repasar Álgebra</strong><span>18:30</span>
        </button>
        <button class="quest-card quest-add" data-screen="habit-form" type="button">
          <span class="quest-icon">${icon("plus")}</span><small>Hazlo tuyo</small><strong>Crear hábito</strong><span>Nueva categoría</span>
        </button>
      </div>
      <button class="next-unlock" data-screen="profile" type="button">
        <span>${icon("palette")}</span><span><strong>Tu colección</strong><small>3 logros nuevos este mes</small></span>${icon("arrow")}
      </button>
    `,
  });
}

function renderCompanionToday() {
  return appPage({
    title: "Buen día, Uri",
    subtitle: "Un plan flexible para hoy",
    active: "today",
    content: `
      <section class="companion-plan">
        <div class="companion-mark">${icon("leaf")}</div>
        <span class="overline">Sugerencia local</span>
        <h2>Empecemos por algo corto.</h2>
        <p>Ayer completaste más cuando comenzaste con una actividad de menos de 25 minutos.</p>
        <button class="primary-button full" data-screen="pomodoro" type="button">${icon("play")} Enfocarme 20 minutos</button>
        <button class="companion-why" type="button">¿Por qué veo esta sugerencia?</button>
      </section>
      <section class="surface-card companion-options">
        <div class="section-action-head">
          <span><strong>También podrías</strong><small>Tú decides</small></span>
          <button class="inline-create" data-screen="habit-form" type="button">
            ${icon("plus")} Crear hábito
          </button>
        </div>
        <button type="button"><span class="habit-icon category-move">${icon("sun")}</span><span><strong>Caminar 20 minutos</strong><small>Movimiento · sin hora</small></span>${icon("arrow")}</button>
        <button data-screen="note-editor" type="button"><span class="habit-icon category-note">${icon("note")}</span><span><strong>Volver a Álgebra lineal</strong><small>Nota activa · 18:30</small></span>${icon("arrow")}</button>
      </section>
      <button class="calendar-discovery compact" data-screen="calendar" type="button">
        <span>${icon("calendar")}</span><span><strong>Ver mi calendario</strong><small>3 actividades para hoy</small></span>${icon("arrow")}
      </button>
    `,
  });
}

function renderStudioToday() {
  return appPage({
    title: "Mi espacio",
    subtitle: "Sábado, 25 de julio",
    active: "today",
    content: `
      <div class="studio-bento">
        <button class="studio-module studio-progress" data-screen="profile" type="button">
          <span class="overline">Nivel 7</span><strong>72%</strong><small>constancia semanal</small><i></i>
        </button>
        <button class="studio-module studio-calendar" data-screen="calendar" type="button">
          <span>${icon("calendar")}</span><strong>25</strong><small>Julio · 3 actividades</small>
        </button>
        <button class="studio-module studio-focus" data-screen="pomodoro" type="button">
          <span>${icon("timer")}</span><span><small>Siguiente bloque</small><strong>25 min de enfoque</strong><p>Álgebra lineal</p></span>${icon("play")}
        </button>
        <button class="studio-module studio-note" data-screen="note-editor" type="button">
          <span class="note-category">Estudio</span><strong>Guía para el examen</strong><p>3 puntos por repasar</p><small>Nota activa · 18:30</small>
        </button>
        <section class="studio-module studio-habits">
          <div class="section-action-head">
            <span><strong>Hábitos</strong><small>1 de 3 completados</small></span>
            <button class="inline-create" data-screen="habit-form" type="button">
              ${icon("plus")} Nuevo
            </button>
          </div>
          ${habitRows()}
        </section>
      </div>
    `,
  });
}

const habitCategories = [
  {
    id: "water",
    label: "Agua",
    icon: "droplet",
    prompt: "Hidratarme",
    colorLabel: "Azul claro",
  },
  {
    id: "move",
    label: "Movimiento",
    icon: "sun",
    prompt: "Caminar 20 minutos",
    colorLabel: "Durazno",
  },
  {
    id: "sleep",
    label: "Sueño",
    icon: "moon",
    prompt: "Leer antes de dormir",
    colorLabel: "Lavanda",
  },
  {
    id: "focus",
    label: "Foco",
    icon: "focus",
    prompt: "Revisar mis metas",
    colorLabel: "Índigo",
  },
  {
    id: "misc",
    label: "Varios",
    icon: "spark",
    prompt: "Preparar mi día",
    colorLabel: "Verde",
  },
];

const habitFrequencies = [
  { id: "daily", label: "Todos los días", short: "Diario" },
  { id: "weekdays", label: "Entre semana", short: "L a V" },
  { id: "custom", label: "Personalizar", short: "Días elegidos" },
  { id: "once", label: "Una vez", short: "Sin repetición" },
];

function selectedHabitCategory() {
  return (
    habitCategories.find((category) => category.id === state.habitCategory) ||
    habitCategories[2]
  );
}

function selectedHabitFrequency() {
  return (
    habitFrequencies.find(
      (frequency) => frequency.id === state.habitFrequency,
    ) || habitFrequencies[0]
  );
}

function categoryPicker(variant = "cards") {
  return `
    <div class="category-picker ${variant}" role="group" aria-label="Categoría del hábito">
      ${habitCategories
        .map(
          (category) => `
            <button
              class="category-choice habit-category-${category.id} ${state.habitCategory === category.id ? "active" : ""}"
              data-action="habit-category"
              data-category="${category.id}"
              type="button"
              aria-pressed="${state.habitCategory === category.id}"
            >
              <span>${icon(category.icon)}</span>
              <strong>${category.label}</strong>
              ${variant === "detailed" ? `<small>${category.colorLabel}</small>` : ""}
            </button>
          `,
        )
        .join("")}
    </div>
  `;
}

function frequencyPicker(variant = "chips") {
  const customDays = state.habitFrequency === "custom";
  return `
    <div class="frequency-picker ${variant}" role="group" aria-label="Frecuencia">
      ${habitFrequencies
        .map(
          (frequency) => `
            <button
              class="frequency-choice ${state.habitFrequency === frequency.id ? "active" : ""}"
              data-action="habit-frequency"
              data-frequency="${frequency.id}"
              type="button"
              aria-pressed="${state.habitFrequency === frequency.id}"
            >
              <strong>${frequency.label}</strong>
              ${variant === "rows" ? `<small>${frequency.short}</small>` : ""}
            </button>
          `,
        )
        .join("")}
    </div>
    ${
      customDays
        ? `<div class="day-picker" role="group" aria-label="Días de repetición">
            ${["L", "M", "X", "J", "V", "S", "D"]
              .map(
                (day) => `
                  <button
                    class="${state.habitDays.includes(day) ? "active" : ""}"
                    data-action="habit-day"
                    data-day="${day}"
                    type="button"
                    aria-pressed="${state.habitDays.includes(day)}"
                  >${day}</button>
                `,
              )
              .join("")}
          </div>`
        : ""
    }
  `;
}

function reminderControl(variant = "card") {
  return `
    <div class="reminder-control ${variant}">
      <button
        class="reminder-toggle ${state.habitReminderEnabled ? "active" : ""}"
        data-action="habit-reminder"
        type="button"
        aria-pressed="${state.habitReminderEnabled}"
      >
        <span class="reminder-toggle-icon">${icon("bell")}</span>
        <span>
          <strong>Recordarme</strong>
          <small>${state.habitReminderEnabled ? "Activo para los días elegidos" : "Sin notificación"}</small>
        </span>
        <i></i>
      </button>
      ${
        state.habitReminderEnabled
          ? `<label class="reminder-time-field">
              <span>Hora</span>
              <input value="9:30 p. m." aria-label="Hora del recordatorio" />
            </label>
            <p class="permission-note">${icon("shield")} Zentra pedirá permiso al activar el primer recordatorio.</p>`
          : `<p class="reminder-off-copy">El hábito seguirá apareciendo en Hoy sin enviarte avisos.</p>`
      }
    </div>
  `;
}

function habitPreview(variant = "card") {
  const category = selectedHabitCategory();
  const frequency = selectedHabitFrequency();
  return `
    <section class="habit-preview ${variant} habit-category-${category.id}">
      <div class="preview-label">
        <span><strong>Vista previa</strong><small>Así aparecerá en Hoy</small></span>
        <em>${category.label}</em>
      </div>
      <article class="habit-preview-row">
        <span class="habit-preview-icon">${icon(category.icon)}</span>
        <span>
          <strong>${category.prompt}</strong>
          <small>${frequency.label}${state.habitReminderEnabled ? " · 9:30 p. m." : " · sin recordatorio"}</small>
        </span>
        <span class="check-button"></span>
      </article>
    </section>
  `;
}

function habitIdentityBlock({ detailed = false } = {}) {
  const category = selectedHabitCategory();
  return `
    <div class="habit-form-section">
      <div class="form-step-label"><span>1</span><strong>Qué quieres repetir</strong></div>
      <label class="field">
        <span>Nombre</span>
        <input class="field-input" value="${category.prompt}" aria-label="Nombre del hábito" />
      </label>
      <p class="form-section-title">Categoría</p>
      ${categoryPicker(detailed ? "detailed" : "cards")}
    </div>
  `;
}

function habitScheduleBlock({ rows = false } = {}) {
  return `
    <div class="habit-form-section">
      <div class="form-step-label"><span>2</span><strong>Cuándo se repite</strong></div>
      ${frequencyPicker(rows ? "rows" : "chips")}
    </div>
  `;
}

function habitReminderBlock({ variant = "card" } = {}) {
  return `
    <div class="habit-form-section">
      <div class="form-step-label"><span>3</span><strong>Cómo quieres recordarlo</strong></div>
      ${reminderControl(variant)}
    </div>
  `;
}

function createHabitButton(label = "Crear hábito") {
  return `
    <button class="primary-button full habit-submit" data-screen="today" type="button">
      ${icon("plus")} ${label}
    </button>
  `;
}

function renderHabitForm() {
  const formRenderers = {
    guide: renderGuideHabitForm,
    timeline: renderTimelineHabitForm,
    playful: renderPlayfulHabitForm,
    companion: renderCompanionHabitForm,
    studio: renderStudioHabitForm,
  };
  return (
    formRenderers[concepts[state.conceptIndex].id] || renderGuideHabitForm
  )();
}

function renderGuideHabitForm() {
  return appPage({
    title: "Nuevo hábito",
    subtitle: "Hazlo fácil de repetir",
    active: "habits",
    content: `
      <div class="habit-form-layout guide-habit-form">
        <section class="surface-card habit-builder-card">
          ${habitIdentityBlock()}
          ${habitScheduleBlock()}
          ${habitReminderBlock()}
          ${createHabitButton()}
        </section>
        <aside>${habitPreview("guide-preview")}</aside>
      </div>
    `,
  });
}

function renderTimelineHabitForm() {
  const frequency = selectedHabitFrequency();
  return appPage({
    title: "Agendar hábito",
    subtitle: "Dale un lugar flexible en tu semana",
    active: "habits",
    content: `
      <div class="timeline-habit-summary">
        <span class="timeline-date-badge"><small>JUL</small><strong>25</strong></span>
        <span><small>Primera aparición</small><strong>Hoy · ${state.habitReminderEnabled ? "9:30 p. m." : "sin hora"}</strong></span>
        <button data-screen="calendar" type="button">${icon("calendar")} Calendario</button>
      </div>
      <div class="habit-form-layout timeline-habit-form">
        <section class="surface-card habit-builder-card">
          ${habitIdentityBlock()}
          ${habitScheduleBlock({ rows: true })}
          <div class="schedule-readout">
            <span>${icon("repeat")}</span>
            <span><strong>${frequency.label}</strong><small>Se puede reprogramar sin perder progreso</small></span>
          </div>
          ${habitReminderBlock({ variant: "timeline-reminder" })}
          ${createHabitButton("Agregar a mi semana")}
        </section>
        <aside>${habitPreview("timeline-preview")}</aside>
      </div>
    `,
  });
}

function renderPlayfulHabitForm() {
  const category = selectedHabitCategory();
  return appPage({
    title: "Nuevo hábito",
    subtitle: "Haz crecer una parte de tu mundo",
    active: "habits",
    content: `
      <section class="playful-habit-hero habit-category-${category.id}">
        <span class="playful-seed">${icon(category.icon)}</span>
        <span><small>Nueva semilla</small><strong>${category.label}</strong><p>La constancia le dará color. Un día difícil no la borra.</p></span>
        <b>+10 XP</b>
      </section>
      <div class="habit-form-layout playful-habit-form">
        <section class="surface-card habit-builder-card">
          ${habitIdentityBlock({ detailed: true })}
          ${habitScheduleBlock()}
          ${habitReminderBlock({ variant: "playful-reminder" })}
          ${createHabitButton("Plantar este hábito")}
        </section>
        <aside>
          ${habitPreview("playful-preview")}
          <section class="gentle-reward-card">
            ${icon("spark")}
            <span><strong>Recompensa amable</strong><small>Completar suma color y experiencia. Nunca quita puntos.</small></span>
          </section>
        </aside>
      </div>
    `,
  });
}

function renderCompanionHabitForm() {
  const category = selectedHabitCategory();
  return appPage({
    title: "Crear hábito",
    subtitle: "Tres decisiones y queda listo",
    active: "habits",
    content: `
      <section class="companion-form-intro">
        <span>${icon("leaf")}</span>
        <div><small>Empecemos pequeño</small><h2>¿Qué te gustaría hacer más fácil?</h2><p>Elegimos un nombre, sus días y si quieres un aviso. Todo se puede cambiar después.</p></div>
      </section>
      <div class="habit-form-layout companion-habit-form">
        <section class="habit-companion-steps">
          <article class="surface-card companion-step">
            ${habitIdentityBlock()}
            <p class="companion-hint">${icon("spark")} Sugerencia local: “${category.prompt}” es concreta y fácil de reconocer.</p>
          </article>
          <article class="surface-card companion-step">${habitScheduleBlock()}</article>
          <article class="surface-card companion-step">${habitReminderBlock({ variant: "companion-reminder" })}</article>
          ${createHabitButton("Guardar mi hábito")}
        </section>
        <aside>${habitPreview("companion-preview")}</aside>
      </div>
    `,
  });
}

function renderStudioHabitForm() {
  return appPage({
    title: "Editor de hábito",
    subtitle: "Configura y previsualiza",
    active: "habits",
    content: `
      <div class="habit-studio-grid">
        <section class="studio-form-module identity-module">
          <div class="module-heading"><span>${icon("edit")}</span><strong>Identidad</strong><small>Nombre y categoría</small></div>
          ${habitIdentityBlock({ detailed: true })}
        </section>
        <section class="studio-form-module schedule-module">
          <div class="module-heading"><span>${icon("calendar")}</span><strong>Repetición</strong><small>Regla semanal</small></div>
          ${habitScheduleBlock({ rows: true })}
        </section>
        <section class="studio-form-module reminder-module">
          <div class="module-heading"><span>${icon("bell")}</span><strong>Aviso</strong><small>Permiso contextual</small></div>
          ${habitReminderBlock({ variant: "studio-reminder" })}
        </section>
        <aside class="studio-form-module preview-module">
          ${habitPreview("studio-preview")}
          ${createHabitButton("Crear y volver a Hoy")}
        </aside>
      </div>
    `,
  });
}

function renderHabits() {
  return appPage({
    title: "Mis hábitos",
    subtitle: "Tres activos · una pausa",
    active: "habits",
    content: `
      <div class="hero-copy"><span class="overline">Tu sistema</span><h2>Constancia antes que perfección</h2><p>Ajusta lo que ya no encaje con tu vida.</p></div>
      <div class="metric-row" style="margin-bottom: 10px">
        <div class="metric"><strong>72%</strong><span>cumplimiento</span></div>
        <div class="metric"><strong>7</strong><span>mejor racha</span></div>
        <div class="metric"><strong>84</strong><span>completados</span></div>
      </div>
      <section class="surface-card">
        <div class="card-label"><strong>Activos</strong><span>Ordenados para hoy</span></div>
        ${habitRows()}
      </section>
      <button class="floating-add" data-screen="habit-form" type="button" aria-label="Nuevo hábito">${icon("plus")}</button>
    `,
  });
}

function renderNotes() {
  return appPage({
    title: "Notas",
    subtitle: "Lo que quieres recordar y usar",
    active: "notes",
    content: `
      <section class="notes-capture-card">
        <span class="notes-capture-icon">${icon("edit")}</span>
        <div>
          <strong>Captura una idea</strong>
          <small>Escribe primero. Organiza cuando te sirva.</small>
        </div>
        <button data-screen="note-editor" type="button" aria-label="Nueva nota">
          ${icon("plus")}
        </button>
      </section>

      <div class="notes-filter-row" aria-label="Filtros de notas">
        <button class="choice-chip active" type="button">Activas</button>
        <button class="choice-chip" type="button">Con recordatorio</button>
        <button class="choice-chip" type="button">Todas</button>
      </div>

      <div class="adaptive-columns notes-layout">
        <section class="note-stack">
          <button class="note-card featured" data-screen="note-editor" type="button">
            <span class="note-card-top">
              <span class="note-category">Estudio</span>
              <span class="note-reminder">${icon("bell")} Hoy · 18:30</span>
            </span>
            <strong>Álgebra lineal · guía para el examen</strong>
            <p>Transformaciones, eigenvalores y las tres preguntas que todavía necesito repasar.</p>
            <span class="note-card-foot">
              <span>${icon("timer")} Enfoque sugerido · 25 min</span>
              <span>Hace 2 h</span>
            </span>
          </button>

          <button class="note-card" data-screen="note-editor" type="button">
            <span class="note-card-top">
              <span class="note-category warm">Personal</span>
              <span class="note-pin">${icon("pin")} Fijada</span>
            </span>
            <strong>Ideas para una mañana más ligera</strong>
            <p>Preparar agua, revisar tres prioridades y dejar el teléfono lejos durante el primer bloque.</p>
            <span class="note-card-foot">
              <span>${icon("link")} Vinculada a un hábito</span>
              <span>Ayer</span>
            </span>
          </button>
        </section>

        <aside class="surface-card notes-support">
          <div class="card-label"><strong>Vuelve con intención</strong><span>Esta semana</span></div>
          <div class="notes-stat"><strong>3</strong><span>notas activas</span></div>
          <div class="notes-stat"><strong>2</strong><span>recordatorios útiles</span></div>
          <p>Zentra te muestra una nota cuando llega el momento de actuar, no por llenar una bandeja.</p>
        </aside>
      </div>
    `,
  });
}

function renderNoteEditor() {
  return appPage({
    title: "Editar nota",
    subtitle: "Guardado automáticamente",
    active: "notes",
    content: `
      <div class="adaptive-columns note-editor-layout">
        <section class="note-paper">
          <span class="note-paper-label">Estudio</span>
          <input class="note-title-input" value="Álgebra lineal · guía para el examen" aria-label="Título de la nota" />
          <textarea class="note-body-input" aria-label="Contenido de la nota">Transformaciones lineales

• Repasar núcleo e imagen
• Resolver el ejemplo de diagonalización
• Preguntar por eigenvalores repetidos

Idea clave: una transformación conserva la suma y el producto por escalares.</textarea>
        </section>

        <aside class="note-tools">
          <button class="note-tool active" data-screen="reminder" type="button">
            <span>${icon("bell")}</span>
            <span><strong>Recordatorio activo</strong><small>Hoy a las 18:30</small></span>
            ${icon("arrow")}
          </button>
          <button class="note-tool" data-screen="pomodoro" type="button">
            <span>${icon("timer")}</span>
            <span><strong>Enfocarme en esta nota</strong><small>Sesión sugerida de 25 min</small></span>
            ${icon("arrow")}
          </button>
          <button class="note-tool" type="button">
            <span>${icon("link")}</span>
            <span><strong>Vincular a un hábito</strong><small>Sin vínculo todavía</small></span>
            ${icon("arrow")}
          </button>
          <button class="primary-button full note-done-button" data-screen="notes" type="button">Listo</button>
        </aside>
      </div>
    `,
  });
}

function renderReminder() {
  return appPage({
    title: "Recordatorio",
    subtitle: "Para tu nota de Álgebra",
    active: "notes",
    content: `
      <div class="adaptive-columns reminder-layout">
        <section class="surface-card reminder-form">
          <div class="reminder-intro">
            <span>${icon("bell")}</span>
            <div><strong>¿Cuándo quieres volver?</strong><small>Elige un momento realista para actuar.</small></div>
          </div>
          <p class="form-section-title">Día</p>
          <div class="choice-row reminder-days">
            <button class="choice-chip active" type="button">Hoy</button>
            <button class="choice-chip" type="button">Mañana</button>
            <button class="choice-chip" type="button">Elegir fecha</button>
          </div>
          <p class="form-section-title">Hora</p>
          <button class="time-picker-row" type="button">
            <span>18:30</span><small>En 3 horas</small>${icon("arrow")}
          </button>
          <label class="reminder-toggle-row">
            <span><strong>Repetir</strong><small>No repetir</small></span>
            <span class="toggle muted"></span>
          </label>
          <button class="primary-button full" data-screen="notes" type="button">Guardar recordatorio</button>
        </section>

        <aside>
          <p class="form-section-title">Así te acompañará Zentra</p>
          <section class="notification-preview">
            <span class="notification-mark">${icon("leaf")}</span>
            <span><strong>Zentra</strong><small>ahora</small></span>
            <p>Es buen momento para volver a tu nota de Álgebra.</p>
            <small class="privacy-label">${icon("eyeOff")} El título se oculta en pantalla bloqueada</small>
          </section>
        </aside>
      </div>
    `,
  });
}

function modeCards() {
  return `
    <div class="mode-stack">
      <button class="mode-card ${state.pomodoroMode === "quick" ? "active" : ""}" data-action="mode" data-mode="quick" type="button">
        <span class="mode-badge">1x</span>
        <span><strong>Enfoque rápido</strong><small>Una sola sesión. Ideal para empezar ahora.</small></span>
        <span class="selection-dot"></span>
      </button>
      <button class="mode-card cycle ${state.pomodoroMode === "cycle" ? "active" : ""}" data-action="mode" data-mode="cycle" type="button">
        <span class="mode-badge">4x</span>
        <span><strong>Ciclo Pomodoro</strong><small>4 enfoques con descansos guiados.</small></span>
        <span class="selection-dot"></span>
      </button>
    </div>
  `;
}

function durationSelector() {
  const presets = [15, 25, 45];
  return `
    <div class="duration-head"><span>Tiempo de enfoque</span><strong>${state.focusMinutes} min</strong></div>
    <div class="duration-segments">
      ${presets
        .map(
          (value) => `<button class="duration-segment ${state.focusMinutes === value ? "active" : ""}" data-action="duration" data-value="${value}" type="button">${value} min</button>`,
        )
        .join("")}
      <button class="duration-segment ${!presets.includes(state.focusMinutes) ? "active" : ""}" data-action="open-dial" type="button">${!presets.includes(state.focusMinutes) ? `${state.focusMinutes} min` : "Otro"}</button>
    </div>
  `;
}

function renderPomodoro() {
  const focusRenderers = {
    guide: renderGuidePomodoro,
    timeline: renderTimelinePomodoro,
    playful: renderPlayfulPomodoro,
    companion: renderCompanionPomodoro,
    studio: renderStudioPomodoro,
  };
  return (
    focusRenderers[concepts[state.conceptIndex].id] || renderGuidePomodoro
  )();
}

function focusModeSwitch(variant = "") {
  const isCycle = state.pomodoroMode === "cycle";
  return `
    <div class="calm-mode-switch ${variant}" role="group" aria-label="Tipo de enfoque">
      <button class="${!isCycle ? "active" : ""}" data-action="mode" data-mode="quick" type="button">
        <span>${icon("focus")}</span>
        <span><strong>Rápido</strong><small>Una sesión</small></span>
      </button>
      <button class="${isCycle ? "active" : ""}" data-action="mode" data-mode="cycle" type="button">
        <span>${icon("repeat")}</span>
        <span><strong>Ciclo</strong><small>4 enfoques</small></span>
      </button>
    </div>
  `;
}

function focusDialPanel(variant = "") {
  const dialProgress = Math.round(((state.focusMinutes - 5) / 55) * 100);
  return `
    <div class="calm-dial-layout ${variant}">
      <button
        class="calm-inline-dial"
        data-action="open-dial"
        type="button"
        style="--focus-progress:${dialProgress}%"
        aria-label="Cambiar duración, ${state.focusMinutes} minutos"
      >
        <span>${state.focusMinutes}</span>
        <small>minutos</small>
        <i></i>
      </button>
      <div class="calm-duration-copy">
        <span>Tiempo de enfoque</span>
        <strong>${state.focusMinutes} min</strong>
        <p>Toca el dial para elegir entre 5 y 60 minutos.</p>
        <div class="calm-presets">
          ${[15, 25, 45]
            .map(
              (value) => `
                <button class="${state.focusMinutes === value ? "active" : ""}" data-action="duration" data-value="${value}" type="button">${value}</button>
              `,
            )
            .join("")}
        </div>
      </div>
    </div>
  `;
}

function focusOptionalContext(variant = "") {
  return `
    <div class="focus-optional-context ${variant}">
      <button
        class="focus-context-trigger ${state.focusContextOpen ? "active" : ""}"
        data-action="toggle-focus-context"
        type="button"
        aria-expanded="${state.focusContextOpen}"
      >
        <span>${icon(state.focusContextOpen ? "edit" : "plus")}</span>
        <span><strong>Añadir nombre o vínculo</strong><small>Opcional. Puedes empezar sin esto.</small></span>
        ${icon("arrow")}
      </button>
      ${
        state.focusContextOpen
          ? `<div class="focus-context-fields">
              <label>
                <span>Nombre de la sesión</span>
                <input placeholder="Ej. Leer, estudiar, escribir" aria-label="Nombre opcional de la sesión" />
              </label>
              <div>
                <span>Vincular con</span>
                <button type="button">${icon("list")} Hábito</button>
                <button type="button">${icon("note")} Nota</button>
              </div>
              <p>Sin selección se guardará como “Sesión de enfoque”.</p>
            </div>`
          : ""
      }
    </div>
  `;
}

function focusCycleSummary() {
  if (state.pomodoroMode !== "cycle") return "";
  return `
    <div class="cycle-summary">
      ${icon("repeat")}
      <span>4 × ${state.focusMinutes} min · descansos de 5 y 15 min</span>
    </div>
  `;
}

function focusStartButton(label = "") {
  const isCycle = state.pomodoroMode === "cycle";
  const actionLabel =
    label ||
    (isCycle
      ? "Iniciar ciclo de 4 sesiones"
      : `Iniciar ${state.focusMinutes} min de enfoque`);
  return `
    <button class="primary-button full calm-start-button" data-screen="focus-active" type="button">
      ${icon("play")} ${actionLabel}
    </button>
  `;
}

function renderGuidePomodoro() {
  const isCycle = state.pomodoroMode === "cycle";
  return appPage({
    title: "Enfoque",
    subtitle: "Haz espacio para una sola cosa",
    active: "pomodoro",
    content: `
      <div class="calm-focus-intro">
        <span class="overline">¿Qué necesitas hoy?</span>
        <h2>${isCycle ? "Un ritmo completo." : "Un bloque sin fricción."}</h2>
        <p>${isCycle ? "Cuatro enfoques con descansos guiados." : "Empieza pequeño y deja que el tiempo haga su parte."}</p>
      </div>

      ${focusModeSwitch("guide-mode-switch")}

      <section class="surface-card calm-focus-setup">
        ${focusDialPanel("guide-focus-dial")}
        ${focusOptionalContext("guide-focus-context")}
        ${focusCycleSummary()}
        ${focusStartButton()}
      </section>
    `,
  });
}

function renderTimelinePomodoro() {
  const isCycle = state.pomodoroMode === "cycle";
  return appPage({
    title: "Bloque de enfoque",
    subtitle: "Ahora · sin evento obligatorio",
    active: "pomodoro",
    content: `
      <section class="focus-now-strip">
        <span class="now-pulse"></span>
        <span><small>Tu agenda tiene espacio</small><strong>${isCycle ? "Ciclo flexible" : `${state.focusMinutes} minutos desde ahora`}</strong></span>
        <button data-screen="calendar" type="button">${icon("calendar")} Ver día</button>
      </section>
      <div class="focus-timeline-layout">
        <section class="surface-card focus-timeline-setup">
          ${focusModeSwitch("timeline-mode-switch")}
          <div class="timeline-focus-line">
            <time>Ahora</time>
            <span></span>
            <div>
              ${focusDialPanel("timeline-focus-dial")}
              ${focusOptionalContext("timeline-focus-context")}
              ${focusCycleSummary()}
            </div>
          </div>
          ${focusStartButton(isCycle ? "Comenzar ciclo ahora" : `Comenzar ${state.focusMinutes} min ahora`)}
        </section>
        <aside class="focus-calendar-note">
          ${icon("calendar")}
          <span><strong>No bloquea tu calendario</strong><small>Si quieres, después puedes guardar esta sesión como parte de tu día.</small></span>
        </aside>
      </div>
    `,
  });
}

function renderPlayfulPomodoro() {
  const isCycle = state.pomodoroMode === "cycle";
  const dialProgress = Math.round(((state.focusMinutes - 5) / 55) * 100);
  return appPage({
    title: "Enfoque",
    subtitle: "Elige tu siguiente bloque",
    active: "pomodoro",
    content: `
      <section class="playful-focus-card">
        <div class="playful-focus-bubbles" aria-hidden="true">
          <span class="habit-category-water"></span>
          <span class="habit-category-move"></span>
          <span class="habit-category-sleep"></span>
        </div>
        <span class="overline">${isCycle ? "4 etapas por delante" : "Una sesión cuenta"}</span>
        <h2>${isCycle ? "Construye un ritmo." : "Hazle espacio a una cosa."}</h2>
        <p>Completar suma experiencia. Pausar o terminar antes nunca quita puntos.</p>
        <button
          class="playful-focus-dial"
          data-action="open-dial"
          type="button"
          style="--focus-progress:${dialProgress}%"
          aria-label="Cambiar duración, ${state.focusMinutes} minutos"
        >
          <span>${state.focusMinutes}</span><small>min</small><i>+10 XP</i>
        </button>
      </section>
      ${focusModeSwitch("playful-mode-switch")}
      <section class="surface-card playful-focus-controls">
        <div class="calm-presets playful-presets">
          ${[15, 25, 45]
            .map(
              (value) => `<button class="${state.focusMinutes === value ? "active" : ""}" data-action="duration" data-value="${value}" type="button">${value} min</button>`,
            )
            .join("")}
          <button data-action="open-dial" type="button">Otro</button>
        </div>
        ${focusOptionalContext("playful-focus-context")}
        ${focusCycleSummary()}
        ${focusStartButton(isCycle ? "Iniciar ciclo" : "Empezar mi bloque")}
      </section>
    `,
  });
}

function renderCompanionPomodoro() {
  const isCycle = state.pomodoroMode === "cycle";
  return appPage({
    title: "Enfoque",
    subtitle: "Tú eliges el ritmo",
    active: "pomodoro",
    content: `
      <section class="companion-focus-suggestion">
        <span class="companion-mark">${icon("leaf")}</span>
        <div><small>Sugerencia, no requisito</small><h2>${isCycle ? "Un ciclo puede darte estructura." : "25 minutos suelen ser un buen inicio."}</h2><p>La recomendación usa tus sesiones recientes. Puedes ignorarla y elegir cualquier duración.</p></div>
        <button class="companion-why" type="button">¿Por qué veo esto?</button>
      </section>
      <section class="surface-card companion-focus-builder">
        ${focusModeSwitch("companion-mode-switch")}
        ${focusDialPanel("companion-focus-dial")}
        ${focusOptionalContext("companion-focus-context")}
        ${focusCycleSummary()}
        ${focusStartButton()}
      </section>
    `,
  });
}

function renderStudioPomodoro() {
  const isCycle = state.pomodoroMode === "cycle";
  return appPage({
    title: "Panel de enfoque",
    subtitle: "Control completo, inicio inmediato",
    active: "pomodoro",
    content: `
      <div class="focus-studio-grid">
        <section class="studio-focus-module mode-module">
          <div class="module-heading"><span>${icon("repeat")}</span><strong>Modo</strong><small>${isCycle ? "Ciclo" : "Rápido"}</small></div>
          ${focusModeSwitch("studio-mode-switch")}
        </section>
        <section class="studio-focus-module dial-module">
          <div class="module-heading"><span>${icon("timer")}</span><strong>Duración</strong><small>5 a 60 min</small></div>
          ${focusDialPanel("studio-focus-dial")}
        </section>
        <section class="studio-focus-module context-module">
          <div class="module-heading"><span>${icon("edit")}</span><strong>Contexto opcional</strong><small>Vacío por defecto</small></div>
          <label class="studio-context-field">
            <span>Título</span>
            <input placeholder="Ej. Escribir propuesta" aria-label="Título opcional" />
          </label>
          <div class="studio-link-actions">
            <button type="button">${icon("list")} Vincular hábito</button>
            <button type="button">${icon("note")} Vincular nota</button>
          </div>
          <p>Si lo dejas vacío se guardará como “Sesión de enfoque”.</p>
        </section>
        <section class="studio-focus-module launch-module">
          <div class="studio-launch-summary">
            <span>${icon(isCycle ? "repeat" : "focus")}</span>
            <span><strong>${isCycle ? "4 sesiones" : "1 sesión"} · ${state.focusMinutes} min</strong><small>${isCycle ? "Descansos 5/15 min" : "Sin vínculo · empieza ahora"}</small></span>
          </div>
          ${focusStartButton(isCycle ? "Ejecutar ciclo" : "Iniciar sesión")}
        </section>
      </div>
    `,
  });
}

function renderFocusActive() {
  const isCycle = state.pomodoroMode === "cycle";
  const totalSeconds = state.focusMinutes * 60;
  const remainingSeconds = Math.max(60, totalSeconds - 197);
  const remainingMinutes = Math.floor(remainingSeconds / 60);
  const remainingRemainder = String(remainingSeconds % 60).padStart(2, "0");
  return appPage({
    title: "Enfoque",
    subtitle: isCycle ? "Ciclo 1 de 4" : "Sesión en curso",
    active: "pomodoro",
    actions: false,
    navigation: false,
    content: `
      <section class="active-focus-scene">
        <div class="focus-bubbles" aria-hidden="true">
          <span class="focus-bubble study one"></span>
          <span class="focus-bubble move two"></span>
          <span class="focus-bubble rest three"></span>
          <span class="focus-bubble health four"></span>
          <span class="focus-bubble note five"></span>
          <span class="focus-bubble study six"></span>
        </div>
        <div class="active-focus-orbit">
          <span class="active-focus-time">${remainingMinutes}:${remainingRemainder}</span>
          <small>de ${state.focusMinutes} min</small>
          <i></i>
        </div>
        <span class="active-focus-label">Ahora</span>
        <h2>Sesión de enfoque</h2>
        <p>Sin título ni vínculo. El temporizador sigue disponible en la pantalla bloqueada.</p>

        <div class="focus-controls">
          <button class="focus-control secondary" data-screen="pomodoro" type="button">
            <span>${icon("archive")}</span><small>Terminar</small>
          </button>
          <button class="focus-control primary" type="button">
            <span>${icon("pause")}</span><small>Pausar</small>
          </button>
          <button class="focus-control secondary" data-screen="system" type="button">
            <span>${icon("layers")}</span><small>Ver fuera</small>
          </button>
        </div>
      </section>

      <section class="focus-note-link">
        <span>${icon("note")}</span>
        <span><strong>Nota vinculada</strong><small>Álgebra lineal · guía para el examen</small></span>
        ${icon("arrow")}
      </section>
    `,
  });
}

function renderProgress() {
  const bars = [42, 58, 46, 78, 64, 88, 72];
  return appPage({
    title: "Progreso",
    subtitle: "Tu semana en perspectiva",
    active: "progress",
    content: `
      <div class="adaptive-columns">
        <div>
          <section class="surface-card streak-card">
            <span class="streak-number">7</span>
            <span><strong>Días de constancia</strong><small style="display:block;color:var(--muted);font-size:8px;margin-top:3px">Tu mejor racha del mes</small></span>
          </section>
          <section class="surface-card chart-card">
            <div class="card-label"><strong>Ritmo semanal</strong><span>72% completado</span></div>
            <div class="bar-chart">
              ${bars.map((height, index) => `<span class="bar-group"><i class="bar" style="height:${height}%"></i><span>${["L", "M", "X", "J", "V", "S", "D"][index]}</span></span>`).join("")}
            </div>
          </section>
        </div>
        <aside>
          <div class="metric-row">
            <div class="metric"><strong>84</strong><span>hábitos</span></div>
            <div class="metric"><strong>26</strong><span>sesiones</span></div>
            <div class="metric"><strong>11h</strong><span>en foco</span></div>
          </div>
          <section class="surface-card" style="margin-top:10px">
            <div class="card-label"><strong>Lectura de la semana</strong></div>
            <p style="margin:0;color:var(--muted);font-size:9px;line-height:1.55">Tu mejor ventana es de 9 a 11 a. m. Los viernes necesitas hábitos más pequeños.</p>
          </section>
        </aside>
      </div>
    `,
  });
}

function renderSystem() {
  return appPage({
    title: "Fuera de la app",
    subtitle: "Presencia útil, privacidad primero",
    active: "pomodoro",
    content: `
      <div class="system-surfaces">
        <section class="system-lock-card">
          <div class="system-status"><span>9:41</span><span>${icon("focus")} ${icon("bell")}</span></div>
          <div class="dynamic-island">
            <span class="island-mark">${icon("timer")}</span>
            <span>21:43</span>
            <i></i>
          </div>
          <div class="live-activity-card">
            <div class="live-activity-top">
              <span class="live-mark">${icon("leaf")}</span>
              <span><strong>Zentra</strong><small>Sesión de enfoque</small></span>
              <span class="live-time">21:43</span>
            </div>
            <div class="live-progress"><i></i></div>
            <div class="live-activity-foot">
              <span>Repasar Álgebra</span>
              <span>Termina 10:03</span>
            </div>
          </div>
        </section>

        <section class="widget-preview-column">
          <p class="form-section-title">Widgets de tu progreso diario</p>
          <div class="widget-row">
            <article class="widget-small">
              <span>${icon("leaf")}</span>
              <strong>2 de 3</strong>
              <small>hábitos de hoy</small>
              <i></i>
            </article>
            <article class="widget-small warm">
              <span>${icon("note")}</span>
              <strong>18:30</strong>
              <small>volver a tu nota</small>
              <i></i>
            </article>
          </div>
          <article class="widget-medium">
            <span class="widget-talisman">${icon("spark")}</span>
            <span><small>Explorador constante · nivel 7</small><strong>Tu ritmo sigue vivo.</strong><p>Un hábito más completa el día.</p></span>
            ${icon("arrow")}
          </article>
          <p class="system-privacy-note">${icon("eyeOff")} Los títulos sensibles pueden ocultarse en Lock Screen.</p>
        </section>
      </div>
    `,
  });
}

function renderCalendar() {
  const days = Array.from({ length: 35 }, (_, index) => index - 2);
  return appPage({
    title: "Calendario",
    subtitle: "Julio 2026",
    active: "calendar",
    content: `
      <div class="adaptive-columns">
        <section class="surface-card">
          <div class="card-label"><strong>Julio</strong><span>18 días con actividad</span></div>
          <div class="calendar-grid">
            ${["L", "M", "X", "J", "V", "S", "D"].map((day) => `<span class="calendar-cell label">${day}</span>`).join("")}
            ${days.map((day) => {
              if (day < 1 || day > 31) return '<span class="calendar-cell"></span>';
              const className = day === 25 ? "today" : [2, 4, 7, 8, 11, 14, 16, 18, 21, 22, 24].includes(day) ? "has-data" : "";
              return `<button class="calendar-cell ${className}" type="button">${day}</button>`;
            }).join("")}
          </div>
        </section>
        <aside class="surface-card">
          <div class="card-label"><strong>25 de julio</strong><span>2 de 3</span></div>
          ${habitRows()}
        </aside>
      </div>
    `,
  });
}

function renderHistory() {
  const rows = [
    ["9:10", "Enfoque completado", "Revisar propuesta · 25 min"],
    ["8:30", "Hábito completado", "Revisar metas del día"],
    ["Ayer", "Ciclo Pomodoro", "Escribir documentación · 4 sesiones"],
    ["Jue", "Hábito completado", "Caminar 20 minutos"],
  ];
  return appPage({
    title: "Historial",
    subtitle: "Todo lo que has avanzado",
    active: "",
    content: `
      <div class="choice-row" style="margin-bottom:14px">
        <button class="choice-chip active" type="button">Todo</button>
        <button class="choice-chip" type="button">Hábitos</button>
        <button class="choice-chip" type="button">Enfoque</button>
      </div>
      <section class="surface-card">
        <div class="timeline">
          ${rows.map(([time, title, subtitle]) => `
            <div class="timeline-row">
              <time>${time}</time><span class="timeline-dot"></span>
              <article class="timeline-card"><strong>${title}</strong><small>${subtitle}</small></article>
            </div>
          `).join("")}
        </div>
      </section>
    `,
  });
}

function renderProfile() {
  return appPage({
    title: "Mi perfil",
    subtitle: "Nivel, colección y preferencias",
    active: "profile",
    actions: false,
    content: `
      <section class="game-profile-hero">
        <div class="profile-identity">
          <span class="profile-avatar">${icon("user")}<i>7</i></span>
          <span><small>Uri Torres</small><h2>Explorador constante</h2><p>7 días encontrando tu ritmo.</p></span>
          <button data-screen="settings" type="button" aria-label="Abrir ajustes">${icon("sliders")}</button>
        </div>
        <div class="profile-world" aria-label="Colección de categorías">
          <span class="world-orbit"></span>
          <span class="world-token study">${icon("focus")}</span>
          <span class="world-token move">${icon("sun")}</span>
          <span class="world-token rest">${icon("moon")}</span>
          <span class="world-token note">${icon("note")}</span>
          <span class="world-core">${icon("spark")}<small>Nivel 7</small></span>
        </div>
      </section>

      <section class="profile-xp-card">
        <div><span><strong>420 XP</strong><small>de 500 para nivel 8</small></span><b>84%</b></div>
        <span class="profile-xp-track"><i></i></span>
        <p>Las pausas no borran tu avance. Retomas desde aquí.</p>
      </section>

      <section class="profile-challenge">
        <span class="challenge-badge category-move">${icon("sun")}</span>
        <span><small>Reto opcional · 4 de 5</small><strong>Muévete cinco días</strong><p>Desbloquea el color Cielo de verano.</p></span>
        <span class="challenge-mini-track"><i></i></span>
      </section>

      <section class="achievement-section">
        <div class="card-label"><strong>Mi colección</strong><button data-screen="history" type="button">Ver todo</button></div>
        <div class="achievement-row">
          <article class="achievement unlocked study"><span>${icon("focus")}</span><strong>Primer paso</strong><small>10 hábitos</small></article>
          <article class="achievement unlocked move"><span>${icon("sun")}</span><strong>En movimiento</strong><small>5 días</small></article>
          <article class="achievement unlocked rest"><span>${icon("moon")}</span><strong>Buen descanso</strong><small>7 noches</small></article>
          <article class="achievement locked"><span>${icon("lock")}</span><strong>Por descubrir</strong><small>1 pista</small></article>
        </div>
      </section>

      <section class="category-palette">
        <div class="card-label"><strong>Colores de mis hábitos</strong><span>Esta semana</span></div>
        <div>
          <span class="category-key study"><i></i>Organización <b>34%</b></span>
          <span class="category-key move"><i></i>Movimiento <b>28%</b></span>
          <span class="category-key rest"><i></i>Descanso <b>22%</b></span>
          <span class="category-key note"><i></i>Estudio <b>16%</b></span>
        </div>
      </section>

      <section class="profile-links">
        <button data-screen="settings" type="button">${icon("sliders")}<span><strong>Preferencias</strong><small>Experiencia, cuenta y respaldo</small></span>${icon("arrow")}</button>
        <button data-screen="about" type="button">${icon("shield")}<span><strong>Privacidad y ayuda</strong><small>Controla tus datos</small></span>${icon("arrow")}</button>
      </section>
    `,
  });
}

function renderSettings() {
  return appPage({
    title: "Ajustes",
    subtitle: "Haz que Zentra trabaje contigo",
    active: "profile",
    content: `
      <p class="form-section-title">Experiencia</p>
      <section class="settings-list">
        <div class="settings-row">${icon("palette")}<span><strong>Apariencia</strong><small>Claro, oscuro o sistema</small></span><span class="settings-value">Sistema</span></div>
        <div class="settings-row">${icon("bell")}<span><strong>Notificaciones</strong><small>Permitidas · 3 recordatorios</small></span><span class="toggle"></span></div>
        <div class="settings-row">${icon("spark")}<span><strong>Reducir movimiento</strong><small>Sigue la preferencia del sistema</small></span><span class="settings-value">Automático</span></div>
        <div class="settings-row">${icon("focus")}<span><strong>Sonido y haptics</strong><small>Firma suave · audio ambiental</small></span><span class="toggle"></span></div>
        <div class="settings-row">${icon("timer")}<span><strong>Pomodoro</strong><small>25 min · pausas 5/15</small></span>${icon("arrow")}</div>
      </section>
      <p class="form-section-title">Cuenta y datos</p>
      <section class="settings-list">
        <div class="settings-row">${icon("eyeOff")}<span><strong>Privacidad en Lock Screen</strong><small>Ocultar títulos de notas y hábitos</small></span><span class="toggle"></span></div>
        <div class="settings-row">${icon("shield")}<span><strong>Respaldo local</strong><small>Exportar, restaurar o eliminar datos</small></span>${icon("arrow")}</div>
        <div class="settings-row">${icon("user")}<span><strong>Cuenta opcional</strong><small>Google, correo o sólo este dispositivo</small></span>${icon("arrow")}</div>
        <div class="settings-row">${icon("info")}<span><strong>Sobre Zentra</strong><small>Versión, soporte y términos</small></span>${icon("arrow")}</div>
      </section>
    `,
  });
}

function renderAbout() {
  return appPage({
    title: "Ayuda",
    subtitle: "Estamos contigo",
    active: "profile",
    content: `
      <span class="about-mark">${icon("leaf")}</span>
      <div class="about-center"><h2>Zentra</h2><p>Hábitos y enfoque con intención</p></div>
      <section class="settings-list">
        <div class="settings-row">${icon("mail")}<span><strong>Contactar soporte</strong><small>Cuéntanos qué necesitas</small></span>${icon("arrow")}</div>
        <div class="settings-row">${icon("book")}<span><strong>Guía rápida</strong><small>Hábitos, ciclos y recordatorios</small></span>${icon("arrow")}</div>
        <div class="settings-row">${icon("shield")}<span><strong>Privacidad</strong><small>Cómo cuidamos tus datos</small></span>${icon("arrow")}</div>
        <div class="settings-row">${icon("info")}<span><strong>Versión</strong><small>Concepto de diseño</small></span><span class="settings-value">UX Lab</span></div>
      </section>
    `,
  });
}

const renderers = {
  splash: renderSplash,
  auth: renderAuth,
  onboarding: renderOnboarding,
  today: renderToday,
  "habit-form": renderHabitForm,
  habits: renderHabits,
  notes: renderNotes,
  "note-editor": renderNoteEditor,
  reminder: renderReminder,
  pomodoro: renderPomodoro,
  "focus-active": renderFocusActive,
  progress: renderProgress,
  system: renderSystem,
  calendar: renderCalendar,
  history: renderHistory,
  profile: renderProfile,
  settings: renderSettings,
  about: renderAbout,
};

function renderConceptNav() {
  conceptNav.innerHTML = concepts
    .map(
      (concept, index) => `
        <button
          class="concept-button ${index === state.conceptIndex ? "active" : ""}"
          data-concept="${index}"
          type="button"
          aria-pressed="${index === state.conceptIndex}"
          ${index === state.conceptIndex ? 'aria-current="true"' : ""}
        >
          <span class="concept-index">0${index + 1}</span>
          <span class="concept-name">${concept.name}</span>
          ${concept.recommended ? '<span class="vote-tag">Mi voto</span>' : ""}
        </button>
      `,
    )
    .join("");
}

function renderScreenNav() {
  screenNav.innerHTML = screens
    .map(
      (screen, index) => `
        <button
          class="screen-button ${index === state.screenIndex ? "active" : ""}"
          data-screen-index="${index}"
          type="button"
          ${index === state.screenIndex ? 'aria-current="page"' : ""}
        >
          ${icon(screen.icon)}
          <span>${screen.name}</span>
        </button>
      `,
    )
    .join("");
  document.querySelector("#screen-count").textContent = String(
    state.screenIndex + 1,
  ).padStart(2, "0");
  document.querySelector("#screen-total").textContent = screens.length;
}

function renderInspector() {
  const concept = concepts[state.conceptIndex];
  const screen = screens[state.screenIndex];
  document.querySelector("#concept-title").textContent = concept.name;
  document.querySelector("#concept-tagline").textContent = concept.tagline;
  document.querySelector("#concept-score").textContent = concept.score;
  document.querySelector("#concept-thesis").textContent = concept.thesis;
  document.querySelector("#concept-tradeoff").textContent = concept.tradeoff;
  document.querySelector("#concept-evolution-title").textContent =
    concept.evolutionTitle;
  document.querySelector("#concept-evolution-copy").textContent =
    concept.evolutionCopy;
  document.querySelector("#concept-principles").innerHTML = concept.principles
    .map((principle) => `<li>${principle}</li>`)
    .join("");
  document.querySelector("#palette").innerHTML = concept.palette
    .map(
      (color) =>
        `<span class="swatch" style="background:${color}" title="${color}"></span>`,
    )
    .join("");
  document.querySelector("#screen-decision-title").textContent =
    `${screen.name}: ${screen.caption}`;
  document.querySelector("#screen-decision-copy").textContent =
    `${concept.lens} ${screen.reason}`;
}

function renderJourney() {
  document.querySelector("#journey-grid").innerHTML = screens
    .map(
      (screen, index) => `
        <button class="journey-card ${index === state.screenIndex ? "active" : ""}" data-screen-index="${index}" type="button">
          <span class="journey-icon">${icon(screen.icon)}</span>
          <strong>${screen.name}</strong>
          <small>${screen.caption}</small>
        </button>
      `,
    )
    .join("");
}

function renderComparison() {
  document.querySelector("#comparison-grid").innerHTML = concepts
    .map(
      (concept, index) => `
        <article class="comparison-card ${concept.recommended ? "recommended" : ""}">
          <span class="comparison-number">0${index + 1}</span>
          <h3>${concept.name}</h3>
          <p>${concept.summary}</p>
          <div class="comparison-score-row"><span>Coherencia</span><strong>${concept.score}</strong></div>
        </article>
      `,
    )
    .join("");
}

function selectorValue(value) {
  return String(value).replaceAll("\\", "\\\\").replaceAll('"', '\\"');
}

function stableFocusSelector(element) {
  if (!element || element === document.body) return null;
  if (element.id) return `#${selectorValue(element.id)}`;

  const attributes = [
    "data-action",
    "data-value",
    "data-mode",
    "data-screen",
    "data-screen-index",
    "data-concept",
    "data-viewport",
  ];
  const available = attributes.filter((attribute) =>
    element.hasAttribute?.(attribute),
  );
  if (available.length) {
    return available
      .map(
        (attribute) =>
          `[${attribute}="${selectorValue(element.getAttribute(attribute))}"]`,
      )
      .join("");
  }
  if (element.matches?.("[data-onboarding-habit-input]")) {
    return "[data-onboarding-habit-input]";
  }
  if (element.matches?.("[data-onboarding-reminder-time]")) {
    return "[data-onboarding-reminder-time]";
  }
  return null;
}

function restoreFocus(root, selector, fallbackSelector = null) {
  const target =
    (selector ? root.querySelector(selector) : null) ||
    (fallbackSelector ? root.querySelector(fallbackSelector) : null);
  target?.focus?.({ preventScroll: true });
}

function currentScreenId() {
  return screens[state.screenIndex].id;
}

function syncCurrentUrl({ replace = false } = {}) {
  const url = new URL(window.location.href);
  const screenId = currentScreenId();
  url.searchParams.set("concept", concepts[state.conceptIndex].id);
  url.searchParams.set("screen", screenId);
  url.searchParams.set("viewport", state.viewport);

  if (screenId === "onboarding") {
    url.searchParams.set("onboarding", state.onboardingMode);
    if (state.onboardingMode === "new") {
      url.searchParams.set("step", String(state.onboardingStep + 1));
      url.searchParams.set("permission", state.onboardingPermission);
    } else {
      url.searchParams.delete("step");
      url.searchParams.delete("permission");
    }
  } else {
    url.searchParams.delete("onboarding");
    url.searchParams.delete("step");
    url.searchParams.delete("permission");
  }

  if (url.href === window.location.href) return;
  window.history[replace ? "replaceState" : "pushState"](
    { uxLab: true },
    "",
    url,
  );
}

function clearOnboardingPermissionTimeout() {
  if (onboardingPermissionTimer !== null) {
    window.clearTimeout(onboardingPermissionTimer);
    onboardingPermissionTimer = null;
  }
}

function reconcileOnboardingPermissionTimeout() {
  const shouldRun =
    currentScreenId() === "onboarding" &&
    state.onboardingMode === "new" &&
    state.onboardingStep === 3 &&
    state.onboardingReminderEnabled === true &&
    state.onboardingPermission === "requesting";

  if (!shouldRun) {
    clearOnboardingPermissionTimeout();
    return;
  }
  if (onboardingPermissionTimer !== null) return;

  onboardingPermissionTimer = window.setTimeout(() => {
    onboardingPermissionTimer = null;
    if (
      currentScreenId() !== "onboarding" ||
      state.onboardingPermission !== "requesting"
    ) {
      return;
    }
    state.onboardingPermission = "error";
    syncCurrentUrl({ replace: true });
    renderMockup({
      focusSelector: '[role="status"]',
      fallbackSelector: "#onboarding-title",
    });
  }, 3000);
}

function renderMockup({
  focusSelector = null,
  fallbackSelector = null,
  restore = true,
} = {}) {
  const capturedFocus =
    focusSelector ||
    (mockup.contains(document.activeElement)
      ? stableFocusSelector(document.activeElement)
      : null);
  const concept = concepts[state.conceptIndex];
  const screen = screens[state.screenIndex];
  mockup.className = `device-screen theme-${concept.id}`;
  mockup.innerHTML = renderers[screen.id]();
  reconcileOnboardingPermissionTimeout();
  if (restore) {
    restoreFocus(mockup, capturedFocus, fallbackSelector);
  }
}

function renderAll({ focusSelector = null, fallbackSelector = null } = {}) {
  const capturedFocus =
    focusSelector || stableFocusSelector(document.activeElement);
  renderConceptNav();
  renderScreenNav();
  renderInspector();
  renderJourney();
  renderComparison();
  renderMockup({ restore: false });
  restoreFocus(document, capturedFocus, fallbackSelector);
}

function setScreenById(screenId) {
  const index = screens.findIndex((screen) => screen.id === screenId);
  if (index < 0) return;
  if (state.screenIndex === index) return;
  syncCurrentUrl({ replace: true });
  state.screenIndex = index;
  syncCurrentUrl();
  renderAll({
    fallbackSelector: screenId === "onboarding" ? "#onboarding-title" : null,
  });
}

function openDial() {
  minuteRange.value = state.focusMinutes;
  updateDial();
  dialLayer.hidden = false;
}

function closeDial() {
  dialLayer.hidden = true;
}

function updateDial() {
  const value = Number(minuteRange.value);
  const progress = ((value - 5) / 55) * 75;
  const angle = -135 + ((value - 5) / 55) * 270;
  document.querySelector("#dial-value").textContent = value;
  document.querySelector("#dial-action-value").textContent = value;
  document
    .querySelector("#rotary-dial")
    .style.setProperty("--dial-progress", `${progress}%`);
  document
    .querySelector("#rotary-dial")
    .style.setProperty("--dial-angle", `${angle}deg`);
}

conceptNav.addEventListener("click", (event) => {
  const button = event.target.closest("[data-concept]");
  if (!button) return;
  state.conceptIndex = Number(button.dataset.concept);
  syncCurrentUrl({ replace: true });
  renderAll();
});

document.addEventListener("click", (event) => {
  const screenButton = event.target.closest("[data-screen-index]");
  if (screenButton) {
    setScreenById(screens[Number(screenButton.dataset.screenIndex)].id);
    document.querySelector(".studio-grid").scrollIntoView({
      behavior: "smooth",
      block: "start",
    });
    return;
  }

  const routeButton = event.target.closest("[data-screen]");
  if (routeButton) {
    setScreenById(routeButton.dataset.screen);
  }
});

mockup.addEventListener("click", (event) => {
  const action = event.target.closest("[data-action]");
  if (!action) return;
  const actionFocusSelector = action.matches('[role="radio"]')
    ? stableFocusSelector(action)
    : null;

  if (action.dataset.action === "mode") {
    state.pomodoroMode = action.dataset.mode;
    renderMockup();
  }

  if (action.dataset.action === "duration") {
    state.focusMinutes = Number(action.dataset.value);
    renderMockup();
  }

  if (action.dataset.action === "open-dial") {
    openDial();
  }

  if (action.dataset.action === "complete-habit") {
    state.completedHabit = !state.completedHabit;
    renderMockup();
  }

  if (action.dataset.action === "toggle-focus-context") {
    state.focusContextOpen = !state.focusContextOpen;
    renderMockup();
  }

  if (action.dataset.action === "habit-category") {
    state.habitCategory = action.dataset.category;
    renderMockup();
  }

  if (action.dataset.action === "habit-frequency") {
    state.habitFrequency = action.dataset.frequency;
    if (state.habitFrequency === "weekdays") {
      state.habitDays = ["L", "M", "X", "J", "V"];
    }
    if (state.habitFrequency === "daily") {
      state.habitDays = ["L", "M", "X", "J", "V", "S", "D"];
    }
    renderMockup();
  }

  if (action.dataset.action === "habit-reminder") {
    state.habitReminderEnabled = !state.habitReminderEnabled;
    renderMockup();
  }

  if (action.dataset.action === "habit-day") {
    const day = action.dataset.day;
    if (state.habitDays.includes(day)) {
      if (state.habitDays.length > 1) {
        state.habitDays = state.habitDays.filter((item) => item !== day);
      }
    } else {
      state.habitDays = [...state.habitDays, day];
    }
    renderMockup();
  }

  if (action.dataset.action === "auth-existing") {
    state.authMode = "existing";
    renderMockup();
  }

  if (action.dataset.action === "auth-backup") {
    state.authMode = "backup";
    renderMockup();
  }

  if (action.dataset.action === "auth-choices") {
    state.authMode = "choices";
    renderMockup();
  }

  if (action.dataset.action === "onboarding-mode") {
    state.onboardingMode = action.dataset.mode;
    if (state.onboardingMode === "new") {
      state.onboardingStep = 0;
    }
    syncCurrentUrl();
    renderMockup({
      focusSelector: `[data-action="onboarding-mode"][data-mode="${state.onboardingMode}"]`,
      fallbackSelector: "#onboarding-title",
    });
  }

  if (action.dataset.action === "onboarding-next") {
    state.onboardingStep = Math.min(3, state.onboardingStep + 1);
    syncCurrentUrl();
    renderMockup({ focusSelector: "#onboarding-title" });
  }

  if (action.dataset.action === "onboarding-back") {
    state.onboardingStep = Math.max(0, state.onboardingStep - 1);
    syncCurrentUrl();
    renderMockup({ focusSelector: "#onboarding-title" });
  }

  if (action.dataset.action === "onboarding-talisman") {
    state.onboardingTalisman = action.dataset.value;
    renderMockup({ focusSelector: actionFocusSelector });
  }

  if (action.dataset.action === "onboarding-intent") {
    state.onboardingIntent = action.dataset.value;
    if (!state.onboardingHabitCustomized) {
      state.onboardingHabitTitle =
        onboardingIntents[state.onboardingIntent].habit;
    }
    renderMockup({ focusSelector: actionFocusSelector });
  }

  if (action.dataset.action === "onboarding-habit-choice") {
    state.onboardingHabitSkipped = action.dataset.value === "skip";
    renderMockup({ focusSelector: actionFocusSelector });
  }

  if (action.dataset.action === "onboarding-skip-habit") {
    state.onboardingHabitSkipped = true;
    state.onboardingStep = 3;
    syncCurrentUrl();
    renderMockup({ focusSelector: "#onboarding-title" });
  }

  if (action.dataset.action === "onboarding-create-habit") {
    state.onboardingHabitSkipped = false;
    if (!state.onboardingHabitTitle.trim()) {
      state.onboardingHabitTitle =
        onboardingIntents[state.onboardingIntent].habit;
    }
    state.onboardingStep = 3;
    syncCurrentUrl();
    renderMockup({ focusSelector: "#onboarding-title" });
  }

  if (action.dataset.action === "onboarding-confirm-habit") {
    if (!state.onboardingHabitSkipped && !state.onboardingHabitTitle.trim()) {
      state.onboardingHabitTitle =
        onboardingIntents[state.onboardingIntent].habit;
    }
    state.onboardingStep = 3;
    syncCurrentUrl();
    renderMockup({ focusSelector: "#onboarding-title" });
  }

  if (action.dataset.action === "onboarding-reminder") {
    state.onboardingReminderEnabled = action.dataset.value === "yes";
    if (!state.onboardingReminderEnabled) {
      state.onboardingPermission = "notDetermined";
    }
    syncCurrentUrl();
    renderMockup({ focusSelector: actionFocusSelector });
  }

  if (action.dataset.action === "onboarding-request-permission") {
    state.onboardingPermission = "requesting";
    syncCurrentUrl();
    renderMockup({
      focusSelector: '[role="status"]',
      fallbackSelector: "#onboarding-title",
    });
  }

  if (action.dataset.action === "onboarding-permission-state") {
    state.onboardingPermission = action.dataset.value;
    syncCurrentUrl();
    renderMockup({ focusSelector: actionFocusSelector });
  }

  if (action.dataset.action === "onboarding-timeout") {
    state.onboardingPermission = "error";
    syncCurrentUrl();
    renderMockup({
      focusSelector: '[role="status"]',
      fallbackSelector: "#onboarding-title",
    });
  }
});

mockup.addEventListener("keydown", (event) => {
  const radio = event.target.closest('[role="radio"]');
  const group = radio?.closest('[role="radiogroup"]');
  if (!radio || !group) return;

  const radios = [...group.querySelectorAll('[role="radio"]:not(:disabled)')];
  const currentIndex = radios.indexOf(radio);
  if (currentIndex < 0) return;

  let nextIndex = null;
  if (["ArrowRight", "ArrowDown"].includes(event.key)) {
    nextIndex = (currentIndex + 1) % radios.length;
  }
  if (["ArrowLeft", "ArrowUp"].includes(event.key)) {
    nextIndex = (currentIndex - 1 + radios.length) % radios.length;
  }
  if (event.key === "Home") nextIndex = 0;
  if (event.key === "End") nextIndex = radios.length - 1;
  if (nextIndex === null) return;

  event.preventDefault();
  radios[nextIndex].focus({ preventScroll: true });
  radios[nextIndex].click();
});

mockup.addEventListener("input", (event) => {
  if (event.target.matches("[data-onboarding-habit-input]")) {
    state.onboardingHabitTitle = event.target.value;
    state.onboardingHabitCustomized = true;
  }
});

mockup.addEventListener("change", (event) => {
  if (event.target.matches("[data-onboarding-reminder-time]")) {
    state.onboardingReminderTime = event.target.value;
    renderMockup();
  }
});

document.querySelectorAll("[data-viewport]").forEach((button) => {
  button.addEventListener("click", () => {
    state.viewport = button.dataset.viewport;
    document.querySelectorAll("[data-viewport]").forEach((item) => {
      const selected = item === button;
      item.classList.toggle("active", selected);
      item.setAttribute("aria-pressed", String(selected));
      if (selected) {
        item.setAttribute("aria-current", "true");
      } else {
        item.removeAttribute("aria-current");
      }
    });
    device.classList.toggle("tablet", state.viewport === "tablet");
    device.classList.toggle("phone", state.viewport === "phone");
    syncCurrentUrl();
  });
});

dialLayer.addEventListener("click", (event) => {
  const action = event.target.closest("[data-action]");
  if (!action) return;

  if (action.dataset.action === "close-dial") {
    closeDial();
  }

  if (action.dataset.action === "apply-dial") {
    state.focusMinutes = Number(minuteRange.value);
    closeDial();
    renderMockup();
  }
});

minuteRange.addEventListener("input", updateDial);

function applyLocationState() {
  const params = new URLSearchParams(window.location.search);
  const conceptIndex = concepts.findIndex(
    (concept) => concept.id === params.get("concept"),
  );
  const screenIndex = screens.findIndex(
    (screen) => screen.id === params.get("screen"),
  );
  const authMode = params.get("auth");
  const onboardingMode = params.get("onboarding");
  const onboardingStep = Number(params.get("step"));
  const permissionState = params.get("permission");

  if (conceptIndex >= 0) state.conceptIndex = conceptIndex;
  if (screenIndex >= 0) state.screenIndex = screenIndex;
  if (["choices", "existing", "backup"].includes(authMode)) {
    state.authMode = authMode;
  }
  if (["new", "restore"].includes(onboardingMode)) {
    state.onboardingMode = onboardingMode;
  }
  if (
    Number.isInteger(onboardingStep) &&
    onboardingStep >= 1 &&
    onboardingStep <= 4
  ) {
    state.onboardingStep = onboardingStep - 1;
  }
  if (onboardingPermissionStates.includes(permissionState)) {
    state.onboardingPermission = permissionState;
    state.onboardingReminderEnabled = true;
  }

  if (params.get("viewport") === "tablet") {
    state.viewport = "tablet";
  } else if (params.get("viewport") === "phone") {
    state.viewport = "phone";
  }
  device.classList.toggle("tablet", state.viewport === "tablet");
  device.classList.toggle("phone", state.viewport === "phone");
  document.querySelectorAll("[data-viewport]").forEach((button) => {
    const selected = button.dataset.viewport === state.viewport;
    button.classList.toggle("active", selected);
    button.setAttribute("aria-pressed", String(selected));
    if (selected) {
      button.setAttribute("aria-current", "true");
    } else {
      button.removeAttribute("aria-current");
    }
  });
}

applyLocationState();
renderAll();
syncCurrentUrl({ replace: true });

const initialParams = new URLSearchParams(window.location.search);
if (
  initialParams.get("dial") === "1" &&
  screens[state.screenIndex].id === "pomodoro"
) {
  openDial();
}

window.addEventListener("popstate", () => {
  clearOnboardingPermissionTimeout();
  applyLocationState();
  renderAll({
    fallbackSelector:
      currentScreenId() === "onboarding" ? "#onboarding-title" : null,
  });
});
