import SwiftUI
import AppKit

/// A plain-text editor tuned for Markdown (no smart quotes / dashes, monospaced font, find bar).
struct MarkdownEditor: NSViewRepresentable {
    @Binding var text: String
    var fontSize: Double

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else { return scrollView }

        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.isGrammarCheckingEnabled = false
        textView.smartInsertDeleteEnabled = false
        textView.usesFindBar = true
        textView.isIncrementalSearchingEnabled = true
        textView.textContainerInset = NSSize(width: 14, height: 14)
        textView.font = Self.font(fontSize)
        textView.textColor = .textColor
        textView.backgroundColor = .textBackgroundColor
        textView.string = text
        context.coordinator.appliedFontSize = fontSize
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.parent = self
        guard let textView = scrollView.documentView as? NSTextView else { return }

        if textView.string != text {
            let selection = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selection.filter {
                NSMaxRange($0.rangeValue) <= (text as NSString).length
            }
        }
        if context.coordinator.appliedFontSize != fontSize {
            context.coordinator.appliedFontSize = fontSize
            textView.font = Self.font(fontSize)
        }
    }

    private static func font(_ size: Double) -> NSFont {
        .monospacedSystemFont(ofSize: size, weight: .regular)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MarkdownEditor
        var appliedFontSize: Double = 0

        init(_ parent: MarkdownEditor) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }
}
