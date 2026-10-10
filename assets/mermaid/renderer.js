/* Mermaid's output is local, inert SVG. Issue text never becomes executable HTML. */
(() => {
  const font = new URL('../fonts/NotoSansJP.ttf', document.currentScript.src).href;
  const style = document.createElement('style');
  style.textContent = `@font-face{font-family:PlaneDiagramJP;src:url("${font}")}`;
  document.head.append(style);
  // Scan decoded CSS tokens without changing the author's diagram text.
  const decodeCss = text => text
    .replace(/&?#(?:x([0-9a-f]+)|([0-9]+));/gi, (_, hex, dec) => {
      const point = parseInt(hex || dec, hex ? 16 : 10);
      return point > 0 && point <= 0x10ffff ? String.fromCodePoint(point) : '\ufffd';
    })
    .replace(/\\([0-9a-f]{1,6})\s?/gi, (_, hex) => {
      const point = parseInt(hex, 16);
      return point > 0 && point <= 0x10ffff ? String.fromCodePoint(point) : '\ufffd';
    })
    .replace(/\\([^\r\n\f])/g, '$1')
    .replace(/\/\*[\s\S]*?\*\//g, '');
  let queue = Promise.resolve();
  globalThis.planeRenderMermaid = (source, dark, id) => {
    const render = async () => {
      if (source.length > 100000 || /\b(?:url|image-set|image|cross-fade|paint|element)\s*\(|@import|@font-face/i.test(decodeCss(source))) {
        throw new Error('Unsupported embedded media');
      }
      mermaid.initialize({
        startOnLoad: false, securityLevel: 'strict', suppressErrorRendering: true,
        htmlLabels: false, flowchart: { htmlLabels: false },
        themeCSS: '', theme: dark ? 'dark' : 'default', fontFamily: 'PlaneDiagramJP, sans-serif',
        maxTextSize: 100000, maxEdges: 500,
        secure: ['secure', 'securityLevel', 'startOnLoad', 'suppressErrorRendering',
          'maxTextSize', 'maxEdges', 'htmlLabels', 'flowchart', 'fontFamily',
          'theme', 'themeCSS', 'themeVariables', 'dompurifyConfig'],
      });
      // Parsing is inert; reject image nodes before Mermaid's layout creates Image().
      const diagram = await mermaid.mermaidAPI.getDiagramFromText(source);
      const data = diagram.db.getData?.();
      if (Array.isArray(data?.nodes) && data.nodes.some(node => node.img != null || /^image/i.test(node.shape || ''))) throw new Error('Unsupported embedded media');
      await document.fonts.load('14px PlaneDiagramJP');
      const container = document.createElement('div');
      container.style.cssText = 'position:fixed;left:-100000px;top:0;visibility:hidden;pointer-events:none';
      document.body.append(container);
      try {
        const { svg } = await mermaid.render(id, source, container);
        const doc = new DOMParser().parseFromString(svg, 'image/svg+xml');
        const root = doc.documentElement;
        if (root.localName !== 'svg' || doc.querySelector('parsererror')) throw new Error('Invalid SVG');
        for (const node of root.querySelectorAll('script,foreignObject,image,iframe,object,embed')) node.remove();
        for (const node of [root, ...root.querySelectorAll('*')]) {
          for (const attr of [...node.attributes]) {
            if (/^on/i.test(attr.name) ||
                (/^(href|xlink:href)$/i.test(attr.name) && !attr.value.startsWith('#')) ||
                /@import|url\s*\(\s*['"]?(?!#)/i.test(attr.value)) node.removeAttribute(attr.name);
          }
          if (node.localName === 'style' && /@import|url\s*\(\s*['"]?(?!#)/i.test(node.textContent)) node.remove();
        }
        root.style.maxWidth = '100%';
        root.setAttribute('width', '100%');
        root.setAttribute('height', '100%');
        root.setAttribute('preserveAspectRatio', 'xMidYMid meet');
        return new XMLSerializer().serializeToString(root);
      } finally {
        container.remove();
      }
    };
    const result = queue.then(render);
    queue = result.catch(() => {});
    return result;
  };
})();
