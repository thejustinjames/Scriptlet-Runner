# Scriptlet Runner

**Run all your scripts from a single place.**

A native SwiftUI macOS app for managing and running shell scripts with a GUI.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5-orange)
![License](https://img.shields.io/badge/license-Non--Commercial-green)

## Author

**Justin James**
- GitHub: [@thejustinjames](https://github.com/thejustinjames)

## Support This Project

If you find Scriptlet Runner useful, please consider supporting its development:

[![Sponsor](https://img.shields.io/badge/Sponsor-GitHub-ea4aaa?logo=github)](https://github.com/sponsors/thejustinjames)

## Features

- **Script Scanner** - Scan folders for .sh scripts recursively
- **Script List View** - Display scripts with name, description, and search
- **Argument Parser** - Extracts usage/options from script header comments
- **Script Runner** - Execute scripts with selected arguments
- **Output Console** - Live output with copy/stop support
- **Script Chains** - Create sequences of scripts to run in order
- **Settings** - Manage scan locations with appearance options
- **Light/Dark/System modes** - Full theme support

## Installation

### Download

Download the latest DMG from the [Releases](https://github.com/thejustinjames/scriptletRunner/releases) page.

### Build from Source

```bash
git clone https://github.com/thejustinjames/scriptletRunner.git
cd scriptletRunner
./build.sh
```

The built app and DMG will be in the `dist/` folder.

## Quick Start

1. Open Scriptlet Runner
2. Click the gear icon to open Settings
3. Add folders containing your shell scripts
4. Browse and select scripts from the sidebar
5. Configure any arguments and click "Run Script"

## Script Comment Format

Scriptlet Runner parses your script headers to extract metadata. Use this format:

```bash
#!/bin/bash
# Description: Brief description of what this script does
#
# Usage: script.sh [OPTIONS] <arguments>
#
# Options:
#   -h, --help      Show this help message
#   -v, --verbose   Enable verbose output
#   -f, --file FILE Input file path
#
# Arguments:
#   input           The input file to process
#   output          The output destination
```

## Script Chains

Create sequences of scripts that run in order:

1. Switch to the "Chains" tab in the sidebar
2. Click "New Chain"
3. Add scripts to the chain
4. Configure arguments for each step
5. Optionally enable "Continue on error" for steps that shouldn't stop the chain
6. Save and run your chain

## Requirements

- macOS 13.0+
- Xcode 15.0+ (for building from source)

## Documentation

- [Help Guide](HELP.md) - Detailed usage instructions
- [Developer's Guide](DEVELOPERS.md) - Contributing and development

## License

This software is **free for non-commercial use**. Commercial use requires a license.

See [LICENSE](LICENSE) for full details.

## Contributing

Contributions are welcome! Please read the [Developer's Guide](DEVELOPERS.md) first.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Acknowledgments

- Built with SwiftUI for macOS
- Golden pig icon designed for Scriptlet Runner
