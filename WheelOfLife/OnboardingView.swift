import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var store: WheelStore
    @State private var step = 0
    @State private var selectedTemplate: WheelTemplate = .fullSpectrum
    @State private var previewReveal = false

    var body: some View {
        ZStack {
            AtmosphereBackground()

            VStack(spacing: 0) {
                TabView(selection: $step) {
                    welcomePage.tag(0)
                    howItWorksPage.tag(1)
                    templatePage.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .animation(.easeInOut, value: step)

                bottomBar
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
                    .padding(.top, 8)
            }
        }
    }

    private var welcomePage: some View {
        VStack(spacing: 28) {
            Spacer()

            WheelChartView(
                areas: LifeArea.fullSpectrum,
                animated: true,
                interactive: false,
                showCapsules: true
            )
            .frame(height: 300)
            .scaleEffect(previewReveal ? 1 : 0.86)
            .opacity(previewReveal ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.9, dampingFraction: 0.78)) {
                    previewReveal = true
                }
            }

            VStack(spacing: 10) {
                Text("See your life\nat a glance")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.ink)

                Text("Rate each area from 0–10. A smooth wheel rolls easy — a bumpy one shows where to focus.")
                    .font(.body)
                    .foregroundStyle(AppTheme.mutedInk)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var howItWorksPage: some View {
        VStack(alignment: .leading, spacing: 22) {
            Spacer()

            Text("How it works")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            featureRow(
                icon: "hand.draw.fill",
                color: Color(hex: "#E91E8C"),
                title: "Drag to rate",
                subtitle: "Pull any segment from the center to set your score with haptics."
            )
            featureRow(
                icon: "sparkle.magnifyingglass",
                color: Color(hex: "#1E88E5"),
                title: "Spot the gaps",
                subtitle: "Focus and strength insights update live as your wheel changes."
            )
            featureRow(
                icon: "clock.arrow.circlepath",
                color: Color(hex: "#43A047"),
                title: "Track over time",
                subtitle: "Save snapshots and see whether your balance is improving."
            )

            Spacer()
        }
        .padding(.horizontal, 28)
    }

    private var templatePage: some View {
        VStack(alignment: .leading, spacing: 18) {
            Spacer(minLength: 20)

            Text("Choose your wheel")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            Text("You can switch templates anytime in Settings.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.mutedInk)

            ForEach(WheelTemplate.allCases) { template in
                Button {
                    withAnimation(.spring(response: 0.35)) {
                        selectedTemplate = template
                    }
                    UISelectionFeedbackGenerator().selectionChanged()
                } label: {
                    HStack(spacing: 14) {
                        WheelChartView(
                            areas: template.areas,
                            animated: false,
                            interactive: false,
                            showCapsules: false
                        )
                        .frame(width: 72, height: 72)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(template.rawValue)
                                .font(.system(.headline, design: .rounded))
                                .foregroundStyle(AppTheme.ink)
                            Text(template.subtitle)
                                .font(.caption)
                                .foregroundStyle(AppTheme.mutedInk)
                                .multilineTextAlignment(.leading)
                        }

                        Spacer()

                        Image(systemName: selectedTemplate == template ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundStyle(selectedTemplate == template ? Color(hex: "#E91E8C") : AppTheme.mutedInk.opacity(0.4))
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(AppTheme.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(
                                        selectedTemplate == template ? Color(hex: "#E91E8C").opacity(0.5) : .clear,
                                        lineWidth: 2
                                    )
                            )
                            .shadow(color: .black.opacity(0.04), radius: 10, y: 4)
                    )
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var bottomBar: some View {
        HStack {
            if step > 0 {
                Button("Back") {
                    withAnimation { step -= 1 }
                }
                .font(.headline)
                .foregroundStyle(AppTheme.mutedInk)
            }

            Spacer()

            Button {
                if step < 2 {
                    withAnimation { step += 1 }
                } else {
                    store.completeOnboarding(with: selectedTemplate)
                }
            } label: {
                Text(step < 2 ? "Continue" : "Start my wheel")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#E91E8C"), Color(hex: "#8E24AA")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private func featureRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(RoundedRectangle(cornerRadius: 12).fill(color))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.mutedInk)
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(WheelStore())
}
