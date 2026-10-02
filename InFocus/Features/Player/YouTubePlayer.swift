import SwiftUI
import WebKit

/// The YouTube embed player in a web view, 16:9, played inline. YouTube
/// requires embeds to identify the app, so the page loads from an https
/// origin named after the bundle and sends it as the referrer.
struct YouTubePlayer: View {
    let videoId: String
    var autoplay = false

    var body: some View {
        YouTubeWebView(videoId: videoId, autoplay: autoplay)
            .aspectRatio(16 / 9, contentMode: .fit)
            .background(Color.black)
            .accessibilityLabel("Video player")
    }
}

private struct YouTubeWebView: UIViewRepresentable {
    let videoId: String
    let autoplay: Bool

    static let origin = URL(string: "https://com.infocuspaly.news")!

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = true
        config.allowsAirPlayForMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = autoplay ? [] : .all
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard context.coordinator.loadedVideo != videoId else { return }
        context.coordinator.loadedVideo = videoId
        webView.loadHTMLString(Self.html(videoId: videoId, autoplay: autoplay), baseURL: Self.origin)
    }

    static func html(videoId: String, autoplay: Bool) -> String {
        let query = "playsinline=1&rel=0&modestbranding=1&autoplay=\(autoplay ? 1 : 0)&origin=\(origin.absoluteString)"
        return """
        <!doctype html><html><head>
        <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1">
        <meta name="referrer" content="strict-origin-when-cross-origin">
        <style>html,body{margin:0;height:100%;background:#000}iframe{position:fixed;inset:0;width:100%;height:100%;border:0}</style>
        </head><body>
        <iframe src="https://www.youtube-nocookie.com/embed/\(videoId)?\(query)"
          title="YouTube video player" referrerpolicy="strict-origin-when-cross-origin"
          allow="autoplay; encrypted-media; picture-in-picture; fullscreen" allowfullscreen></iframe>
        </body></html>
        """
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var loadedVideo: String?

        /// The player stays in the frame; links out of it (title, logo) open YouTube.
        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction)
            async -> WKNavigationActionPolicy {
            guard action.targetFrame?.isMainFrame == true || action.targetFrame == nil,
                  action.navigationType == .linkActivated, let url = action.request.url else { return .allow }
            await UIApplication.shared.open(url)
            return .cancel
        }
    }
}
