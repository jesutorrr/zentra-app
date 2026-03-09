import ActivityKit
import WidgetKit
import SwiftUI

struct ZentraActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Estado dinámico que cambia durante el timer
        var timerEndTime: Double? // Timestamp UNIX para evitar problemas de serialización
        var sessionType: String // "work", "shortBreak", "longBreak"
        var isPaused: Bool
        var progress: Double // 0.0 a 1.0 para barras visuales estáticas
    }

    // Datos estáticos que no cambian (o raramente)
    var activityName: String
}
