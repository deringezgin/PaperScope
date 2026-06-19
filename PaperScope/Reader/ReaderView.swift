import SwiftUI
import WebKit
import UIKit

// MARK: - Reader Palette

enum ReaderPalette {
    case light
    case dark

    init(colorScheme: ColorScheme) {
        self = colorScheme == .dark ? .dark : .light
    }

    /// The `data-theme` attribute value used by the injected CSS.
    var cssAttribute: String {
        switch self {
        case .light: return "light"
        case .dark: return "dark"
        }
    }

    /// Background color used for the web view itself, to avoid white flashes.
    var backgroundColor: UIColor {
        switch self {
        case .light: return UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        case .dark:  return UIColor(red: 0.059, green: 0.067, blue: 0.082, alpha: 1)
        }
    }
}

// MARK: - Reader View

struct ReaderView: View {
    let paperUrl: URL?
    var paperTitle: String = ""

    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("readerFontScale") private var fontScale: Double = 1.0

    @State private var isLoading = true
    @State private var progress: Double = 0
    @State private var zoomedImageURL: URL?

    private var palette: ReaderPalette {
        ReaderPalette(colorScheme: colorScheme)
    }

    var body: some View {
        ZStack(alignment: .top) {
            palette.swiftUIBackground.ignoresSafeArea()

            if let url = paperUrl {
                WebView(
                    url: url,
                    palette: palette,
                    fontScale: fontScale,
                    isLoading: $isLoading,
                    progress: $progress,
                    zoomedImageURL: $zoomedImageURL
                )
                .ignoresSafeArea(edges: .bottom)
                .opacity(isLoading ? 0 : 1)
                .animation(.easeIn(duration: 0.25), value: isLoading)
            } else {
                ContentUnavailableView(
                    "Reader Unavailable",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("There is no HTML version of this paper to read.")
                )
            }

            // Thin reading-progress bar pinned to the top.
            if !isLoading {
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(width: geo.size.width * CGFloat(progress), height: 2.5)
                        .animation(.easeOut(duration: 0.12), value: progress)
                }
                .frame(height: 2.5)
                .allowsHitTesting(false)
            }

            if isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(paperTitle)
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(palette == .dark ? .dark : .light)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                readerOptionsMenu
            }
        }
        .fullScreenCover(item: $zoomedImageURL) { url in
            ZoomableImageView(url: url)
        }
    }

    private var readerOptionsMenu: some View {
        Menu {
            Section("Text Size") {
                Button {
                    fontScale = max(0.8, (fontScale - 0.1).rounded(toPlaces: 1))
                } label: {
                    Label("Smaller", systemImage: "textformat.size.smaller")
                }
                .disabled(fontScale <= 0.8)

                Button {
                    fontScale = min(1.7, (fontScale + 0.1).rounded(toPlaces: 1))
                } label: {
                    Label("Larger", systemImage: "textformat.size.larger")
                }
                .disabled(fontScale >= 1.7)
            }
        } label: {
            Image(systemName: "textformat.size")
        }
    }
}

private extension ReaderPalette {
    var swiftUIBackground: Color { Color(backgroundColor) }
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

// Allow URL to drive `.fullScreenCover(item:)`.
extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

// MARK: - Web View

struct WebView: UIViewRepresentable {
    let url: URL
    let palette: ReaderPalette
    let fontScale: Double
    @Binding var isLoading: Bool
    @Binding var progress: Double
    @Binding var zoomedImageURL: URL?

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> WKWebView {
        let controller = WKUserContentController()
        controller.add(context.coordinator, name: "imageTap")
        controller.add(context.coordinator, name: "scroll")

        let config = WKWebViewConfiguration()
        config.userContentController = controller

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.isOpaque = false
        webView.backgroundColor = palette.backgroundColor
        webView.scrollView.backgroundColor = palette.backgroundColor
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.parent = self
        webView.backgroundColor = palette.backgroundColor
        webView.scrollView.backgroundColor = palette.backgroundColor

        // Apply live app color-scheme / font-size changes without reloading the document.
        if context.coordinator.didFinishLoad {
            let apply = """
            document.documentElement.setAttribute('data-theme', '\(palette.cssAttribute)');
            document.documentElement.style.setProperty('--reader-fs-scale', '\(fontScale)');
            """
            webView.evaluateJavaScript(apply)
        }
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        let controller = webView.configuration.userContentController
        controller.removeScriptMessageHandler(forName: "imageTap")
        controller.removeScriptMessageHandler(forName: "scroll")
    }

    // MARK: Coordinator

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: WebView
        var didFinishLoad = false

