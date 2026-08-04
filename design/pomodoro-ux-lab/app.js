const proposals = [
  {
    id: "two-paths",
    name: "Dos caminos",
    subtitle:
      "La elección aparece primero y explica claramente qué obtiene el usuario en cada modo.",
    score: "9.4",
    recommended: true,
    strengths: [
      "Se entiende sin conocer la técnica Pomodoro.",
      "Hace visible la diferencia entre una sesión y un ciclo.",
      "Permite configurar después de elegir, con contexto.",
    ],
    risk:
      "Agrega una decisión antes de iniciar. Podemos recordar el último modo para usuarios frecuentes.",
    verdict:
      "Es la base más fuerte. Tomaría esta propuesta y le añadiría la rapidez visual de la propuesta 3.",
    ratings: [5, 4, 5],
    tableVerdict: "Recomendada como arquitectura principal.",
  },
  {
    id: "goal-first",
    name: "Objetivo primero",
    subtitle:
      "Primero pregunta qué quieres lograr y después presenta el tipo de sesión como una configuración.",
    score: "8.8",
    strengths: [
      "Conecta el temporizador con una intención real.",
      "El historial tendría nombres útiles por defecto.",
      "Reduce la sensación de usar un cronómetro genérico.",
    ],
    risk:
      "Pedir texto antes de iniciar puede sentirse pesado para una sesión rápida.",
    verdict:
      "Muy buena para productividad profunda. La usaría como flujo del Ciclo Pomodoro, no como entrada universal.",
    ratings: [4, 4, 5],
    tableVerdict: "Ideal dentro del modo Ciclo.",
  },
  {
    id: "big-presets",
    name: "Tarjetas directas",
    subtitle:
      "Dos tarjetas grandes convierten cada modo en una acción inmediata, con sus tiempos siempre visibles.",
    score: "9.1",
    strengths: [
      "Es la opción más rápida de escanear.",
      "Funciona muy bien para usuarios recurrentes.",
      "Los tiempos se entienden antes de tocar.",
    ],
    risk:
      "Si las tarjetas crecen con más opciones, la pantalla puede volverse un menú de presets.",
    verdict:
      "Mi segunda favorita. Visualmente es la más sencilla y complementa muy bien la propuesta 1.",
    ratings: [5, 5, 5],
    tableVerdict: "Excelente para la portada de Pomodoro.",
  },
  {
    id: "timer-first",
    name: "Reloj primero",
    subtitle:
      "Conserva el temporizador como héroe y deja los dos modos como un selector persistente debajo.",
    score: "7.7",
    strengths: [
      "Mantiene el aspecto premium del círculo actual.",
      "Un usuario frecuente inicia con muy pocos toques.",
      "El estado activo tiene continuidad visual.",
    ],
    risk:
      "La diferencia entre los modos vuelve a quedar subordinada al reloj. Repite parte de la ambigüedad actual.",
    verdict:
      "Se ve bonita, pero no resuelve suficientemente el problema de comprensión. No la elegiría como portada.",
    ratings: [3, 5, 4],
    tableVerdict: "Rápida, pero todavía ambigua.",
  },
  {
    id: "guided",
    name: "Asistente guiado",
    subtitle:
      "Un recorrido de tres pasos ayuda a elegir modo, objetivo y tiempos antes de iniciar.",
    score: "8.2",
    strengths: [
      "Nadie comienza sin entender qué configuró.",
      "Excelente para primera vez y accesibilidad cognitiva.",
      "Permite explicar notificaciones y descansos en contexto.",
    ],
    risk:
      "Demasiados pasos para algo que el usuario repetirá todos los días.",
    verdict:
      "Lo reservaría para onboarding o para crear un ciclo personalizado, no para cada inicio.",
    ratings: [5, 2, 4],
    tableVerdict: "Útil como onboarding, no como home.",
  },
];

const state = {
  proposalIndex: 0,
  viewport: "phone",
  mode: "quick",
  focus: 25,
  shortBreak: 5,
  longBreak: 15,
  cycles: 4,
  activity: "",
  running: false,
  remainingSeconds: 25 * 60,
  wizardStep: 1,
};

let timerId = null;

const nav = document.querySelector("#variant-nav");
const mockup = document.querySelector("#mockup");
const device = document.querySelector("#device");
const dialog = document.querySelector("#settings-dialog");

function iconButton(label, symbol) {
  return `<button class="icon-button" type="button" aria-label="${label}"><span aria-hidden="true">${symbol}</span></button>`;
}

