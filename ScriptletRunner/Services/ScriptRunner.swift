import Foundation
import Combine

class ScriptRunner: ObservableObject {
    @Published var isRunning = false
    @Published var output = ""
    @Published var exitCode: Int32?

    private var process: Process?
    private var outputPipe: Pipe?
    private var errorPipe: Pipe?

    func run(script: Script, arguments: [ScriptArgument]) {
        guard !isRunning else { return }

        isRunning = true
        output = ""
        exitCode = nil

        let process = Process()
        self.process = process

        // Determine shell
        process.executableURL = URL(fileURLWithPath: "/bin/bash")

        // Pass environment variables for GUI operations (browser, etc.)
        var env = ProcessInfo.processInfo.environment
        env["HOME"] = NSHomeDirectory()
        env["USER"] = NSUserName()
        env["TERM"] = "xterm-256color"
        process.environment = env

        // Build command with arguments
        var commandArgs = ["-c"]
        var scriptCommand = "\"\(script.path)\""

        // Add flag arguments
        for arg in arguments where arg.isEnabled && !arg.isPositional {
            if let flag = arg.flagForCommand {
                if arg.requiresValue && !arg.value.isEmpty {
                    scriptCommand += " \(flag) \"\(arg.value)\""
                } else if !arg.requiresValue {
                    scriptCommand += " \(flag)"
                }
            }
        }

        // Add positional arguments
        for arg in arguments where arg.isEnabled && arg.isPositional {
            if !arg.value.isEmpty {
                scriptCommand += " \"\(arg.value)\""
            }
        }

        commandArgs.append(scriptCommand)
        process.arguments = commandArgs
        process.currentDirectoryURL = URL(fileURLWithPath: script.directory)

        // Setup pipes
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        self.outputPipe = outputPipe
        self.errorPipe = errorPipe

        process.standardOutput = outputPipe
        process.standardError = errorPipe

        // Handle output
        outputPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if let str = String(data: data, encoding: .utf8), !str.isEmpty {
                DispatchQueue.main.async {
                    self?.output += str
                }
            }
        }

        errorPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if let str = String(data: data, encoding: .utf8), !str.isEmpty {
                DispatchQueue.main.async {
                    self?.output += "[stderr] " + str
                }
            }
        }

        process.terminationHandler = { [weak self] proc in
            DispatchQueue.main.async {
                self?.isRunning = false
                self?.exitCode = proc.terminationStatus
                self?.outputPipe?.fileHandleForReading.readabilityHandler = nil
                self?.errorPipe?.fileHandleForReading.readabilityHandler = nil
            }
        }

        do {
            try process.run()
        } catch {
            output = "Failed to start script: \(error.localizedDescription)"
            isRunning = false
        }
    }

    func stop() {
        process?.terminate()
    }

    func clear() {
        output = ""
        exitCode = nil
    }
}
