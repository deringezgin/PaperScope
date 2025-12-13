import SwiftUI
import WebKit
import UIKit

struct ReaderView: View {
    let paperUrl: URL?
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            if let url = paperUrl {
                WebView(url: url, isLoading: $isLoading)
                    .edgesIgnoringSafeArea(.all)
                    .opacity(isLoading ? 0 : 1)
                    .animation(.easeIn(duration: 0.3), value: isLoading)
            } else {
                Text("Content not available")
                    .foregroundColor(.secondary)
            }
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }
}

struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.backgroundColor = .systemBackground
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if webView.url == nil {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        
        init(parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // "Scrape and Reconstruct" Logic
            // We use JS to remove all non-content elements and inject our own styling to make it look like a native reader.
            
            let js = """
            // Strict Reconstruction Logic
            // We define strictly what we want to keep, based on the user's requirement.
            
            const allowedSelectors = [
                '.ltx_title_document', // Title
                '.ltx_authors',        // Authors
                '.ltx_abstract',       // Abstract
                '.ltx_section',        // Sections (contains content)
                '.ltx_bibliography'    // References
            ];
            
            // 1. Extract content
            const newContent = document.createElement('div');
            newContent.className = 'reconstructed-paper';
            
            allowedSelectors.forEach(selector => {
                const elements = document.querySelectorAll(selector);
                elements.forEach(el => {
                   // Clone the node to move it (or just move it)
                   newContent.appendChild(el.cloneNode(true));
                });
            });
            
            // 2. Clear the Body but PRESERVE HEAD (to keep arXiv CSS for Math/Tables)
            document.body.innerHTML = '';
            
            // 3. Append the new clean content
            document.body.appendChild(newContent);
            
            // 4. Inject Custom Styling for the Reconstructed View
            const style = document.createElement('style');
            style.innerHTML = `
            :root {
                color-scheme: light dark;
            }
            
            /* Aggressive Reset to remove 'Beta' watermarks/flairs likely on pseudo-elements */
            html, body {
                margin: 0 !important;
                padding: 0 !important;
                background: #ffffff !important;
                background-image: none !important;
            }
            
            html::before, html::after, body::before, body::after {
                content: none !important;
                display: none !important;
                background: none !important;
                width: 0 !important;
                height: 0 !important;
                opacity: 0 !important;
            }
            
            body {
                font-family: -apple-system, system-ui, BlinkMacSystemFont, "SF Pro Text", Roboto, Helvetica, Arial, sans-serif !important;
                font-size: 18px !important;
                line-height: 1.6 !important;
                padding: 24px 20px !important;
                margin: 0 auto !important;
                max-width: 800px !important;
                color: #000000 !important;
                -webkit-text-size-adjust: 100%;
            }
            
            /* Ensure the reconstructed container handles spacing */
            .reconstructed-paper > * {
                margin-bottom: 24px;
            }
            
            /* Hide scrolling on body, let webview handle it */
            html {
                overflow-x: hidden;
            }
            
            /* Responsive Images */
            img, video, canvas, svg {
                max-width: 100% !important;
                height: auto !important;
                border-radius: 8px;
                box-shadow: 0 4px 12px rgba(0,0,0,0.1);
            }
            
            /* Clean up Math */
            .MathJax {
                outline: none !important;
                font-size: 105% !important;
            }
            
            /* Typography */
            .ltx_title_document {
                font-size: 28px !important;
                line-height: 1.2 !important;
                font-weight: 800 !important;
                margin-top: 0 !important;
            }
            
            .ltx_authors {
                font-size: 16px !important;
                color: var(--secondary-label, #666);
                margin-bottom: 32px !important;
                font-style: italic;
            }
            
            /* Adjust abstract styling */
            .ltx_abstract {
               background-color: rgba(128,128,128, 0.05);
               padding: 16px;
               border-radius: 12px;
               border-left: 4px solid #007AFF;
            }
            
            .ltx_title_abstract {
                font-weight: 700;
                font-size: 14px;
                text-transform: uppercase;
                color: #007AFF;
                margin-bottom: 8px;
                display: block;
            }
            
            /* Section Headers */
            h2, .ltx_title_section {
                font-size: 24px !important;
                font-weight: 700 !important;
                margin-top: 40px !important;
                border-bottom: 1px solid rgba(128,128,128,0.2);
                padding-bottom: 8px;
            }
            
            h3, .ltx_title_subsection {
                font-size: 20px !important;
                font-weight: 600 !important;
                margin-top: 24px !important;
            }
            
            /* Dark Mode Support */
            @media (prefers-color-scheme: dark) {
                html, body {
                    background: #000000 !important;
                    background-color: #000000 !important;
                    color: #E0E0E0 !important;
                }
                .ltx_authors { color: #aaa; }
                a { color: #64b5f6 !important; }
            }
            `;
            
            document.head.appendChild(style);
            """
            
            webView.evaluateJavaScript(js) { _, _ in
                // Reveal the content
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.parent.isLoading = false
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }
    }
}
