import SwiftUI

struct DurationField: View {
    let caption: String
    let suffix: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    var compact = false

    @FocusState private var isFocused: Bool

    private var numberFontSize: CGFloat { compact ? 26 : 40 }
    private var suffixFontSize: CGFloat { compact ? 15 : 21 }
    private var fieldWidth: CGFloat { compact ? 56 : 86 }
    private var fieldHeight: CGFloat { compact ? 44 : 62 }
    private var horizontalPadding: CGFloat { compact ? 9 : 14 }
    private var cornerRadius: CGFloat { compact ? 10 : 13 }
    private var captionFont: Font { compact ? .caption2 : .caption }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 3 : 5) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                TextField("0", value: $value, format: .number.grouping(.never))
                    .textFieldStyle(.plain)
                    .font(.system(size: numberFontSize, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .multilineTextAlignment(.trailing)
                    .frame(width: fieldWidth)
                    .focused($isFocused)
                    .accessibilityLabel(caption.isEmpty ? "Duration \(suffix)" : caption)

                Text(suffix)
                    .font(.system(size: suffixFontSize, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, horizontalPadding)
            .frame(height: fieldHeight)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.primary.opacity(isFocused ? 0.09 : 0.06))
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        isFocused ? Color.accentColor.opacity(0.75) : Color.primary.opacity(0.08),
                        lineWidth: isFocused ? 1.5 : 1
                    )
            }
            .animation(.easeOut(duration: 0.15), value: isFocused)

            if !caption.isEmpty {
                Text(caption)
                    .font(captionFont)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 5)
            }
        }
        .onChange(of: value) { _, newValue in
            let clamped = min(max(newValue, range.lowerBound), range.upperBound)
            if clamped != newValue {
                value = clamped
            }
        }
    }
}
