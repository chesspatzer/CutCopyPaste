# CutCopyPaste

A powerful macOS menubar clipboard manager built with SwiftUI and SwiftData. Runs entirely offline — no internet required, no cloud sync, no telemetry.

**Requires macOS 14.0 (Sonoma) or later.**

---

## Features

### Clipboard History
- Real-time clipboard monitoring with automatic capture
- Supports **text**, **rich text (RTF)**, **images**, **files**, and **links**
- Configurable history limit (up to 10,000 items) and retention period
- Pin important items to keep them permanently
- Consecutive duplicate detection and deduplication
- Source app tracking — see which app each clip came from
- Double-click any item to copy it back to the clipboard
- Drag and drop items out of the popover into other apps

### Smart Search
- Full-text search across all content, OCR text, summaries, and metadata
- **On-device semantic search** via Apple's NLEmbedding — finds "function" when you search "method", "error" when you search "exception"
- Pre-computed embedding vectors at capture time for instant search (~8-16ms total)
- **Natural language queries**: type "images from Xcode" or "links from yesterday" and the app understands
- Normalized matching handles separator differences (API_KEY matches "api key")
- Fuzzy matching with programming-aware synonyms as fallback
- Date-aware filters: "today", "last week", "five minutes ago" (word numbers supported)
- Category tabs: All, Text, Images, Links, Pinned, Snippets

### Text Transforms (28+)
Apply transforms directly from the hover actions menu on any text item:

| Category | Transforms |
|---|---|
| **Case** | camelCase to snake_case, snake_case to camelCase, to kebab-case |
| **Encoding** | Base64 encode/decode, URL encode/decode |
| **JSON** | Prettify, Minify, JSON to Swift Struct (with Codable + CodingKeys) |
| **Code Gen** | cURL to URLSession Swift code, SQL CREATE TABLE to SwiftData @Model |
| **Markup** | XML prettify, Markdown to plain text |
| **Colors** | Hex to RGB, RGB to Hex |
| **Code Formatting** | Strip line numbers, Normalize whitespace, Sort lines, Remove duplicate lines |

Transforms are context-aware — only applicable transforms appear based on content analysis.

### Sensitive Data Detection
Automatically detects and flags sensitive content on capture:

- AWS access keys and secret keys
- OpenAI API keys
- Stripe keys (test and live)
- GitHub tokens
- Generic API keys and secrets
- Credit card numbers (with Luhn validation)
- Social Security Numbers
- PEM private keys
- Database connection strings (MongoDB, MySQL, Postgres, Redis)
- Passwords in config files

Items with detected sensitive data show a warning badge. Enable **auto-mask** to automatically hide sensitive content in the UI.

### OCR (Image Text Extraction)
- Extract text from any captured image using Apple's Vision framework
- On-demand extraction via context menu, or enable auto-OCR for all images
- Extracted text becomes searchable alongside regular clipboard content
- View and copy OCR results from the item detail overlay

### Snippets & Templates
- Create reusable text templates with `{{placeholder}}` syntax
- Built-in variables: `{{date}}`, `{{time}}`, `{{clipboard}}`, `{{uuid}}`, `{{timestamp}}`
- Custom variables prompt a fill-in dialog before insertion
- Organize snippets into folders
- Ships with built-in templates: date stamp, code comment block, bug report, email reply, console log, guard statement
- Usage tracking (most-used snippets rise to the top)

### Diff & Merge
- **Compare**: Hover any item and click the compare button to select it — a floating bar appears showing selection progress with a "Compare" button when ready
- **Merge**: Click the merge button in the header to enter merge mode — selected items highlight purple, then merge with configurable separator
- Side-by-side diff with color-coded additions/deletions and line numbers

### Paste Stack (Multi-Copy Mode)
- Activate paste stack mode to queue up multiple copied items
- **FIFO (Queue)** or **LIFO (Stack)** mode
- Visual banner shows stack depth and current mode
- Paste items in order — great for filling out forms or migrating data between apps

### Clipboard Rules
- Create rules that automatically transform content on capture
- Filter by source app (bundle ID) and content type
- Available auto-transforms: strip ANSI codes, prettify JSON, strip URL tracking parameters, regex find/replace, trim whitespace, case conversion
- Ships with default rules for stripping terminal color codes
- Test rules inline before saving

### Workspace Awareness
- Detects your current project context from the frontmost app
- **Xcode**: extracts project name from window title
- **VS Code**: extracts workspace folder
- **Terminal / iTerm2**: extracts current working directory
- **Finder**: tracks the active folder
- Filter clipboard history by workspace using the chip bar below the category tabs

