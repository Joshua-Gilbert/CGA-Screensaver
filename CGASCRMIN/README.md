# CGASCRMIN - Ultra-Minimal CGA Screensaver

A tiny memory-resident screensaver for CGA graphics systems. Optimized for minimal memory usage while providing smooth color animation.

## Features

- **Ultra-Small**: Only 593 bytes executable, ~2KB resident memory
- **30-Second Timeout**: Activates after 30 seconds of keyboard inactivity
- **Color Animation**: Smooth cycling through cyan, magenta, and white
- **Instant Response**: Immediate deactivation on any keypress
- **Stable Operation**: Proper COM file structure with minimal interrupt handlers

## System Requirements

- IBM PC or compatible with 80286 processor
- CGA (Color Graphics Adapter) or compatible
- DOS 3.0 or higher
- 2KB available memory

## Installation

```
C:\> CGASCRMIN.com
CGA Screensaver
Installed (30 sec)
```

## Usage

- **Activation**: Screensaver starts automatically after 30 seconds of keyboard inactivity
- **Animation**: Displays color-cycling patterns in CGA 320x200 4-color mode
- **Deactivation**: Press any key to return to normal operation
- **Uninstall**: Reboot system to remove

## Technical Details

- **Graphics Mode**: CGA mode 4 (320x200, 4 colors)
- **Animation Rate**: ~1 second per color change
- **Color Sequence**: Cyan → Magenta → White → Repeat
- **Interrupt Usage**: INT 1Ch (timer) and INT 09h (keyboard)
- **Memory Layout**: Proper COM file with ORG 100h directive

## Architecture

Built for maximum compatibility and minimal resource usage:
- Optimized interrupt handlers avoid complex operations
- Direct CGA memory access for smooth animation
- Flag-based state management prevents conflicts
- Proper interrupt chaining maintains system stability

---

*Assembled with OpenWatcom for 80286 CPU and CGA graphics*