function header(title = "Pomodoro", subtitle = "Elige cómo quieres enfocarte") {
  return `
    <header class="mobile-header">
      <div>
        <h2 class="mobile-title">${title}</h2>
        <p class="mobile-subtitle">${subtitle}</p>
      </div>
      <div class="header-actions">
        ${iconButton("Historial", "↺")}
        <button class="icon-button" data-action="settings" type="button" aria-label="Configurar tiempos">
          <span aria-hidden="true">⋯</span>
        </button>
      </div>
    </header>
  `;
}

function activityField({ required = false } = {}) {
  return `
    <label class="field-label">
      En qué te enfocarás ${required ? "" : "(opcional)"}
      <input
        class="text-field"
        data-role="activity"
        value="${escapeHtml(state.activity)}"
        placeholder="${required ? "Ej. Preparar presentación" : "Ej. Revisar correos"}"
      />
    </label>
  `;
}

function modeCards() {
  return `
    <div class="mode-stack">
      <button class="mode-card ${state.mode === "quick" ? "active" : ""}" data-action="mode" data-mode="quick" type="button">
        <div class="mode-card-head">
          <span class="mode-icon">1x</span>
          <span>
            <strong>Enfoque rápido</strong>
            <small>Una sola sesión. Ideal para empezar ahora.</small>
          </span>
          <span class="selection-dot" aria-hidden="true"></span>
        </div>
      </button>
      <button class="mode-card ${state.mode === "cycle" ? "active" : ""}" data-action="mode" data-mode="cycle" type="button">
        <div class="mode-card-head">
          <span class="mode-icon cycle-icon">4x</span>
          <span>
            <strong>Ciclo Pomodoro</strong>
            <small>${state.cycles} enfoques con descansos guiados.</small>
          </span>
          <span class="selection-dot" aria-hidden="true"></span>
        </div>
      </button>
    </div>
  `;
}

function focusPresetSelector(label = "Tiempo de enfoque") {
  const presets = [15, 25, 45];
  const usesCustomValue = !presets.includes(state.focus);

  return `
    <div class="focus-presets">
      <div class="focus-presets-label">
        <span>${label}</span>
        <strong>${state.focus} min</strong>
      </div>
      <div class="focus-preset-options" role="group" aria-label="${label}">
        ${presets
          .map(
            (minutes) => `
              <button
                class="focus-preset ${state.focus === minutes ? "active" : ""}"
                data-action="focus-preset"
                data-minutes="${minutes}"
                type="button"
              >
                ${minutes}
              </button>
            `,
          )
          .join("")}
        <button
          class="focus-preset custom ${usesCustomValue ? "active" : ""}"
          data-action="settings"
          type="button"
        >
          ${usesCustomValue ? `${state.focus} min` : "Otro"}
        </button>
      </div>
    </div>
  `;
}

function settingsSummary() {
  if (state.mode === "quick") {
    return `
      ${focusPresetSelector()}
    `;
  }

  return `
    ${focusPresetSelector()}
    <div class="cycle-preview" aria-label="${state.cycles} sesiones">
      ${Array.from({ length: state.cycles }, () => '<span class="cycle-step"></span>').join("")}
    </div>
    <div class="meta-row">
      <span>${state.cycles} sesiones · Descansos</span>
      <strong>${state.shortBreak} min cortos · ${state.longBreak} min largo</strong>
      <button class="inline-link" data-action="settings" type="button">Ajustar</button>
    </div>
  `;
}

function startLabel() {
  return state.mode === "quick"
    ? `Iniciar enfoque de ${state.focus} min`
    : `Iniciar ciclo de ${state.cycles} sesiones`;
}

function renderTwoPaths() {
  return `
    <div class="mobile-page">
      ${header()}
      <main class="mobile-content">
        <div class="intro-copy">
          <h3>¿Qué necesitas hoy?</h3>
          <p>Una sesión rápida o un ciclo completo con descansos.</p>
        </div>
        ${modeCards()}
        <div class="selection-details">
          ${activityField({ required: state.mode === "cycle" })}
          ${settingsSummary()}
          <button class="primary-action full" data-action="start" type="button">${startLabel()}</button>
        </div>
      </main>
    </div>
  `;
}

