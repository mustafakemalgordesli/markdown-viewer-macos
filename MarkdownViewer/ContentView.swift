import SwiftUI

struct ContentView: View {
    @Binding var document: MarkdownDocument
    let fileURL: URL?

    @AppStorage(Settings.viewMode) private var mode: ViewMode = .split
    @AppStorage(Settings.fontSize) private var fontSize: Double = Settings.defaultFontSize

    var body: some View {
        Group {
            switch mode {
            case .editor:
                editor
            case .preview:
                preview
            case .split:
                HSplitView {
                    editor.frame(minWidth: 240, maxWidth: .infinity)
                    preview.frame(minWidth: 240, maxWidth: .infinity)
                }
            }
        }
        .frame(minWidth: 520, minHeight: 360)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("View Mode", selection: $mode) {
                    ForEach(ViewMode.allCases) { m in
                        Label(m.title, systemImage: m.icon)
                            .help(m.menuTitle)
                            .tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .labelStyle(.iconOnly)
            }
        }
    }

    private var editor: some View {
        MarkdownEditor(text: $document.text, fontSize: fontSize)
    }

    private var preview: some View {
        MarkdownPreview(
            markdown: document.text,
            baseURL: fileURL?.deletingLastPathComponent(),
            fontSize: fontSize
        )
    }
}
