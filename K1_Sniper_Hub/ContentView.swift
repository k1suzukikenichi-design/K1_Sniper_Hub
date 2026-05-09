import SwiftUI
import FirebaseCore
import FirebaseFirestore
import WebKit

// MARK: - AppDelegate（Firebase 初期化）

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

// MARK: - ContentView

struct ContentView: View {
    private let quantAgentURL = URL(string: "https://glider-thirsty-cursor.ngrok-free.dev/demo")!

    var body: some View {
        ZStack {
            K1QuantAgentWebView(url: quantAgentURL)
                .ignoresSafeArea()

            VStack {
                HStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("K1 QuantAgent")
                    Spacer()
                    Text("LOCAL")
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.18))
                        .clipShape(Capsule())
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.black.opacity(0.45))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.top, 8)
                .padding(.horizontal, 10)

                Spacer()
            }
        }
    }
}

// MARK: - WebView

struct K1QuantAgentWebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if webView.url != url {
            webView.load(URLRequest(url: url))
        }
    }
}
