import SwiftUI

struct CredentialsPromptView: View {
    @Binding var isPresented: Bool
    @State private var apiKey: String = FreshdeskAPI.apiKey
    @State private var domain: String = FreshdeskAPI.domain

    var body: some View {
        VStack(spacing: 16) {
            Text("Enter Freshdesk Credentials")
                .font(.headline)

            SecureField("API Key", text: $apiKey)
                .textFieldStyle(.roundedBorder)
                .frame(width: 300)

            TextField("Domain (e.g., https://yourorg.freshdesk.com)", text: $domain)
                .textFieldStyle(.roundedBorder)
                .frame(width: 300)

            HStack {
                Spacer()
            Button("Save") {
                let trimmedApiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedDomain = domain.trimmingCharacters(in: .whitespacesAndNewlines)
                FreshdeskAPI.saveCredentials(apiKey: trimmedApiKey, domain: trimmedDomain)
                
                isPresented = false
            }
            .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                      domain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                

        }
        .frame(width: 300)
    }
    .padding()
    .frame(width: 400, height: 200)
    }
}
