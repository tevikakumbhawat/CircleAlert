import SwiftUI

struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var isLoading: Bool = false
    var isDestructive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(isDestructive ? Color.red : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(color: (isDestructive ? Color.red : Color.blue).opacity(0.25), radius: 6, x: 0, y: 3)
        }
        .disabled(isLoading)
    }
}
