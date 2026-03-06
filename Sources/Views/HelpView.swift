import SwiftUI
import WebKit

struct HelpView: View {
    var body: some View {
        HelpWebView()
            .frame(minWidth: 700, minHeight: 600)
            .background(Color(hex: "#1a1a2e"))
    }
}

struct HelpWebView: NSViewRepresentable {
    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        loadHelpIndex(in: webView)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {}

    private func loadHelpIndex(in webView: WKWebView) {
        // Look in the app bundle's Resources for the help book
        if let helpURL = Bundle.main.url(
            forResource: "index",
            withExtension: "html",
            subdirectory: "MonopolyAIRoyal.help/Contents/Resources/en.lproj"
        ) {
            let dirURL = helpURL.deletingLastPathComponent()
            webView.loadFileURL(helpURL, allowingReadAccessTo: dirURL.deletingLastPathComponent().deletingLastPathComponent())
        }
    }
}
