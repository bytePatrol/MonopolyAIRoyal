import SwiftUI

struct InterviewsSection: View {
    let interviews: [AIInterview]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("POST-GAME INTERVIEWS")
                    .font(.system(size: 16, weight: .black, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.9))
                Text("THE AIs REACT TO THE RESULT")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
            }

            HStack(spacing: 14) {
                ForEach(interviews) { interview in
                    InterviewCard(interview: interview)
                }
            }
        }
    }
}

// MARK: - Interview Card

struct InterviewCard: View {
    let interview: AIInterview

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(interview.playerName)
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundStyle(Color(hex: interview.colorHex))
                    Text(interview.role)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.45))
                }
                Spacer()
                // Avatar circle
                ZStack {
                    Circle()
                        .fill(Color(hex: interview.colorHex).opacity(0.15))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(Color(hex: interview.colorHex).opacity(0.4), lineWidth: 1)
                        )
                    Text(String(interview.playerName.prefix(2)))
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundStyle(Color(hex: interview.colorHex))
                }
            }

            Divider().background(Color.white.opacity(0.06))

            // Quote
            VStack(alignment: .leading, spacing: 8) {
                Text("\"")
                    .font(.system(size: 36, weight: .black))
                    .foregroundStyle(Color(hex: interview.colorHex).opacity(0.3))
                    .offset(y: 8)
                    .padding(.bottom, -20)

                Text(interview.quote)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.75))
                    .lineSpacing(3)
                    .padding(.horizontal, 8)

                Text("\"")
                    .font(.system(size: 36, weight: .black))
                    .foregroundStyle(Color(hex: interview.colorHex).opacity(0.3))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .offset(y: -8)
                    .padding(.top, -16)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: interview.colorHex).opacity(0.04))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: interview.colorHex).opacity(0.2), lineWidth: 1)
        )
    }
}