        init(_ parent: WebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async { self.parent.isLoading = true }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript(Self.reconstructScript(
                theme: parent.palette.cssAttribute,
                fontScale: parent.fontScale
            )) { [weak self] _, _ in
                self?.didFinishLoad = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    self?.parent.isLoading = false
                }
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async { self.parent.isLoading = false }
        }

        // Route external links to Safari; keep in-page anchors inside the reader.
        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .linkActivated,
               let target = navigationAction.request.url {
                if let current = webView.url,
                   target.host == current.host,
                   target.path == current.path {
                    decisionHandler(.allow)
                    return
                }
                UIApplication.shared.open(target)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }

        // MARK: Messages from the page

        func userContentController(_ userContentController: WKUserContentController,
                                   didReceive message: WKScriptMessage) {
            switch message.name {
            case "imageTap":
                if let src = message.body as? String, let url = URL(string: src) {
                    DispatchQueue.main.async { self.parent.zoomedImageURL = url }
                }
            case "scroll":
                if let value = message.body as? Double {
                    DispatchQueue.main.async { self.parent.progress = max(0, min(1, value)) }
                }
            default:
                break
            }
        }
    }
}

// MARK: - Zoomable Image Viewer (native)

struct ZoomableImageView: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(magnification)
                        .simultaneousGesture(drag)
                        .onTapGesture(count: 2) { toggleZoom() }
                case .failure:
                    Image(systemName: "photo.badge.exclamationmark")
                        .font(.largeTitle)
                        .foregroundStyle(.white.opacity(0.6))
                case .empty:
                    ProgressView().tint(.white)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .padding()
        }
        .statusBarHidden()
    }

    private var magnification: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = min(max(lastScale * value, 1), 6)
            }
            .onEnded { _ in
                lastScale = scale
                if scale <= 1 { resetTransform() }
            }
    }

    private var drag: some Gesture {
        DragGesture()
            .onChanged { value in
                guard scale > 1 else { return }
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in lastOffset = offset }
    }

    private func toggleZoom() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if scale > 1 {
                resetTransform()
            } else {
                scale = 2.5
                lastScale = 2.5
            }
        }
    }

    private func resetTransform() {
        scale = 1
        lastScale = 1
        offset = .zero
        lastOffset = .zero
    }
}

// MARK: - Reconstruction Script

