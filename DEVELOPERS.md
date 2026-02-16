# Scriptlet Runner - Developer's Guide

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Project Structure](#project-structure)
3. [Building](#building)
4. [Code Style](#code-style)
5. [Adding Features](#adding-features)
6. [Testing](#testing)
7. [Contributing](#contributing)

---

## Architecture Overview

Scriptlet Runner is a native macOS app built with:

- **SwiftUI** for the user interface
- **Swift 5** for all logic
- **AppStorage** for persistence
- **Combine** for reactive updates

### Design Patterns

- **MVVM-ish**: Views observe `@StateObject` services
- **Service Layer**: Dedicated classes for scanning, parsing, and running
- **Model Layer**: Simple structs with Codable conformance

---

## Project Structure

```
scriptletRunner/
├── ScriptletRunner.xcodeproj/    # Xcode project
├── ScriptletRunner/
│   ├── App/
│   │   └── ScriptletRunnerApp.swift    # App entry point
│   ├── Models/
│   │   ├── Script.swift                # Script model
│   │   ├── ScriptArgument.swift        # Argument model
│   │   ├── ScanLocation.swift          # Scan location model
│   │   └── ScriptChain.swift           # Chain model
│   ├── Views/
│   │   ├── ContentView.swift           # Main view
│   │   ├── ScriptListView.swift        # Script sidebar
│   │   ├── ScriptDetailView.swift      # Script details
│   │   ├── ConsoleView.swift           # Output console
│   │   ├── SettingsView.swift          # Settings panel
│   │   ├── AboutView.swift             # About dialog
│   │   ├── HelpView.swift              # Help dialog
│   │   ├── ChainListView.swift         # Chain sidebar
│   │   ├── ChainEditorView.swift       # Chain editor
│   │   └── ChainDetailView.swift       # Chain details
│   ├── Services/
│   │   ├── ScriptScanner.swift         # File scanner
│   │   ├── ScriptParser.swift          # Comment parser
│   │   ├── ScriptRunner.swift          # Script executor
│   │   └── ChainRunner.swift           # Chain executor
│   └── Assets.xcassets/                # Images and icons
├── dist/                               # Build output
├── build.sh                            # Build script
├── generate_icon.swift                 # Icon generator
├── README.md
├── HELP.md
├── DEVELOPERS.md
├── LICENSE
└── .gitignore
```

---

## Building

### Prerequisites

- macOS 13.0+
- Xcode 15.0+
- Command Line Tools (`xcode-select --install`)

### Quick Build

```bash
./build.sh
```

This creates:
- `dist/Scriptlet Runner.app` - The application
- `dist/ScriptletRunner-1.0.0.dmg` - Installer package

### Manual Build

```bash
xcodebuild -project ScriptletRunner.xcodeproj \
    -scheme ScriptletRunner \
    -configuration Release \
    -derivedDataPath build
```

### Debug Build

Open `ScriptletRunner.xcodeproj` in Xcode and run with ⌘R.

---

## Code Style

### Swift Guidelines

- Use Swift 5 features
- Prefer `let` over `var`
- Use descriptive names
- Keep functions short and focused
- Use extensions for organization

### SwiftUI Guidelines

- Extract reusable views to separate structs
- Use `@StateObject` for owned objects
- Use `@ObservedObject` for passed objects
- Prefer `@Binding` for two-way data flow

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Views | PascalCase + View | `ScriptDetailView` |
| Models | PascalCase | `ScriptChain` |
| Services | PascalCase | `ScriptRunner` |
| Properties | camelCase | `selectedScript` |
| Functions | camelCase | `runSelectedScript()` |

---

## Adding Features

### Adding a New View

1. Create file in `ScriptletRunner/Views/`
2. Define struct conforming to `View`
3. Add to project in Xcode
4. Update `project.pbxproj` if editing manually

Example:
```swift
import SwiftUI

struct MyNewView: View {
    var body: some View {
        Text("Hello")
    }
}
```

### Adding a New Model

1. Create file in `ScriptletRunner/Models/`
2. Conform to `Identifiable`, `Codable`, `Hashable`
3. Add to project

Example:
```swift
import Foundation

struct MyModel: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}
```

### Adding a New Service

1. Create file in `ScriptletRunner/Services/`
2. Make it `ObservableObject` if UI needs updates
3. Use `@Published` for reactive properties

Example:
```swift
import Foundation
import Combine

class MyService: ObservableObject {
    @Published var result: String = ""

    func doWork() {
        // Implementation
        result = "Done"
    }
}
```

---

## Key Components

### ScriptParser

Parses script header comments to extract:
- Description (first comment or `# Description:`)
- Usage (`# Usage:`)
- Options (`# Options:` block)
- Arguments (`# Arguments:` block)

**Key method:** `parse(scriptPath:) -> Script`

### ScriptScanner

Scans directories for shell scripts:
- Checks `.sh` extension
- Validates shebang for executables
- Supports recursive scanning

**Key method:** `scan(locations:) -> [Script]`

### ScriptRunner

Executes scripts with arguments:
- Uses `Process` for execution
- Captures stdout and stderr
- Provides real-time output via `@Published`

**Key methods:**
- `run(script:arguments:)`
- `stop()`
- `clear()`

### ChainRunner

Executes script chains sequentially:
- Runs steps in order
- Handles "continue on error" option
- Tracks per-step status

**Key methods:**
- `run(chain:scripts:)`
- `stop()`

---

## Testing

### Manual Testing

1. Build and run the app
2. Add test scripts with various comment formats
3. Test all features:
   - Script discovery
   - Argument parsing
   - Script execution
   - Chain creation and execution
   - Settings persistence

### Test Scripts

Create test scripts with different formats:

```bash
#!/bin/bash
# Description: Test script with all features
#
# Usage: test.sh [OPTIONS] <file>
#
# Options:
#   -v, --verbose   Enable verbose output
#   -o, --output    Output file
#
# Arguments:
#   file            Input file

echo "Running with args: $@"
```

---

## Contributing

### Getting Started

1. Fork the repository
2. Clone your fork
3. Create a feature branch
4. Make changes
5. Test thoroughly
6. Submit a pull request

### Pull Request Guidelines

- Keep PRs focused on a single feature/fix
- Update documentation if needed
- Follow existing code style
- Test on macOS 13.0+ if possible

### Branch Strategy

- `main` - Protected, release-ready code
- `develop` - Integration branch (if used)
- `feature/*` - Feature branches
- `fix/*` - Bug fix branches

### Commit Messages

Use clear, descriptive commit messages:

```
Add script chain feature

- Add ScriptChain model
- Add ChainRunner service
- Add chain management views
- Update ContentView with chain support
```

---

## Release Process

1. Update version in `project.pbxproj`
2. Update `MARKETING_VERSION` in both Debug and Release configs
3. Update version in `AboutView.swift`
4. Run `./build.sh`
5. Test the DMG
6. Create GitHub release with DMG attachment
7. Tag the release

---

## Support

- **Issues**: [GitHub Issues](https://github.com/thejustinjames/scriptletRunner/issues)
- **Discussions**: [GitHub Discussions](https://github.com/thejustinjames/scriptletRunner/discussions)
- **Sponsor**: [GitHub Sponsors](https://github.com/sponsors/thejustinjames)