function renderGoalFirst() {
  return `
    <div class="mobile-page">
      ${header("Nuevo enfoque", "Primero define qué quieres avanzar")}
      <main class="mobile-content">
        <section class="goal-hero">
          <h3>¿Qué quieres sacar adelante?</h3>
          <p>Nombrarlo ayuda a proteger este tiempo y hace que tu historial sea útil.</p>
          ${activityField()}
        </section>
        <div style="height: 14px"></div>
        <div class="mode-tabs" aria-label="Tipo de sesión">
          <button class="mode-tab ${state.mode === "quick" ? "active" : ""}" data-action="mode" data-mode="quick" type="button">Enfoque rápido</button>
          <button class="mode-tab ${state.mode === "cycle" ? "active" : ""}" data-action="mode" data-mode="cycle" type="button">Ciclo Pomodoro</button>
        </div>
        <div class="selection-details">
          ${settingsSummary()}
          <button class="primary-action full" data-action="start" type="button">${startLabel()}</button>
        </div>
      </main>
    </div>
  `;
}

function renderBigPresets() {
  return `
    <div class="mobile-page">
      ${header("Pomodoro", "Elige una opción para comenzar")}
      <main class="mobile-content">
        <div class="preset-stack">
          <button class="preset-card quick" data-action="start-mode" data-mode="quick" type="button">
            <div class="preset-head">
              <span class="mode-icon">1x</span>
              <span>
                <strong>Enfoque rápido</strong>
                <small>Una sesión sin complicaciones</small>
              </span>
              <span class="preset-time">${state.focus}</span>
            </div>
            <div class="mini-config">
              <span class="mini-chip">${state.focus} min</span>
              <span class="mini-chip">Actividad opcional</span>
            </div>
          </button>
          <button class="preset-card cycle" data-action="choose-cycle" type="button">
            <div class="preset-head">
              <span class="mode-icon cycle-icon">4x</span>
              <span>
                <strong>Ciclo Pomodoro</strong>
                <small>Enfoque profundo con pausas</small>
              </span>
              <span class="preset-time">${state.cycles}x</span>
            </div>
            <div class="mini-config">
              <span class="mini-chip">${state.cycles} × ${state.focus} min</span>
              <span class="mini-chip">Pausas ${state.shortBreak}/${state.longBreak}</span>
            </div>
          </button>
        </div>
        <div class="selection-details">
          ${activityField({ required: state.mode === "cycle" })}
          ${focusPresetSelector()}
          <button class="primary-action full" data-action="start" type="button">${startLabel()}</button>
          ${
            state.mode === "cycle"
              ? '<button class="inline-link" data-action="settings" type="button">Ajustar descansos y número de sesiones</button>'
              : ""
          }
        </div>
        <div class="intro-copy" style="margin-top: 18px">
          <h3 style="font-size: 14px">Tu última configuración</h3>
          <p>${state.focus} min de enfoque · ${state.shortBreak} min de descanso</p>
        </div>
      </main>
    </div>
  `;
}

function renderTimerFirst() {
  return `
    <div class="mobile-page">
      ${header("Pomodoro", state.mode === "quick" ? "Enfoque rápido" : "Ciclo Pomodoro")}
      <main class="mobile-content">
        <div class="timer-hero">
          <div class="timer-ring">
            <div class="timer-center">
              <small>${state.mode === "quick" ? "Enfoque rápido" : `Sesión 1 de ${state.cycles}`}</small>
              <span class="timer-value">${state.focus}:00</span>
            </div>
          </div>
        </div>
        ${activityField()}
        <div style="height: 12px"></div>
        ${focusPresetSelector()}
        <div style="height: 12px"></div>
        <button class="primary-action full" data-action="start" type="button">${startLabel()}</button>
        <div class="timer-mode-dock">
          <button class="timer-mode-button ${state.mode === "quick" ? "active" : ""}" data-action="mode" data-mode="quick" type="button">
            <strong>Enfoque rápido</strong><small>${state.focus} minutos</small>
          </button>
          <button class="timer-mode-button ${state.mode === "cycle" ? "active" : ""}" data-action="mode" data-mode="cycle" type="button">
            <strong>Ciclo Pomodoro</strong><small>${state.cycles} sesiones</small>
          </button>
        </div>
      </main>
    </div>
  `;
}

function wizardContent() {
  if (state.wizardStep === 1) {
    return `
      <h3>Elige tu tipo de enfoque</h3>
      <p>Después podrás personalizar los tiempos antes de comenzar.</p>
      ${modeCards()}
    `;
  }

  if (state.wizardStep === 2) {
    return `
      <h3>${state.mode === "quick" ? "Ponle intención" : "Nombra este ciclo"}</h3>
      <p>${state.mode === "quick" ? "Es opcional. Puedes comenzar sin escribir nada." : "Esto aparecerá durante las cuatro sesiones y en tu historial."}</p>
      ${activityField({ required: state.mode === "cycle" })}
    `;
  }

  return `
    <h3>Todo listo</h3>
    <p>Revisa el plan. El temporizador comenzará inmediatamente al confirmar.</p>
    <div class="selection-details">
      ${settingsSummary()}
      <div class="meta-row"><span>Objetivo</span><strong>${escapeHtml(state.activity) || "Enfoque libre"}</strong></div>
    </div>
  `;
}

