import SwiftUI

struct SetupWizardView: View {
    @State private var installing = false
    @State private var installComplete = false
    @State private var errorOccurred = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Welcome to Evdetix")
                .font(.largeTitle)
                .bold()

            Text("To get started, the app will register the Mistral model locally. This enables offline AI summarization of ticket conversations — no internet required.")
                .multilineTextAlignment(.leading)
                .frame(maxWidth: 480)

            if installing {
                ProgressView("Installing model...")
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(width: 300)
            } else if installComplete {
                Text("Installation Complete!")
                    .font(.headline)
                    .foregroundColor(.green)
                Button("Next") {
                    NSApp.keyWindow?.close()
                }
                .keyboardShortcut(.defaultAction)
            } else {
                Button("Begin Setup") {
                    installing = true

                    Task {
                        let modelExists = Bundle.main.url(
                            forResource: "mistral",
                            withExtension: nil
                        ) != nil

                        installing = false
                        installComplete = modelExists
                        errorOccurred = !modelExists

                        if installComplete {
                            UserDefaults.standard.set(true, forKey: "OllamaInstalled")

                            if let path = Bundle.main.path(
                                forResource: "run_ollama",
                                ofType: "rb"
                            ) {
                                print("Ruby launcher script found at: \(path)")
                            } else {
                                print("Ruby launcher script not found in Resources folder.")
                            }

                            ensureOllamaIsRunning()

                            let ready = await waitUntilOllamaIsReady()
                            if ready {
                                print("Ollama daemon confirmed running.")
                            } else {
                                print("Timed out waiting for Ollama to launch.")
                            }

                            NSApp.keyWindow?.close()
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
            }

            if errorOccurred {
                Text("Installation failed. Please contact IT support or reinstall.")
                    .foregroundColor(.red)
            }

            Spacer()
        }
        .padding()
        .frame(minWidth: 500, minHeight: 320)
    }
}
