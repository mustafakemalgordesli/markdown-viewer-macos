import SwiftUI
import WebKit

/// Live HTML preview. The page is loaded once; later edits are pushed in via JavaScript
/// so the scroll position is preserved and there is no flicker.
struct MarkdownPreview: NSViewRepresentable {
    var markdown: String
    var baseURL: URL?
    var fontSize: Double

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        webView.navigationDelegate = context.coordinator
        webView.allowsMagnification = true

        let html = MarkdownRenderer.html(from: markdown)
        let coordinator = context.coordinator
        coordinator.lastMarkdown = markdown
        coordinator.lastHTML = html
        coordinator.lastFontSize = fontSize
        webView.loadHTMLString(PreviewTemplate.page(body: html, fontSize: fontSize), baseURL: baseURL)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let coordinator = context.coordinator

        if markdown != coordinator.lastMarkdown {
            coordinator.lastMarkdown = markdown
            let html = MarkdownRenderer.html(from: markdown)
            if html != coordinator.lastHTML {
                coordinator.lastHTML = html
                coordinator.run("update(\(Self.jsString(html)))", in: webView)
            }
        }
        if fontSize != coordinator.lastFontSize {
            coordinator.lastFontSize = fontSize
            coordinator.run("setFontSize(\(fontSize))", in: webView)
        }
    }

    static func jsString(_ string: String) -> String {
        guard let data = try? JSONEncoder().encode(string),
              let json = String(data: data, encoding: .utf8) else { return "\"\"" }
        return json
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var lastMarkdown = ""
        var lastHTML = ""
        var lastFontSize: Double = 0
        private var isLoaded = false
        private var needsResync = false

        func run(_ script: String, in webView: WKWebView) {
            guard isLoaded else { needsResync = true; return }
            webView.evaluateJavaScript(script, completionHandler: nil)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoaded = true
            if needsResync {
                needsResync = false
                webView.evaluateJavaScript(
                    "update(\(MarkdownPreview.jsString(lastHTML))); setFontSize(\(lastFontSize))",
                    completionHandler: nil
                )
            }
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            // Initial page load is allowed; clicked links open in the default app (browser, etc.).
            if navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url {
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }
    }
}
