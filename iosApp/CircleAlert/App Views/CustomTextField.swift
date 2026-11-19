import SwiftUI

struct CustomTextField: View {
    let title: String
    let icon: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .never

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 22)

            if isSecure {
                SecureField(title, text: $text)
            } else {
                TextField(title, text: $text)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(autocapitalization)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(uiColor: .separator).opacity(0.4), lineWidth: 1)
        )
    }
}
