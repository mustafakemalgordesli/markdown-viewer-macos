import Foundation

enum PreviewTemplate {
    static func page(body: String, fontSize: Double) -> String {
        """
        <!doctype html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="color-scheme" content="light dark">
        <style>\(css)</style>
        <style id="font-size">:root { --fs: \(fontSize)px; }</style>
        </head>
        <body>
        <article id="content" class="markdown-body">\(body)</article>
        <script>\(script)</script>
        </body>
        </html>
        """
    }

    private static let script = #"""
    function slugify(text) {
      return text.toLowerCase().trim()
        .replace(/[^\p{L}\p{N}\s_-]/gu, '')
        .replace(/\s+/g, '-');
    }
    function decorate() {
      const seen = {};
      document.querySelectorAll('#content h1, #content h2, #content h3, #content h4, #content h5, #content h6')
        .forEach(h => {
          let id = slugify(h.textContent);
          if (seen[id] !== undefined) { seen[id] += 1; id += '-' + seen[id]; } else { seen[id] = 0; }
          h.id = id;
        });
    }
    function update(html) {
      document.getElementById('content').innerHTML = html;
      decorate();
    }
    function setFontSize(px) {
      document.getElementById('font-size').textContent = ':root { --fs: ' + px + 'px; }';
    }
    // In-page anchor links (#heading) scroll instead of navigating.
    document.addEventListener('click', e => {
      const a = e.target.closest('a[href^="#"]');
      if (!a) return;
      e.preventDefault();
      const target = document.getElementById(decodeURIComponent(a.getAttribute('href').slice(1)));
      if (target) target.scrollIntoView({ behavior: 'smooth' });
    });
    decorate();
    """#

    private static let css = """
    :root {
      --fs: 14px;
      --fg: #1f2328; --muted: #59636e; --bg: #ffffff; --border: #d1d9e0;
      --code-bg: rgba(129,139,152,0.12); --pre-bg: #f6f8fa; --link: #0969da;
      --quote: #59636e; --row-alt: #f6f8fa;
    }
    @media (prefers-color-scheme: dark) {
      :root {
        --fg: #e6edf3; --muted: #9198a1; --bg: #1e1e1e; --border: #3d444d;
        --code-bg: rgba(101,108,118,0.25); --pre-bg: #262626; --link: #4493f8;
        --quote: #9198a1; --row-alt: #252525;
      }
    }
    html { background: var(--bg); }
    body {
      margin: 0; padding: 28px 32px 64px;
      font: calc(var(--fs) * 1.08)/1.6 -apple-system, BlinkMacSystemFont, "Helvetica Neue", sans-serif;
      color: var(--fg); background: var(--bg);
      -webkit-font-smoothing: antialiased; word-wrap: break-word;
    }
    .markdown-body { max-width: 860px; margin: 0 auto; }
    .markdown-body > *:first-child { margin-top: 0 !important; }
    h1, h2, h3, h4, h5, h6 { margin: 1.5em 0 0.6em; font-weight: 600; line-height: 1.25; }
    h1 { font-size: 2em; padding-bottom: .3em; border-bottom: 1px solid var(--border); }
    h2 { font-size: 1.5em; padding-bottom: .3em; border-bottom: 1px solid var(--border); }
    h3 { font-size: 1.25em; } h4 { font-size: 1em; } h5 { font-size: .875em; }
    h6 { font-size: .85em; color: var(--muted); }
    p, ul, ol, blockquote, pre, table { margin: 0 0 1em; }
    a { color: var(--link); text-decoration: none; }
    a:hover { text-decoration: underline; }
    ul, ol { padding-left: 2em; }
    li + li { margin-top: .25em; }
    li > p { margin: 0 0 .5em; }
    li > p:last-child { margin-bottom: 0; }
    .task-list-item { list-style: none; }
    .task-list-item > input { margin: 0 .4em 0 -1.4em; vertical-align: middle; }
    .task-list-item > p { display: inline; }
    blockquote { padding: 0 1em; color: var(--quote); border-left: .25em solid var(--border); }
    code {
      font: .88em/1.45 ui-monospace, "SF Mono", Menlo, monospace;
      background: var(--code-bg); padding: .2em .4em; border-radius: 6px;
    }
    pre {
      background: var(--pre-bg); padding: 14px 16px; border-radius: 8px; overflow: auto;
    }
    pre code { background: none; padding: 0; font-size: .85em; white-space: pre; }
    hr { height: 2px; border: 0; background: var(--border); margin: 1.5em 0; }
    table { border-collapse: collapse; display: block; width: max-content; max-width: 100%; overflow: auto; }
    th, td { border: 1px solid var(--border); padding: 6px 13px; }
    th { font-weight: 600; }
    tbody tr:nth-child(2n) { background: var(--row-alt); }
    img { max-width: 100%; }
    del { color: var(--muted); }
    """
}