extension WebView.Coordinator {
    /// Builds the JS that strips arXiv chrome, re-styles the paper for mobile reading,
    /// and tames wide content (display math, tables, figures).
    static func reconstructScript(theme: String, fontScale: Double) -> String {
        """
        (function() {
          // ---- 1. Inject reader stylesheet ----
          var css = `
          :root {
            --reader-base: 18px;
            --reader-fs-scale: 1;
            --reader-maxw: 720px;
          }
          html, body { overflow-x: hidden; max-width: 100%; box-sizing: border-box; }
          html { -webkit-text-size-adjust: 100%; }

          html[data-theme="light"] {
            --bg:#ffffff; --fg:#1c1c1e; --muted:#6b7177;
            --accent:#0a6cff; --rule:rgba(0,0,0,0.10); --card:rgba(0,0,0,0.035);
          }
          html[data-theme="dark"] {
            --bg:#0f1115; --fg:#e6e8ea; --muted:#9aa1a8;
            --accent:#4c9aff; --rule:rgba(255,255,255,0.12); --card:rgba(255,255,255,0.05);
          }

          html, body {
            margin: 0 !important; padding: 0 !important;
            background: var(--bg) !important; background-image: none !important;
            color: var(--fg) !important;
          }
          html::before, html::after, body::before, body::after {
            content: none !important; display: none !important;
          }

          body {
            font-family: -apple-system, system-ui, BlinkMacSystemFont, "SF Pro Text", Roboto, Helvetica, Arial, sans-serif !important;
            font-size: calc(var(--reader-base) * var(--reader-fs-scale)) !important;
            line-height: 1.65 !important;
            max-width: var(--reader-maxw) !important;
            margin: 0 auto !important;
            padding: 18px 20px 96px !important;
            hyphens: auto; -webkit-hyphens: auto;
            overflow-wrap: anywhere; word-break: break-word;
          }

          .reconstructed { max-width: 100%; overflow-wrap: anywhere; }
          .reconstructed > * { margin-bottom: 1.15em; }
          p { margin: 0 0 1em; overflow-wrap: anywhere; }
          p, .ltx_para, .ltx_p, li, .ltx_bibitem {
            text-align: left !important;
            text-justify: auto !important;
          }
          /* Long unbreakable tokens (URLs, unresolved citation keys) must wrap
             rather than stretch the whole page wide. */
          a, .ltx_ref, .ltx_url, .ltx_cite, code, tt { overflow-wrap: anywhere; }

          /* ---- Wide-content containment ---- */
          .scroll-x {
            overflow-x: auto; -webkit-overflow-scrolling: touch;
            max-width: 100%; margin: 1.3em 0;
            scrollbar-width: thin;
          }
          .scroll-x > * { margin: 0 auto !important; }
          .table-scroll {
            padding-bottom: 0.35em;
          }
          .scroll-x::-webkit-scrollbar { height: 5px; }
          .scroll-x::-webkit-scrollbar-thumb { background: var(--rule); border-radius: 3px; }

          /* ---- Images & figures ---- */
          img, svg, canvas, video { max-width: 100% !important; height: auto !important; }
          .ltx_figure:not(.ltx_table), figure:not(.ltx_table) {
            margin: 1.6em 0 !important; text-align: center;
            overflow-x: auto; -webkit-overflow-scrolling: touch;
          }
          .reconstructed img {
            display: inline-block; border-radius: 6px; cursor: zoom-in;
          }
          .ltx_caption, figcaption {
            font-size: 0.84em; color: var(--muted);
            margin-top: 0.7em; line-height: 1.45; text-align: left;
          }

          /* ---- Math ---- */
          math { font-size: 1.0em; }
          math[display="block"] { display: block; margin: 0 auto; }
          table.ltx_eqn_table { margin: 0 auto; border: none; }
          table.ltx_eqn_table td { border: none; padding: 2px 6px; }
          .ltx_eqn_cell { white-space: nowrap; }

          /* ---- Data tables ---- */
          .ltx_table {
            margin: 1.6em 0 !important;
            max-width: 100%;
            overflow-x: visible !important;
            text-align: center;
          }
          table.ltx_tabular {
            border-collapse: collapse;
            margin: 0 auto;
            font-size: 1em;
            max-width: none !important;
            table-layout: auto !important;
            width: max-content !important;
          }
          .ltx_tabular td, .ltx_tabular th {
            padding: 6px 11px; border-color: var(--rule) !important;
          }
          .ltx_tabular th { font-weight: 700; }
          .ltx_table .ltx_transformed_outer {
            display: inline-block !important;
            height: auto !important;
            max-width: none !important;
            vertical-align: baseline !important;
            width: max-content !important;
          }
          .ltx_table .ltx_transformed_inner {
            display: inline-block !important;
            transform: none !important;
          }

          /* ---- Title / authors ---- */
          .ltx_title_document {
            font-size: 1.72em; line-height: 1.18; font-weight: 800;
            margin: 0 0 0.35em !important;
          }
          .ltx_authors {
            color: var(--muted); font-size: 0.95em; line-height: 1.5;
            margin: 0 0 1.6em !important; font-style: normal;
          }
          .ltx_personname { font-style: normal; }
          .ltx_authors, .ltx_authors * { white-space: normal !important; }
          .ltx_author_notes, .ltx_contact { display: none !important; }

          /* ---- Abstract ---- */
          .ltx_abstract {
            background: var(--card); padding: 16px 18px;
            border-radius: 12px; border-left: 3px solid var(--accent);
          }
          .ltx_abstract .ltx_title, .ltx_title_abstract {
            font-size: 0.78em; text-transform: uppercase; letter-spacing: 0.07em;
            color: var(--accent); font-weight: 700; margin: 0 0 0.5em; display: block;
          }
          .ltx_abstract p { margin-bottom: 0; }

          /* ---- Headings ---- */
          .ltx_title_section {
            font-size: 1.38em; font-weight: 700; line-height: 1.25;
            margin: 1.9em 0 0.55em; padding-bottom: 0.3em;
            border-bottom: 1px solid var(--rule);
          }
          .ltx_title_subsection { font-size: 1.16em; font-weight: 650; margin: 1.4em 0 0.4em; }
          .ltx_title_subsubsection, .ltx_title_paragraph { font-size: 1.02em; font-weight: 650; margin: 1.1em 0 0.35em; }

          /* ---- Links & citations ---- */
          a, .ltx_ref { color: var(--accent); text-decoration: none; }
          .citation-back-link {
            margin-left: 6px; font-size: 0.9em; text-decoration: none;
            color: var(--accent); opacity: 0.85;
          }

          /* ---- Lists ---- */
          .ltx_itemize, .ltx_enumerate, ul, ol { padding-left: 1.4em; }
          .ltx_item { margin-bottom: 0.4em; }

          /* ---- Bibliography ---- */
          .ltx_bibliography .ltx_title { font-size: 1.38em; font-weight: 700; margin-bottom: 0.6em; }
          .ltx_bibitem { margin-bottom: 0.85em; font-size: 0.9em; line-height: 1.5; }

          /* ---- Reading progress bar ---- */
          #reader-progress {
            position: fixed; top: 0; left: 0; height: 0;
          }
          ::selection { background: color-mix(in srgb, var(--accent) 30%, transparent); }
          `;
          var styleEl = document.createElement('style');
          styleEl.textContent = css;
          document.head.appendChild(styleEl);

          // ---- 2. Add back-links from bibliography to citations ----
          var counter = 0;
          document.querySelectorAll('.ltx_cite .ltx_ref').forEach(function(ref) {
            var href = ref.getAttribute('href');
            if (href && href.charAt(0) === '#') {
              var target = document.getElementById(href.substring(1));
              if (target) {
                counter++;
                if (!ref.id) { ref.id = 'cite-src-' + counter; }
                var back = document.createElement('a');
                back.href = '#' + ref.id;
                back.className = 'citation-back-link';
                back.textContent = '\\u21A9';
                target.appendChild(back);
              }
            }
          });

          // ---- 3. Collect the content we want, in reading order ----
          var picked = [];
          function consider(el) {
            if (!el) return;
            if (picked.some(function(p) { return p.contains(el); })) return;
            picked.push(el);
          }
          ['.ltx_title_document', '.ltx_authors', '.ltx_dates', '.ltx_abstract'].forEach(function(sel) {
            consider(document.querySelector(sel));
          });
          document.querySelectorAll(
            '.ltx_section, .ltx_appendix, .ltx_acknowledgement, .ltx_acknowledgements, .ltx_bibliography'
          ).forEach(consider);

          var container = document.createElement('div');
          container.className = 'reconstructed';
          picked.forEach(function(el) { container.appendChild(el.cloneNode(true)); });

          document.body.innerHTML = '';
          document.body.appendChild(container);

          // ---- 4. Tame wide content (display math + data tables + block math) ----
          function wrap(el, extraClass) {
            var parent = el.parentNode;
            if (!parent) return;
            if (el.closest && el.closest('.scroll-x')) return;
            if (parent.classList && parent.classList.contains('scroll-x')) return;
            var box = document.createElement('div');
            box.className = extraClass ? 'scroll-x ' + extraClass : 'scroll-x';
            parent.insertBefore(box, el);
            box.appendChild(el);
          }
          container.querySelectorAll(
            'table.ltx_eqn_table, table.ltx_equation, table.ltx_equationgroup'
          ).forEach(wrap);
          container.querySelectorAll('math[display="block"]').forEach(function(m) {
            if (!m.closest('table.ltx_eqn_table') && !m.closest('.scroll-x')) { wrap(m); }
          });

          var tableTargets = [];
          function addTableTarget(el) {
            if (el && tableTargets.indexOf(el) === -1) { tableTargets.push(el); }
          }
          container.querySelectorAll('table.ltx_tabular').forEach(function(table) {
            addTableTarget(table.closest('.ltx_transformed_outer, .ltx_inline-block') || table);
          });
          container.querySelectorAll('.ltx_table > .ltx_transformed_outer, .ltx_table > .ltx_inline-block').forEach(addTableTarget);
          tableTargets.forEach(function(el) { wrap(el, 'table-scroll'); });

          // ---- 5. Native image zoom: forward taps to Swift ----
          container.querySelectorAll('img').forEach(function(img) {
            img.addEventListener('click', function(e) {
              e.preventDefault();
              e.stopPropagation();
              var src = img.currentSrc || img.src;
              if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.imageTap) {
                window.webkit.messageHandlers.imageTap.postMessage(src);
              }
            });
          });

          // ---- 6. Reading progress reporting ----
          function reportProgress() {
            var doc = document.documentElement;
            var max = doc.scrollHeight - doc.clientHeight;
            var p = max > 0 ? (window.scrollY || doc.scrollTop) / max : 0;
            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.scroll) {
              window.webkit.messageHandlers.scroll.postMessage(p);
            }
          }
          window.addEventListener('scroll', reportProgress, { passive: true });
          reportProgress();

          // ---- 7. Apply current theme + font scale ----
          document.documentElement.setAttribute('data-theme', '\(theme)');
          document.documentElement.style.setProperty('--reader-fs-scale', '\(fontScale)');
        })();
        """
    }
}
