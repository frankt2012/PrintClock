import AppKit
import SwiftUI
import TimeCalculatorKit

struct MenuBarView: View {
    @EnvironmentObject private var model: PrintModel
    @Environment(\.openWindow) private var openWindow

    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            durationSection
            resultSection
            Divider()
            footer
        }
        .padding(14)
        .frame(width: 340)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
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
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 26, height: 26)

            Text("Time Calculator")
                .font(.headline)

            Spacer()

            Button {
                NSApp.terminate(nil)
            } label: {
                Image(systemName: "power")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .help("Quit Time Calculator")
        }
    }

    // MARK: - Duration

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("Print time")
                    .font(.subheadline.weight(.medium))

                Spacer()

                Text(
                    model.hasDuration
                        ? PrintTime.durationText(hours: model.hours, minutes: model.minutes)
                        : "From your slicer"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            HStack(alignment: .top, spacing: 8) {
                DurationField(caption: "", suffix: "h", value: $model.hours, range: 0...999, compact: true)
                DurationField(caption: "", suffix: "m", value: $model.minutes, range: 0...59, compact: true)
                Spacer(minLength: 0)
            }

            HStack(spacing: 5) {
                ForEach(QuickDuration.presets) { quick in
                    Button(quick.label) {
                        model.setDuration(hours: quick.hours, minutes: quick.minutes)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .controlSize(.mini)
                    .help("Set the print time to \(PrintTime.durationText(hours: quick.hours, minutes: quick.minutes))")
                }

                Spacer(minLength: 0)

                if model.hasDuration {
                    Button("Clear") {
                        model.setDuration(hours: 0, minutes: 0)
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.mini)
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Result

    private var resultSection: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let now = context.date
            let remaining = model.finish.timeIntervalSince(now)
            let progress = PrintTime.progress(start: model.start, finish: model.finish, now: now)
            let isDone = model.hasDuration && remaining <= 0

            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Finishes at")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    if isDone {
                        Text("Done")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.green)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.green.opacity(0.15)))
                    }
                }

                Text(model.hasDuration ? PrintTime.clockText(for: model.finish) : "--:--")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .opacity(model.hasDuration ? 1 : 0.35)

                if model.hasDuration {
                    HStack(spacing: 5) {
                        Text(PrintTime.dayText(for: model.finish, relativeTo: now))
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text(isDone ? "Finished" : PrintTime.countdownText(remaining: remaining))
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    ProgressView(value: progress)
                        .tint(Color.accentColor)
                } else {
                    Text("Enter a print time to get started.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.regularMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
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
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.accentColor.opacity(0.20))
                    }
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 8) {
            Button {
                copyFinishTime()
            } label: {
                Label(
                    copied ? "Copied" : "Copy Time",
                    systemImage: copied ? "checkmark" : "doc.on.doc"
                )
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(!model.hasDuration)

            Spacer()

            Button {
                openMainWindow()
            } label: {
                Label("Open App", systemImage: "macwindow")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
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

    private func openMainWindow() {
        openWindow(id: "main")

        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

#Preview {
    MenuBarView()
        .environmentObject(PrintModel())
}
