import SwiftUI

struct CustomSlider: View {
    let label: String
    @Binding var value: Double
    var range: ClosedRange<Double>
    
    var body: some View {
       VStack {
           Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
           Spacer()
           Text("\(value, specifier: "%.2f")")
                .monospacedDigit()
                .font(.caption)
                .padding(.horizontal, 6)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(4)
        }
        Slider(value: $value, in: range)
            .tint(.accentColor)
    }
}
