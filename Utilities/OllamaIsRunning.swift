import Foundation

var ollamaProcess: Process?

func ensureOllamaIsRunning() {

    guard let healthCheckURL = URL(string: "http://127.0.0.1:11434") else {
        print("Invalid Ollama health check URL.")
        return
    }

    var request = URLRequest(url: healthCheckURL)
    request.httpMethod = "GET"

    URLSession.shared.dataTask(with: request) { _, response, _ in
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {

            print("Ollama is already running.")
            return
        }

        launchOllamaViaRuby()
    }.resume()
}

private func launchOllamaViaRuby() {

    guard let rubyScriptURL = Bundle.main.url(
        forResource: "run_ollama",
        withExtension: "rb"
    ) else {
        print("Ruby launcher script not found in Resources folder.")
        return
    }

    print("Launching Ollama via Ruby script at: \(rubyScriptURL.path)")

    let task = Process()
    task.launchPath = "/usr/bin/env"
    task.arguments = ["ruby", rubyScriptURL.path]
    
    task.currentDirectoryPath = rubyScriptURL.deletingLastPathComponent().path

    let outputPipe = Pipe()
    task.standardOutput = outputPipe
    task.standardError = outputPipe

    task.terminationHandler = { process in
        print("Ollama (via Ruby) exited with code \(process.terminationStatus)")
    }

    do {
        try task.run()
        ollamaProcess = task
        print("Ollama process launched via Ruby script.")

        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if let output = String(data: data, encoding: .utf8),
               !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                print("Ollama output: \(output)")
            }
        }
    } catch {
        print("Failed to launch Ollama via Ruby: \(error)")
    }
}