function renderGuided() {
  return `
    <div class="mobile-page">
      ${header("Preparar sesión", `Paso ${state.wizardStep} de 3`)}
      <main class="mobile-content">
        <div class="wizard-progress">
          ${[1, 2, 3].map((step) => `<span class="wizard-dot ${step === state.wizardStep ? "active" : ""}"></span>`).join("")}
        </div>
        <section class="wizard-card">
          ${wizardContent()}
          <div class="wizard-actions">
            ${state.wizardStep > 1 ? '<button class="secondary-action" data-action="wizard-back" type="button">Atrás</button>' : ""}
            ${
              state.wizardStep < 3
                ? '<button class="primary-action" data-action="wizard-next" type="button">Continuar</button>'
                : `<button class="primary-action" data-action="start" type="button">${startLabel()}</button>`
            }
          </div>
        </section>
      </main>
    </div>
  `;
}

function renderRunning() {
  const activity = state.activity.trim() || "Enfoque libre";
  const cycleDots =
    state.mode === "cycle"
      ? `<div class="cycle-dots">${Array.from({ length: state.cycles }, (_, index) => `<span class="cycle-dot ${index === 0 ? "active" : ""}"></span>`).join("")}</div>`
      : "";

  return `
    <div class="mobile-page running-page">
      ${header(state.mode === "quick" ? "Enfoque rápido" : "Ciclo Pomodoro", state.running ? "Sesión en curso" : "Sesión pausada")}
      <main class="mobile-content">
        <div class="running-context">
          <strong>${escapeHtml(activity)}</strong>
          <span>${state.mode === "quick" ? "Una sesión de enfoque" : `Enfoque 1 de ${state.cycles}`}</span>
        </div>
        <div class="timer-ring">
          <div class="timer-center">
            <small>${state.running ? "En progreso" : "Pausado"}</small>
            <span class="timer-value" data-role="timer">${formatTime(state.remainingSeconds)}</span>
          </div>
        </div>
        ${cycleDots}
        <div class="running-actions">
          <button class="secondary-action" data-action="finish-early" type="button">Terminar antes</button>
          <button class="primary-action" data-action="toggle-timer" type="button">${state.running ? "Pausar" : "Continuar"}</button>
        </div>
      </main>
    </div>
  `;
}

function renderProposal() {
  const proposal = proposals[state.proposalIndex];
  document.querySelector("#proposal-title").textContent = proposal.name;
  document.querySelector("#proposal-subtitle").textContent = proposal.subtitle;
  document.querySelector("#proposal-score").textContent = proposal.score;
  document.querySelector("#proposal-risk").textContent = proposal.risk;
  document.querySelector("#proposal-verdict").textContent = proposal.verdict;
  document.querySelector("#proposal-strengths").innerHTML = proposal.strengths
    .map((strength) => `<li>${strength}</li>`)
    .join("");

  if (state.running || timerId !== null) {
    mockup.innerHTML = renderRunning();
    return;
  }

  const renderers = [
    renderTwoPaths,
    renderGoalFirst,
    renderBigPresets,
    renderTimerFirst,
    renderGuided,
  ];
  mockup.innerHTML = renderers[state.proposalIndex]();
}

function renderNavigation() {
  nav.innerHTML = proposals
    .map(
      (proposal, index) => `
        <button class="variant-button ${index === state.proposalIndex ? "active" : ""}" data-proposal="${index}" type="button">
          <span class="variant-number">0${index + 1}</span>
          <span class="variant-name">${proposal.name}</span>
          ${proposal.recommended ? '<span class="recommended-tag">Mi voto</span>' : ""}
        </button>
      `,
    )
    .join("");
}

function renderRating(value) {
  return `<span class="rating" aria-label="${value} de 5">${Array.from(
    { length: 5 },
    (_, index) => `<i class="${index < value ? "on" : ""}"></i>`,
  ).join("")}</span>`;
}

function renderComparison() {
  document.querySelector("#comparison-body").innerHTML = proposals
    .map(
      (proposal, index) => `
        <tr>
          <td><span class="table-title">0${index + 1}. ${proposal.name}</span></td>
          <td>${renderRating(proposal.ratings[0])}</td>
          <td>${renderRating(proposal.ratings[1])}</td>
          <td>${renderRating(proposal.ratings[2])}</td>
          <td class="table-verdict">${proposal.tableVerdict}</td>
        </tr>
      `,
    )
    .join("");
}

