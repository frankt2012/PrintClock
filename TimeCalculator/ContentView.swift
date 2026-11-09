import SwiftUI
import TimeCalculatorKit

struct ContentView: View {
    @EnvironmentObject private var model: PrintModel
    @State private var copied = false

    private var start: Date {
        model.start
    }

    private var hasDuration: Bool {
        model.hasDuration
    }

    private var finish: Date {
        model.finish
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

                Text(
                    hasDuration
                        ? PrintTime.durationText(hours: model.hours, minutes: model.minutes)
                        : "From your slicer"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            HStack(alignment: .top, spacing: 12) {
                DurationField(caption: "Hours", suffix: "h", value: $model.hours, range: 0...999)
                DurationField(caption: "Minutes", suffix: "m", value: $model.minutes, range: 0...59)
                Spacer(minLength: 0)
            }

            HStack(spacing: 6) {
                Text("Quick")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(QuickDuration.presets) { quick in
                    Button(quick.label) {
                        model.setDuration(hours: quick.hours, minutes: quick.minutes)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .controlSize(.small)
                    .help("Set the print time to \(PrintTime.durationText(hours: quick.hours, minutes: quick.minutes))")
                }

                Spacer(minLength: 0)

                if hasDuration {
                    Button("Clear") {
                        model.setDuration(hours: 0, minutes: 0)
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

                Picker("Start", selection: $model.startMode) {
                    ForEach(StartMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 164)
            }

            if model.startMode == .now {
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .foregroundStyle(.secondary)

                    Text("Started at \(PrintTime.clockText(for: model.anchor))")

                    Spacer()

                    Button("Reset to Now") {
                        model.resetToNow()
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
                        selection: $model.customStart,
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
                        Text("\(PrintTime.durationText(hours: model.hours, minutes: model.minutes)) print")
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

    private func copyFinishTime() {
        model.copyFinishTime()

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
        .environmentObject(PrintModel())
}
