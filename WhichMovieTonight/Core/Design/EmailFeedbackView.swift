//
//  EmailFeedbackView.swift
//  WhichMovieTonight
//
//  Created by AI Assistant on 31/12/2024.
//

import MessageUI
import SwiftUI

struct EmailFeedbackView: View {
    let rating: Int
    let selectedFeedback: String
    let onDismiss: () -> Void

    @State private var showingMailComposer = false
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "envelope.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(DesignSystem.primaryGradient)

                    Text("Send Feedback")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("We'll open your email app with a pre-filled message. You can edit it before sending.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Feedback summary
                VStack(spacing: 16) {
                    HStack {
                        Text("Your Rating:")
                            .fontWeight(.medium)
                        Spacer()
                        HStack(spacing: 4) {
                            ForEach(1 ... 5, id: \.self) { star in
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .foregroundColor(star <= rating ? .yellow : .gray)
                                    .font(.caption)
                            }
                        }
                    }

                    HStack {
                        Text("Feedback Category:")
                            .fontWeight(.medium)
                        Spacer()
                        Text(selectedFeedback)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.mediumRadius))
                .padding(.horizontal)

                Spacer()

                // Action buttons
                VStack(spacing: 12) {
                    Button(action: {
                        if MFMailComposeViewController.canSendMail() {
                            showingMailComposer = true
                        } else {
                            alertMessage = "Email is not available on this device. Please contact us through the App Store."
                            showingAlert = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "envelope.fill")
                            Text("Open Email App")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(DesignSystem.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.mediumRadius))
                    }
                    .padding(.horizontal)

                    Button(action: onDismiss) {
                        Text("Cancel")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .navigationTitle("Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingMailComposer) {
            MailComposeView(
                rating: rating,
                selectedFeedback: selectedFeedback,
                onDismiss: onDismiss
            )
        }
        .alert("Email Not Available", isPresented: $showingAlert) {
            Button("OK") {}
        } message: {
            Text(alertMessage)
        }
    }
}

struct MailComposeView: UIViewControllerRepresentable {
    let rating: Int
    let selectedFeedback: String
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator

        // Email configuration
        composer.setToRecipients(["feedback@moviebuddy.app"]) // Replace with your email
        composer.setSubject("MovieBuddy Feedback - \(rating) Star Rating")

        // Email body
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        let deviceModel = UIDevice.current.model
        let systemVersion = UIDevice.current.systemVersion

        let emailBody = """
        Hi MovieBuddy Team,

        I'm providing feedback about MovieBuddy:

        Rating: \(rating)/5 stars
        Feedback Category: \(selectedFeedback)

        Additional Comments:
        [Please share your detailed feedback here]

        ---
        App Version: \(appVersion) (\(buildNumber))
        Device: \(deviceModel)
        iOS Version: \(systemVersion)
        """

        composer.setMessageBody(emailBody, isHTML: false)

        return composer
    }

    func updateUIViewController(_: MFMailComposeViewController, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let onDismiss: () -> Void

        init(onDismiss: @escaping () -> Void) {
            self.onDismiss = onDismiss
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith _: MFMailComposeResult, error _: Error?) {
            controller.dismiss(animated: true) {
                self.onDismiss()
            }
        }
    }
}

#Preview {
    EmailFeedbackView(
        rating: 3,
        selectedFeedback: "Hard to use",
        onDismiss: {}
    )
}