function renderAll() {
  renderNavigation();
  renderProposal();
  renderComparison();
}

function resetDemo() {
  clearInterval(timerId);
  timerId = null;
  state.mode = "quick";
  state.activity = "";
  state.running = false;
  state.remainingSeconds = state.focus * 60;
  state.wizardStep = 1;
  renderAll();
}

function startTimer() {
  state.remainingSeconds = state.focus * 60;
  state.running = true;
  clearInterval(timerId);
  timerId = setInterval(() => {
    if (!state.running) return;
    state.remainingSeconds = Math.max(0, state.remainingSeconds - 1);
    const timer = document.querySelector('[data-role="timer"]');
    if (timer) timer.textContent = formatTime(state.remainingSeconds);
    if (state.remainingSeconds === 0) {
      clearInterval(timerId);
      timerId = null;
      state.running = false;
      renderProposal();
    }
  }, 1000);
  renderProposal();
}

function openSettings() {
  document.querySelector("#focus-range").value = state.focus;
  document.querySelector("#short-range").value = state.shortBreak;
  document.querySelector("#long-range").value = state.longBreak;
  document.querySelector("#cycles-range").value = state.cycles;
  updateOutputs();
  document.querySelector("#cycle-settings").hidden = state.mode === "quick";
  dialog.showModal();
}

function updateOutputs() {
  document.querySelector("#focus-output").textContent =
    `${document.querySelector("#focus-range").value} min`;
  document.querySelector("#short-output").textContent =
    `${document.querySelector("#short-range").value} min`;
  document.querySelector("#long-output").textContent =
    `${document.querySelector("#long-range").value} min`;
  document.querySelector("#cycles-output").textContent =
    `${document.querySelector("#cycles-range").value} sesiones`;
}

function saveSettings() {
  state.focus = Number(document.querySelector("#focus-range").value);
  state.shortBreak = Number(document.querySelector("#short-range").value);
  state.longBreak = Number(document.querySelector("#long-range").value);
  state.cycles = Number(document.querySelector("#cycles-range").value);
  state.remainingSeconds = state.focus * 60;
  renderAll();
}

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function formatTime(seconds) {
  const minutes = Math.floor(seconds / 60);
  const remainder = seconds % 60;
  return `${String(minutes).padStart(2, "0")}:${String(remainder).padStart(2, "0")}`;
}

nav.addEventListener("click", (event) => {
  const button = event.target.closest("[data-proposal]");
  if (!button) return;
  resetDemo();
  state.proposalIndex = Number(button.dataset.proposal);
  renderAll();
});

mockup.addEventListener("input", (event) => {
  if (event.target.matches('[data-role="activity"]')) {
    state.activity = event.target.value;
  }
});

mockup.addEventListener("click", (event) => {
  const action = event.target.closest("[data-action]");
  if (!action) return;

  switch (action.dataset.action) {
    case "mode":
      state.mode = action.dataset.mode;
      state.remainingSeconds = state.focus * 60;
      renderProposal();
      break;
    case "settings":
      openSettings();
      break;
    case "focus-preset":
      state.focus = Number(action.dataset.minutes);
      state.remainingSeconds = state.focus * 60;
      renderAll();
      break;
    case "start":
      startTimer();
      break;
    case "start-mode":
      state.mode = action.dataset.mode;
      startTimer();
      break;
    case "choose-cycle":
      state.mode = "cycle";
      renderProposal();
      break;
    case "toggle-timer":
      state.running = !state.running;
      renderProposal();
      break;
    case "finish-early":
      resetDemo();
      break;
    case "wizard-next":
      state.wizardStep = Math.min(3, state.wizardStep + 1);
      renderProposal();
      break;
    case "wizard-back":
      state.wizardStep = Math.max(1, state.wizardStep - 1);
      renderProposal();
      break;
  }
});

document.querySelectorAll("[data-viewport]").forEach((button) => {
  button.addEventListener("click", () => {
    state.viewport = button.dataset.viewport;
    document.querySelectorAll("[data-viewport]").forEach((item) => {
      item.classList.toggle("active", item === button);
    });
    device.classList.toggle("tablet", state.viewport === "tablet");
    device.classList.toggle("phone", state.viewport === "phone");
  });
});

document.querySelector("#reset-demo").addEventListener("click", resetDemo);
document.querySelector("#save-settings").addEventListener("click", saveSettings);
document
  .querySelectorAll('.duration-control input[type="range"]')
  .forEach((range) => range.addEventListener("input", updateOutputs));

renderAll();