### Analytics Dashboard
- Copies per day chart (last 30 days)
- Content type distribution (pie chart)
- Peak usage hours (24-hour breakdown)
- Top source apps
- Most re-used items
- Total item count and daily average

Open from the overflow menu (ellipsis) in the popover header.

### Text Summarization
- Items longer than 200 characters get an automatic one-line summary
- Full stats available in the detail overlay: character/word/line/sentence/paragraph counts, estimated reading time
- Key phrase extraction via Apple's NaturalLanguage framework

### Quick Actions
Context-aware actions appear on hover based on content type:
- **URLs**: open in browser, strip tracking parameters, extract domain
- **JSON**: validate, extract keys
- **Colors**: preview swatch (hex colors show inline), convert formats
- **UUIDs**: detect and regenerate
- **Timestamps**: convert between epoch, ISO 8601, and human-readable

---

## UI

- Menubar popover (400x560 default, resizable in settings)
- **Always-visible copy button** on every row — no guessing, just click to copy
- Hover actions expand to show: compare, transforms/actions, pin, and delete
- **Labeled tab bar** — all category tabs show both icon and label for clarity
- **Dedicated header buttons** for Paste Stack and Merge mode (not hidden in a menu)
- **"Actions" label** on the transform menu — no more cryptic wand icon
- **Compare bar** appears when selecting items for diff, with clear "Compare" button
- **Sensitive data tooltip** — hover the warning badge to see what type of sensitive data was detected
- Metadata pills: timestamp, source app, workspace, character count, OCR badge
- Overlay-based modals (no system sheet conflicts with menubar windows)
- Color swatch preview for hex color strings
- Keyboard navigation: arrow keys to select, Enter to copy, Escape to deselect
- Staggered list entry animations

---

## Settings

| Tab | Options |
|---|---|
| **General** | Max history, retention days, deduplication, launch at login, sound on copy |
| **Appearance** | Compact/comfortable mode, popover dimensions, show timestamps, show source app |
| **Security** | Detect sensitive data, auto-mask |
| **Shortcuts** | Global toggle hotkey (default: Cmd+Shift+V), modifier key selection |
| **Exclusions** | Apps to never capture from (1Password, Bitwarden, LastPass, Keychain Access by default) |
| **Rules** | Create, edit, enable/disable, and test clipboard auto-transform rules |

---

## CLI Tool (`ccp`)

A companion command-line tool that shares the same SwiftData store as the GUI app.

```bash
# List recent clipboard history
ccp list
ccp list --count 20 --full

# Add text to clipboard history
ccp copy "some text"

# Output an item from history (0 = most recent)
ccp paste 0

# Search clipboard history
ccp search "query"
```

---

## Building

Requires [XcodeGen](https://github.com/yonaskolb/XcodeGen) and Xcode 15+.

```bash
# Generate the Xcode project
xcodegen generate

# Build the GUI app
xcodebuild -scheme CutCopyPaste -destination 'platform=macOS' build

# Build the CLI tool
xcodebuild -scheme CutCopyPasteCLI -destination 'platform=macOS' build
```

Or open `CutCopyPaste.xcodeproj` in Xcode and run the **CutCopyPaste** scheme.

---

## Architecture

- **100% SwiftUI + SwiftData** — no UIKit, no Core Data
- **No third-party dependencies** for the main app (CLI uses swift-argument-parser)
- **No internet access** — everything runs locally using Apple frameworks (Vision for OCR, NaturalLanguage for NLP, Charts for analytics)
- **Strict concurrency** — `@MainActor` isolated AppState, `@ModelActor` services

### Project Structure

```
CutCopyPaste/
├── App/                    # App entry point, AppState
├── Models/                 # SwiftData models (ClipboardItem, Snippet, ClipboardRule)
├── Services/               # Business logic (17 services)
│   └── Transforms/         # Transform implementations (9 files, 28+ transforms)
├── Views/
│   ├── MainPopover/        # Primary UI (list, search, tabs, overlays)
│   ├── Settings/           # Settings tabs
│   ├── Snippets/           # Snippet management
│   ├── Analytics/          # Dashboard and charts
│   ├── PasteStack/         # Multi-copy UI
│   └── Components/         # Reusable buttons, badges, menus
├── Extensions/             # Transferable conformance, helpers
└── Utilities/              # Constants, keyboard shortcuts

CutCopyPasteCLI/            # CLI tool (list, copy, paste, search)
```

---

## Privacy

- All data stays on your Mac — no network requests, no analytics, no telemetry
- Password manager apps are excluded from capture by default
- Sensitive data detection warns you about accidentally copied secrets
- Masking hides sensitive content in the UI without deleting it
