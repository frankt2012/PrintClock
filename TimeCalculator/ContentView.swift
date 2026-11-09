import AppKit
import SwiftUI
import TimeCalculatorKit

struct ContentView: View {
    private enum StartMode: String, CaseIterable, Identifiable {
        case now = "Now"
        case custom = "Custom"

        var id: String { rawValue }
    }

    private struct QuickDuration: Identifiable {
        let label: String
        let hours: Int
        let minutes: Int

        var id: String { label }
    }

    private static let quickDurations: [QuickDuration] = [
        QuickDuration(label: "30m", hours: 0, minutes: 30),
        QuickDuration(label: "1h", hours: 1, minutes: 0),
        QuickDuration(label: "2h", hours: 2, minutes: 0),
        QuickDuration(label: "4h", hours: 4, minutes: 0),
        QuickDuration(label: "8h", hours: 8, minutes: 0)
    ]

    @AppStorage("printHours") private var hours = 0
    @AppStorage("printMinutes") private var minutes = 0

    @State private var startMode: StartMode = .now
    @State private var anchor = Date.now
    @State private var customStart = Date.now
    @State private var copied = false

    private var start: Date {
        startMode == .now ? anchor : customStart
    }

    private var duration: TimeInterval {
        PrintTime.duration(hours: hours, minutes: minutes)
    }

    private var hasDuration: Bool {
        duration > 0
    }

    private var finish: Date {
        start.addingTimeInterval(duration)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            durationCard
            startCard
            resultCard
        }
        .padding(22)
        .frame(width: 470)
        .background {
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor),
                    Color.accentColor.opacity(0.08)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
        .onChange(of: hours) { _, _ in
            reanchorIfNeeded()
        }
        .onChange(of: minutes) { _, _ in
            reanchorIfNeeded()
        }
        .onChange(of: startMode) { _, newMode in
            if newMode == .now {
                anchor = .now
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.30, green: 0.27, blue: 0.78),
                                Color(red: 0.55, green: 0.36, blue: 0.90)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Image(systemName: "clock.badge.checkmark")
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 46, height: 46)
            .shadow(color: Color.accentColor.opacity(0.24), radius: 8, y: 3)

            VStack(alignment: .leading, spacing: 2) {
                Text("Time Calculator")
                    .font(.title2.weight(.semibold))
                Text("Know exactly when your 3D print finishes.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - Duration

    private var durationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Print time", systemImage: "hourglass")
                    .font(.headline)

                Spacer()

                Text(hasDuration ? PrintTime.durationText(hours: hours, minutes: minutes) : "From your slicer")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .top, spacing: 12) {
                DurationField(caption: "Hours", suffix: "h", value: $hours, range: 0...999)
                DurationField(caption: "Minutes", suffix: "m", value: $minutes, range: 0...59)
                Spacer(minLength: 0)
            }

            HStack(spacing: 6) {
                Text("Quick")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(Self.quickDurations) { quick in
                    Button(quick.label) {
                        hours = quick.hours
                        minutes = quick.minutes
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .controlSize(.small)
                    .help("Set the print time to \(PrintTime.durationText(hours: quick.hours, minutes: quick.minutes))")
                }

                Spacer(minLength: 0)

                if hasDuration {
                    Button("Clear") {
                        hours = 0
                        minutes = 0
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Start

    private var startCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Start", systemImage: "play.circle")
                    .font(.headline)

                Spacer()

                Picker("Start", selection: $startMode) {
                    ForEach(StartMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 164)
            }

            if startMode == .now {
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .foregroundStyle(.secondary)

                    Text("Started at \(PrintTime.clockText(for: anchor))")

                    Spacer()

                    Button("Reset to Now") {
                        anchor = .now
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                    .foregroundStyle(Color.accentColor)
                    .help("Treat the print as starting right now")
                }
                .font(.callout)
                .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 8) {
                    Text("Started at")
                        .foregroundStyle(.secondary)

                    DatePicker(
                        "Start time",
                        selection: $customStart,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.field)
                    .labelsHidden()

                    Spacer()
                }
                .font(.callout)
            }
        }
        .cardStyle()
    }

    // MARK: - Result

    private var resultCard: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let now = context.date
            let remaining = finish.timeIntervalSince(now)
            let progress = PrintTime.progress(start: start, finish: finish, now: now)
            let isDone = hasDuration && remaining <= 0

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Finishes at", systemImage: "flag.checkered")
                        .font(.headline)

                    Spacer()

                    if hasDuration {
                        Button {
                            copyFinishTime()
                        } label: {
                            Label(
                                copied ? "Copied" : "Copy",
                                systemImage: copied ? "checkmark" : "doc.on.doc"
                            )
                        }
                        .buttonStyle(.borderless)
                        .font(.callout)
                        .foregroundStyle(Color.accentColor)
                        .keyboardShortcut("c", modifiers: [.command, .shift])
                        .help("Copy the finish date and time")
                    }
                }

                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(hasDuration ? PrintTime.clockText(for: finish) : "--:--")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .opacity(hasDuration ? 1 : 0.35)

                    Spacer(minLength: 0)

                    if isDone {
                        Text("Done")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.green.opacity(0.15)))
                    }
                }

                HStack(spacing: 6) {
                    if hasDuration {
                        Text(PrintTime.dayText(for: finish, relativeTo: now))
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text("\(PrintTime.durationText(hours: hours, minutes: minutes)) print")
                    } else {
                        Text("Enter your print time above to get started.")
                    }
                }
                .font(.callout)
                .foregroundStyle(.secondary)

                if hasDuration {
                    VStack(spacing: 7) {
                        ProgressView(value: progress)
                            .tint(Color.accentColor)

                        HStack {
                            Text(isDone ? "Finished" : PrintTime.countdownText(remaining: remaining))
                            Spacer()
                            Text("\(Int(progress * 100))%")
                                .monospacedDigit()
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(18)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.regularMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.accentColor.opacity(0.16),
                                        Color.accentColor.opacity(0.03)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(Color.accentColor.opacity(0.20))
                    }
            }
        }
    }

    // MARK: - Actions

    private func reanchorIfNeeded() {
        if startMode == .now {
            anchor = .now
        }
    }

    private func copyFinishTime() {
        let text = finish.formatted(
            .dateTime
                .weekday(.wide)
                .month(.wide)
                .day()
                .year()
                .hour()
                .minute()
        )

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        withAnimation(.easeOut(duration: 0.15)) {
            copied = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeOut(duration: 0.2)) {
                copied = false
            }
        }
    }
}

// MARK: - Duration field

private struct DurationField: View {
    let caption: String
    let suffix: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                TextField("0", value: $value, format: .number.grouping(.never))
                    .textFieldStyle(.plain)
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .multilineTextAlignment(.trailing)
                    .frame(width: 86)
                    .focused($isFocused)
                    .accessibilityLabel(caption)

                Text(suffix)
                    .font(.system(size: 21, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .frame(height: 62)
            .background {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(Color.primary.opacity(isFocused ? 0.09 : 0.06))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .strokeBorder(
                        isFocused ? Color.accentColor.opacity(0.75) : Color.primary.opacity(0.08),
                        lineWidth: isFocused ? 1.5 : 1
                    )
            }
            .animation(.easeOut(duration: 0.15), value: isFocused)

            Text(caption)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 5)
        }
        .onChange(of: value) { _, newValue in
            let clamped = min(max(newValue, range.lowerBound), range.upperBound)
            if clamped != newValue {
                value = clamped
            }
        }
    }
}

// MARK: - Card style

private struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                .regularMaterial,
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.07))
            }
    }
}

private extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

#Preview {
    ContentView()
}
