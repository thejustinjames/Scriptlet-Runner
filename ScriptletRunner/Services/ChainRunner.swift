import Foundation
import Combine

enum ChainStepStatus {
    case pending
    case running
    case completed(exitCode: Int32)
    case failed(error: String)
    case skipped
}

class ChainRunner: ObservableObject {
    @Published var isRunning = false
    @Published var currentStepIndex: Int = 0
    @Published var stepStatuses: [UUID: ChainStepStatus] = [:]
    @Published var output = ""
    @Published var overallSuccess = true

    private var process: Process?
    private var shouldStop = false

    func run(chain: ScriptChain, scripts: [Script]) {
        guard !isRunning else { return }

        isRunning = true
        shouldStop = false
        currentStepIndex = 0
        stepStatuses = [:]
        output = ""
        overallSuccess = true

        // Initialize all steps as pending
        for step in chain.steps {
            stepStatuses[step.id] = .pending
        }

        output += "=== Starting Chain: \(chain.name) ===\n"
        output += "Total steps: \(chain.steps.count)\n\n"

        runNextStep(chain: chain, scripts: scripts, stepIndex: 0)
    }

    private func runNextStep(chain: ScriptChain, scripts: [Script], stepIndex: Int) {
        guard stepIndex < chain.steps.count else {
            // All steps completed
            DispatchQueue.main.async {
                self.output += "\n=== Chain Completed ===\n"
                self.output += self.overallSuccess ? "All steps succeeded!\n" : "Some steps failed.\n"
                self.isRunning = false
            }
            return
        }

        guard !shouldStop else {
            DispatchQueue.main.async {
                self.output += "\n=== Chain Stopped by User ===\n"
                self.isRunning = false
            }
            return
        }

        let step = chain.steps[stepIndex]

        DispatchQueue.main.async {
            self.currentStepIndex = stepIndex
            self.stepStatuses[step.id] = .running
            self.output += "--- Step \(stepIndex + 1): \(step.scriptName) ---\n"
        }

        // Find the script
        guard let script = scripts.first(where: { $0.path == step.scriptPath }) else {
            DispatchQueue.main.async {
                self.stepStatuses[step.id] = .failed(error: "Script not found")
                self.output += "ERROR: Script not found at \(step.scriptPath)\n\n"
                self.overallSuccess = false

                if step.continueOnError {
                    self.runNextStep(chain: chain, scripts: scripts, stepIndex: stepIndex + 1)
                } else {
                    self.output += "=== Chain Stopped Due to Error ===\n"
                    self.isRunning = false
                }
            }
            return
        }

        // Build arguments
        var arguments: [ScriptArgument] = []
        for var arg in script.arguments {
            if step.enabledFlags.contains(arg.id.uuidString) {
                arg.isEnabled = true
                if let value = step.arguments[arg.id.uuidString] {
                    arg.value = value
                }
            }
            arguments.append(arg)
        }

        // Run the script
        runScript(script: script, arguments: arguments) { [weak self] success, exitCode in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if success {
                    self.stepStatuses[step.id] = .completed(exitCode: exitCode)
                    self.output += "Step completed with exit code: \(exitCode)\n\n"
                } else {
                    self.stepStatuses[step.id] = .failed(error: "Exit code: \(exitCode)")
                    self.output += "Step failed with exit code: \(exitCode)\n\n"
                    self.overallSuccess = false
                }

                if !success && !step.continueOnError {
                    self.output += "=== Chain Stopped Due to Error ===\n"
                    self.isRunning = false
                } else {
                    self.runNextStep(chain: chain, scripts: scripts, stepIndex: stepIndex + 1)
                }
            }
        }
    }

    private func runScript(script: Script, arguments: [ScriptArgument], completion: @escaping (Bool, Int32) -> Void) {
        let process = Process()
        self.process = process

        process.executableURL = URL(fileURLWithPath: "/bin/bash")

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

        process.arguments = ["-c", scriptCommand]
        process.currentDirectoryURL = URL(fileURLWithPath: script.directory)

        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.standardOutput = outputPipe
        process.standardError = errorPipe

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

        process.terminationHandler = { proc in
            outputPipe.fileHandleForReading.readabilityHandler = nil
            errorPipe.fileHandleForReading.readabilityHandler = nil
            completion(proc.terminationStatus == 0, proc.terminationStatus)
        }

        do {
            try process.run()
        } catch {
            DispatchQueue.main.async {
                self.output += "Failed to start script: \(error.localizedDescription)\n"
            }
            completion(false, -1)
        }
    }

    func stop() {
        shouldStop = true
        process?.terminate()
    }

    func clear() {
        output = ""
        stepStatuses = [:]
        currentStepIndex = 0
        overallSuccess = true
    }
}
