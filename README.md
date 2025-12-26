# Clipman Pro

A powerful and elegant clipboard manager for macOS that enhances your productivity by keeping track of multiple copied items and providing quick access through the menu bar.

![Screenshot Placeholder](https://raw.githubusercontent.com/Angryman18/Clipman-Pro/main/screenshots/clipman.png)

## Features

### 🗂️ **Multi-Item Clipboard History**

- Automatically stores your recently copied text items
- Configurable maximum items (25-300)
- Persistent storage across app restarts
- Smart duplicate detection

### 📌 **Pin Important Items**

- Pin frequently used items to keep them at the top
- Pinned items stay visible even when new items are added
- Easy toggle pin/unpin with a single click

### ⚡ **Quick Access**

- Always available in your menu bar
- Click any item to instantly copy it back to clipboard
- Smooth hover effects and intuitive interface

### 🎛️ **Customizable Settings**

- Adjust maximum clipboard items through the settings window
- Option to auto-move copied items to the top
- Confirmation dialogs for destructive actions

### 🗑️ **Smart Management**

- Delete individual items or clear all at once
- Confirmation prompts for pinned item deletion
- Automatic cleanup when reducing maximum items

## How It Works

1. **Automatic Monitoring**: Clipman Pro runs quietly in the background, monitoring your clipboard for new content every 0.5 seconds.

2. **Smart Storage**: When you copy text, it automatically gets added to your clipboard history, removing duplicates and maintaining the most recent items.

3. **Menu Bar Access**: Click the clipboard icon in your menu bar to see all your copied items in a clean, organized list.

4. **Pin & Organize**: Pin important items to keep them easily accessible at the top of your list.

5. **Settings**: Open the app window to customize the maximum number of items and other preferences.

## Installation

### From Source

1. Clone this repository
2. Open `Clipman Pro.xcodeproj` in Xcode
3. Build and run the project
4. The app will appear in your menu bar automatically

### Requirements

- macOS 12.0 or later
- Xcode 13.0 or later (for building from source)

## Usage

### Basic Workflow

1. Copy text as you normally would (⌘C)
2. Click the clipboard icon in your menu bar
3. Click on any item to copy it back to your clipboard
4. Use the pin button to keep important items at the top

### Settings

- **Max Items**: Set the maximum number of clipboard items to store (25-300)
- **Auto Move to Top**: When enabled, copied items automatically move to the top of the list

### Menu Options

- **Clear All**: Remove all clipboard items (with confirmation)
- **About**: View app information and credits
- **Quit**: Exit the application

## Technical Details

- **Built with**: SwiftUI and AppKit
- **Architecture**: MVVM pattern with Combine for reactive updates
- **Storage**: UserDefaults for persistence
- **Monitoring**: Timer-based clipboard polling (0.5s intervals)
- **Memory**: Efficient storage with configurable limits

## Privacy & Security

- All clipboard data is stored locally on your device
- No data is transmitted over the internet
- Clipboard content is only monitored for text data
- Full control over data retention and deletion

## Contributing

This project is open source. Feel free to submit issues, feature requests, or pull requests.

## License

Copyright © 2025 Shyam Mahanta. All rights reserved.

## Credits

Created by [Shyam Mahanta](https://www.linkedin.com/in/shyam-mahanta)

---

**Version**: 1.0
**Last Updated**: December 2025
