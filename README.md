# AI-HUB-AHK

A comprehensive AutoHotkey v2 application combining hotkey management, AI chat, data storage, and grammar correction in one intuitive interface.

## Features

### Hotkey Manager (Tab 1)
- **Visual Modifier Selection**: Toggle Ctrl, Alt, Win, Shift, and CapsLock modifiers with checkboxes
- **Key Capture Dialog**: Press any key to capture it as your hotkey trigger
- **Action Types**:
  - Send Text - Type out the configured text
  - Run Program - Launch applications
  - Open URL - Open websites
  - Custom Script - Execute custom AutoHotkey code
- **Hotkey Management**: Edit, delete, and save hotkeys with descriptions
- **Persistent Storage**: All hotkeys are saved to `config.json`

### AI Chat (Tab 2)
- **Conversation Interface**: Chat with AI models directly from the app
- **Quick Prompts**: One-click buttons for common tasks:
  - Fix Grammar
  - Summarize
  - Explain
  - Translate
- **Chat History**: Conversation is maintained during session
- **API Integration Ready**: Configure your preferred AI provider (OpenAI, Anthropic, etc.)

### Data Storage (Tab 3)
- **Categorized Storage**: Organize data by type:
  - General
  - Personal Info
  - API Keys
  - Phone Numbers
  - Email Addresses
  - Addresses
  - Important Dates
  - Passwords
  - Account Numbers
  - Notes
- **Search & Filter**: Quickly find stored data
- **Quick Copy**: Double-click to copy values to clipboard
- **Export**: Export data to JSON files
- **Tags**: Add tags for better organization

### Settings (Tab 4)
- **AI Configuration**: Set up API keys, endpoints, and model selection
- **General Options**:
  - Start with Windows
  - Minimize to tray
  - Show notifications
  - Auto-save
  - Dark mode
- **Import/Export**: Backup and restore configurations

## Global Hotkeys

| Hotkey | Action |
|--------|--------|
| `Ctrl+Alt+S` | Grammar correction - selects all text in active field, sends to AI for correction |
| `Ctrl+Alt+H` | Show/hide the main AI-HUB window |

## Installation

1. Install [AutoHotkey v2.0](https://www.autohotkey.com/)
2. Clone or download this repository
3. Run `AI-HUB.ahk`

## File Structure

```
AI-HUB-AHK/
  AI-HUB.ahk          # Main application
  lib/
    JSON.ahk          # JSON parsing library
  config.json         # Hotkey and settings storage (auto-created)
  storage.json        # Data storage (auto-created)
```

## Usage

### Creating a Hotkey

1. Go to the **Hotkeys** tab
2. Select your modifiers (Ctrl, Alt, Win, Shift, CapsLock)
3. Click **Capture** and press your desired trigger key
4. Enter a description for reference
5. Enter the output/action (text to type, program path, URL, etc.)
6. Select the action type
7. Click **Add**

### Using Grammar Correction

1. Configure your API key in **Settings** tab
2. Place cursor in any text field
3. Press `Ctrl+Alt+S`
4. The text will be selected, sent to AI, and replaced with corrected version

### Storing Data

1. Go to **Data Storage** tab
2. Select a category
3. Enter a name/label and value
4. Optionally add tags
5. Click **Add Entry**
6. Double-click any entry to copy its value to clipboard

## API Configuration

To enable AI features:

1. Go to **Settings** tab
2. Select your API provider
3. Enter your API key
4. Adjust endpoint and model if needed
5. Click **Save API Key**

Supported providers:
- OpenAI
- Anthropic
- Local LLM
- Custom endpoints

## Requirements

- Windows 10/11
- AutoHotkey v2.0+

## License

MIT License
