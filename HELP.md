# Scriptlet Runner Help Guide

## Table of Contents

1. [Getting Started](#getting-started)
2. [Adding Scripts](#adding-scripts)
3. [Running Scripts](#running-scripts)
4. [Script Chains](#script-chains)
5. [Settings](#settings)
6. [Script Comment Format](#script-comment-format)
7. [Keyboard Shortcuts](#keyboard-shortcuts)
8. [Troubleshooting](#troubleshooting)
9. [FAQ](#faq)

---

## Getting Started

### First Launch

When you first open Scriptlet Runner, you'll see an empty script list. To get started:

1. Click the **gear icon** in the toolbar to open Settings
2. In the **Locations** tab, click **Add Folder**
3. Select a folder containing your shell scripts
4. Close Settings - your scripts will appear in the sidebar

### Interface Overview

The app has three main areas:

- **Sidebar** (left): Lists all discovered scripts or chains
- **Detail View** (right top): Shows script details and arguments
- **Console** (right bottom): Displays script output

---

## Adding Scripts

### Setting Up Scan Locations

1. Open **Settings** (gear icon or ⌘,)
2. Go to the **Locations** tab
3. Click **Add Folder** to add directories
4. Toggle **Recursive** to include subdirectories
5. Disable locations you want to temporarily exclude

### Supported Script Types

Scriptlet Runner recognizes:
- Files with `.sh` extension
- Executable files with shell shebangs:
  - `#!/bin/bash`
  - `#!/bin/sh`
  - `#!/usr/bin/env bash`
  - `#!/usr/bin/env sh`
  - `#!/bin/zsh`
  - `#!/usr/bin/env zsh`

### Refreshing Scripts

Click the **refresh icon** in the toolbar (or press ⌘R) to rescan all locations.

---

## Running Scripts

### Basic Execution

1. Select a script from the sidebar
2. Review the script details (description, usage)
3. Configure any arguments using the checkboxes
4. Enter values for arguments that require input
5. Click **Run Script**

### Managing Output

- Output appears in real-time in the console
- **Stop** button terminates a running script
- **Clear** button (trash icon) clears console output
- **Copy** button copies all output to clipboard

### Exit Codes

After execution, the console shows:
- **Exit: 0** (green) - Script succeeded
- **Exit: X** (red) - Script failed with error code X

---

## Script Chains

### What Are Chains?

Chains let you run multiple scripts in sequence. Each step can have its own arguments, and you can control what happens if a step fails.

### Creating a Chain

1. Switch to **Chains** in the sidebar picker
2. Click **New Chain**
3. Enter a name and optional description
4. Click **Add Script** to add steps
5. Configure each step's arguments
6. Click **Save**

### Chain Options

For each step, you can:
- **Enable/Disable arguments**: Configure which flags to pass
- **Set argument values**: Enter values for arguments that require input
- **Continue on error**: If enabled, the chain continues even if this step fails

### Running a Chain

1. Select a chain from the sidebar
2. Review the steps
3. Click **Run Chain**
4. Watch the progress as each step executes

---

## Settings

### Locations Tab

| Setting | Description |
|---------|-------------|
| Add Folder | Browse for directories containing scripts |
| Remove | Delete selected location |
| Enable/Disable | Toggle scanning for specific locations |
| Recursive | Include subdirectories when scanning |

### Appearance Tab

Choose your theme:
- **System**: Follows macOS appearance
- **Light**: Always use light mode
- **Dark**: Always use dark mode

---

## Script Comment Format

Scriptlet Runner parses comment blocks at the top of your scripts to extract metadata.

### Basic Format

```bash
#!/bin/bash
# Description: What this script does
#
# Usage: script.sh [OPTIONS] <arguments>
#
# Options:
#   -h, --help      Show this help message
#   -v, --verbose   Enable verbose output
#   -f, --file FILE Specify input file
#
# Arguments:
#   input           Input file path
#   output          Output destination
```

### Supported Patterns

**Options (flags):**
- `-h, --help      Description` - Short and long form
- `--verbose       Description` - Long form only
- `-f FILE         Description` - With value placeholder
- `--output=FILE   Description` - With value (= style)

**Positional Arguments:**
- `input           Description` - Named argument
- `<output>        Description` - Bracketed argument

---

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘, | Open Settings |
| ⌘R | Refresh Scripts |
| ⌘? | Open Help |
| Esc | Close dialogs |

---

## Troubleshooting

### Scripts Not Appearing

1. Check that the folder is added in Settings
2. Verify the folder exists (look for warning icon)
3. Ensure "Recursive" is enabled if scripts are in subfolders
4. Click refresh (⌘R)
5. Check that scripts have `.sh` extension or proper shebang

### Scripts Won't Run

1. Ensure the script is executable: `chmod +x script.sh`
2. Check for syntax errors in the script
3. Verify any required dependencies are installed

### Arguments Not Detected

1. Follow the [comment format](#script-comment-format) exactly
2. Ensure there's whitespace between flags and descriptions
3. Use `#` at the start of each line

### Permission Denied

The script may not be executable. Run in terminal:
```bash
chmod +x /path/to/your/script.sh
```

---

## FAQ

### Can I run scripts from any location?

Yes, add any folder in Settings. The app will scan and list all valid scripts.

### Are my settings saved?

Yes, settings persist between sessions. Scan locations, appearance preferences, and saved chains are all stored.

### Can I edit scripts from the app?

Currently, Scriptlet Runner is for running scripts, not editing. Use your preferred text editor to modify scripts.

### What happens if a script hangs?

Click the **Stop** button to terminate the running script.

### Can I run the same script with different arguments?

Yes! Change the arguments and run again. For repeated runs with specific configurations, create a chain with one step.

### Is there a limit to chain length?

No technical limit. Chains can have as many steps as needed.

---

## Getting Help

- Visit [GitHub Issues](https://github.com/thejustinjames/scriptletRunner/issues) to report bugs
- Check the [Developer's Guide](DEVELOPERS.md) for technical details
- Support the project at [GitHub Sponsors](https://github.com/sponsors/thejustinjames)
