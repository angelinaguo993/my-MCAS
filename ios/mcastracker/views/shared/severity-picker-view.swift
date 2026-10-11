import SwiftUI

/// Reusable 1-10 severity slider
struct SeverityPickerView: View {
    let label: String
    @Binding var value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.nSubheadline)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text("\(value)/10")
                    .font(.nSubheadlineBold)
                    .foregroundColor(Theme.accent)
            }
            Slider(value: Binding(
                get: { Double(value) },
                set: { value = Int($0.rounded()) }
            ), in: 1...10, step: 1)
            .tint(Theme.primary)
        }
    }
}

struct SeverityPickerView_Previews: PreviewProvider {
    static var previews: some View {
        SeverityPickerView(label: "Overall severity", value: .constant(6))
            .padding()
    }
}
