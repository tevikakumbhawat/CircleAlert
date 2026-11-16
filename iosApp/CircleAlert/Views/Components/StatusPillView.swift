import SwiftUI

struct StatusPillView: View {
    let status: MemberGeofenceStatusModel
    var hasActiveGeofence: Bool = true

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(indicatorColor)
                .frame(width: 8, height: 8)

            Text(displayText)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(textColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(backgroundColor)
        .clipShape(Capsule())
    }

    private var displayText: String {
        guard hasActiveGeofence else {
            return "No Zone Set"
        }
        return status.title
    }

    private var indicatorColor: Color {
        guard hasActiveGeofence else { return .gray }
        switch status {
        case .inside: return .green
        case .outside: return .red
        case .unknown: return .gray
        }
    }

    private var textColor: Color {
        guard hasActiveGeofence else { return .secondary }
        switch status {
        case .inside: return .green
        case .outside: return .red
        case .unknown: return .secondary
        }
    }

    private var backgroundColor: Color {
        guard hasActiveGeofence else { return Color.gray.opacity(0.12) }
        switch status {
        case .inside: return Color.green.opacity(0.12)
        case .outside: return Color.red.opacity(0.12)
        case .unknown: return Color.gray.opacity(0.12)
        }
    }
}
