import Foundation

func waitUntilOllamaIsReady(timeout: TimeInterval = 30.0) async -> Bool {
    let start = Date()
    let url = URL(string: "http://127.0.0.1:11434")!

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.timeoutInterval = timeout

    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = timeout
    let session = URLSession(configuration: config)

    while Date().timeIntervalSince(start) < timeout {
        do {
            let (_, response) = try await session.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                print("Ollama is ready.")
                return true
            }
        } catch {
            let elapsed = Int(Date().timeIntervalSince(start))
            print("Waiting for Ollama... (\(elapsed)s elapsed)")
        }

        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
    }

    print("Ollama did not become ready in time.")
    return false
}
