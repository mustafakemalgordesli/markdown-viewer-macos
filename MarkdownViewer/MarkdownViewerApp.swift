import SwiftUI
import AppKit

@main
struct MarkdownViewerApp: App {
    @AppStorage(Settings.viewMode) private var mode: ViewMode = .split
    @AppStorage(Settings.fontSize) private var fontSize: Double = Settings.defaultFontSize

    var body: some Scene {
        DocumentGroup(newDocument: MarkdownDocument(text: "# Untitled\n\n")) { file in
            ContentView(document: file.$document, fileURL: file.fileURL)
        }
        .commands {
            CommandGroup(after: .appSettings) {
                Button("Set as Default App for Markdown…") {
                    DefaultAppHelper.makeDefault()
                }
            }
            CommandGroup(before: .toolbar) {
                ForEach(ViewMode.allCases) { m in
                    Button(m.menuTitle) { mode = m }
                        .keyboardShortcut(m.shortcut, modifiers: .command)
                }
                Divider()
                Button("Bigger Text") { fontSize = min(fontSize + 1, 36) }
                    .keyboardShortcut("+", modifiers: .command)
                Button("Smaller Text") { fontSize = max(fontSize - 1, 9) }
                    .keyboardShortcut("-", modifiers: .command)
                Button("Actual Size") { fontSize = Settings.defaultFontSize }
                    .keyboardShortcut("0", modifiers: .command)
                Divider()
            }
        }
    }
}

enum Settings {
    static let viewMode = "viewMode"
    static let fontSize = "fontSize"
    static let defaultFontSize: Double = 14
}

enum ViewMode: String, CaseIterable, Identifiable {
    case editor, split, preview
    var id: String { rawValue }

    var title: String {
        switch self {
        case .editor: "Editor"
        case .split: "Split"
        case .preview: "Preview"
        }
    }

    var menuTitle: String {
        switch self {
        case .editor: "Show Editor Only"
        case .split: "Show Editor and Preview"
        case .preview: "Show Preview Only"
        }
    }

    var icon: String {
        switch self {
        case .editor: "square.and.pencil"
        case .split: "rectangle.split.2x1"
        case .preview: "eye"
        }
    }

    var shortcut: KeyEquivalent {
        switch self {
        case .editor: "1"
        case .split: "2"
        case .preview: "3"
        }
    }
}

enum DefaultAppHelper {
    static func makeDefault() {
        NSWorkspace.shared.setDefaultApplication(
            at: Bundle.main.bundleURL,
            toOpen: .markdownText
        ) { error in
            DispatchQueue.main.async {
                let alert = NSAlert()
                if let error {
                    alert.messageText = "Could not set default app"
                    alert.informativeText = error.localizedDescription
                    alert.alertStyle = .warning
                } else {
                    alert.messageText = "Markdown Viewer is now the default app"
                    alert.informativeText = "Double-clicking .md files will open them here."
                }
                alert.runModal()
            }
        }
    }
}
