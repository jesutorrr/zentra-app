/// Application-wide constants
/// 
/// This file centralizes magic numbers, strings, and configuration values
/// to improve maintainability and consistency across the app.
library;

// ============================================================================
// TIME & DURATION CONSTANTS
// ============================================================================

/// Number of days to retain Pomodoro activity history
const int kPomodoroRetentionDays = 30;

/// Number of days to show in weekly progress chart
const int kWeeklyProgressDays = 7;

/// Default Pomodoro work duration in minutes
const int kDefaultPomodoroDuration = 25;

/// Default short break duration in minutes
const int kDefaultShortBreakDuration = 5;

/// Default long break duration in minutes
const int kDefaultLongBreakDuration = 15;

/// Number of pomodoros before a long break
const int kPomodorosUntilLongBreak = 4;

// ============================================================================
// UI LAYOUT CONSTANTS
// ============================================================================

/// Maximum width for content on larger screens (tablets/web)
const double kMaxContentWidth = 600.0;

/// Standard page padding
const double kPagePadding = 20.0;

/// Standard card border radius
const double kCardBorderRadius = 24.0;

/// Standard small border radius
const double kSmallBorderRadius = 12.0;

// ============================================================================
// EMOJI LISTS
// ============================================================================

/// Available avatar emojis for profile selection (35 total = 5 rows de 7)
const List<String> kAvatarEmojis = [
  // Row 1 - Faces & Symbols
  '😊', '😎', '🚀', '💪', '🔥', '⭐', '🎯',
  // Row 2 - Achievements & Animals
  '🏆', '🌟', '💫', '🦁', '🐯', '🦊', '🐻',
  // Row 3 - More Animals
  '🐼', '🐨', '🐸', '🦄', '🐲', '🦋', '🌸',
  // Row 4 - Nature & Objects
  '🌺', '🍀', '⚡', '💎', '🎸', '🎮', '🏀',
  // Row 5 - Sports & Activities
  '⚽', '🎨', '🎭', '🎪', '🌈', '🍕', '☕',
];

/// Compact avatar emoji list for quick profile creation
const List<String> kCompactAvatarEmojis = [
  '😊', '😎', '🚀', '💪', '🔥', '⭐', '🎯', '🏆', '🌟', '💫',
  '🦁', '🐯', '🦊', '🐻', '🐼',
];

// ============================================================================
// MOTIVATIONAL PHRASES
// ============================================================================

/// Motivational phrases shown when completing all habits for the day
/// 65 unique Spanish messages to celebrate daily achievements (gender-neutral)
const List<String> kMotivationalPhrases = [
  // Celebración general
  '¡Increíble! Hoy fue un gran día.',
  'La constancia es la madre del éxito. ¡Sigue así!',
  'Cada día que completas es un paso más hacia tu mejor versión.',
  '¡Lo lograste! Los pequeños pasos llevan a grandes cambios.',
  'Tu disciplina de hoy es tu libertad de mañana.',
  'Imparable. Nada puede detenerte.',
  '¡Excelente trabajo! Tu futuro yo te lo agradecerá.',
  'La grandeza no es casualidad, es constancia. ¡Bravo!',
  'Hoy venciste a la procrastinación. ¡Eso es ganar!',
  'Tu compromiso es admirable. ¡Felicidades!',
  'Otro día completado, otra victoria.',
  '¡Asombroso! Estás construyendo hábitos que durarán toda la vida.',
  'La mejor inversión es en uno mismo. Hoy lo demostraste.',
  'No hay atajos hacia el éxito, pero vas por el camino correcto.',
  '¡Fantástico! Tu determinación es inspiradora.',
  'Cada hábito completado es una promesa cumplida.',
  'Hoy elegiste ser mejor. Esa decisión vale oro.',
  '¡Brillante! La consistencia te llevará muy lejos.',
  'Los sueños se construyen día a día. Hoy lo probaste.',
  'Tu esfuerzo de hoy es el resultado de mañana. ¡Genial!',
  'La disciplina es el puente entre metas y logros. ¡Lo cruzaste!',
  '¡Maravilloso! Estás más cerca de tus objetivos que ayer.',
  'El secreto del éxito es la constancia. Tú lo tienes.',
  'Hoy hubo superación. ¡Eso es verdadero progreso!',
  '¡Impresionante! La dedicación está dando frutos.',
  'Cada día que avanzas, dejas atrás una versión anterior.',
  'La excelencia es un hábito. ¡Y lo estás formando!',
  'El compromiso habla más fuerte que cualquier palabra.',
  '¡Sensacional! Los grandes días se hacen así.',
  'No se trata de ser perfecto, sino de ser constante. ¡Lo lograste!',
  'Hoy escribiste otra página de tu historia de éxito.',
  '¡Extraordinario! La perseverancia es un superpoder.',
  'Los grandes logros son la suma de pequeñas acciones diarias.',
  'Tu yo del futuro estará agradecido por lo de hoy.',
  '¡Fenomenal! Estás creando la vida que mereces.',
  'La motivación te pone en marcha, los hábitos te mantienen. ¡Excelente!',
  'Hoy elegiste crecer. Esa es la mejor elección posible.',
  '¡Sobresaliente! El esfuerzo constante marca la diferencia.',
  'Cada hábito cumplido es un ladrillo en tu castillo de éxito.',
  'La mejor versión de ti se construye día a día. ¡Sigue!',
  '¡Magnífico! La disciplina abre puertas que el talento no puede.',
  'Hoy probaste que puedes confiar en ti.',
  'El éxito no es un destino, es un viaje. ¡Y vas muy bien!',
  '¡Espectacular! La constancia te hace invencible.',
  'Otro día, otra victoria silenciosa pero poderosa.',
  'Un futuro brillante se construye con días como este.',
  '¡Tremendo! La perseverancia siempre gana al final.',
  'Hoy ganaste. ¡Celebra tu victoria!',
  'La clave del cambio está en la repetición. ¡Lo entendiste!',
  '¡Sublime! Tu dedicación es el ejemplo a seguir.',
  // Enfocadas en el proceso
  'El progreso, no la perfección, es lo que importa.',
  'Un 1% mejor cada día = 37 veces mejor en un año.',
  'Los hábitos son el interés compuesto del crecimiento personal.',
  // Enfocadas en la identidad
  'No solo completaste hábitos, reforzaste quién quieres ser.',
  'Hoy actuaste como la persona que quieres llegar a ser.',
  'Cada check es un voto por tu mejor versión.',
  // Para días difíciles
  'Incluso un día difícil con hábitos es mejor que uno sin ellos.',
  'El éxito no es lineal. Lo importante es no rendirse.',
  // Con humor/ligereza
  'Tu yo de hace un mes estaría feliz de verte hoy.',
  'Otro día, otro paso hacia ser funcional. 😎',
  '¿Quién necesita superpoderes cuando hay disciplina?',
  // Específicas para TDAH/organización
  'Completar algo es mejor que planear todo perfectamente.',
  'El cerebro quería distraerse, pero ganaste hoy.',
  'Estructura + constancia = libertad. ¡Lo estás logrando!',
];
