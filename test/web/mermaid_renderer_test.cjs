const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

function renderer() {
  let fontRequests = 0;
  const context = { console, setTimeout, clearTimeout, URL };
  vm.createContext(context);
  vm.runInContext(fs.readFileSync("assets/mermaid/mermaid.min.js", "utf8"), context);
  context.document = {
    currentScript: { src: 'https://plane.example/mobile/assets/assets/mermaid/renderer.js' },
    createElement: () => ({}), head: { append() {} },
    fonts: { load() { fontRequests++; return Promise.reject(new Error('FONT_SENTINEL')); } },
  };
  vm.runInContext(fs.readFileSync("assets/mermaid/renderer.js", "utf8"), context);
  return { context, get fontRequests() { return fontRequests; } };
}

test('normal diagrams reach layout; malformed diagrams fail before layout', async () => {
  const r = renderer();
  await assert.rejects(r.context.planeRenderMermaid('graph TD; A --> B;', false, 'valid'), /FONT_SENTINEL/);
  assert.equal(r.fontRequests, 1);
  await assert.rejects(r.context.planeRenderMermaid('not a diagram', false, 'invalid'));
  assert.equal(r.fontRequests, 1);
});

test('media nodes including quoted JSON properties are rejected before image layout', async () => {
  for (const source of [
    'flowchart TD\nA@{ img: "/api/probe" }',
    'flowchart TD\nA@{ "img": "/api/probe" }',
    "flowchart TD\nA@{ 'img': '/api/probe' }",
  ]) {
    const r = renderer();
    await assert.rejects(r.context.planeRenderMermaid(source, false, 'media'), /Unsupported embedded media/);
    assert.equal(r.fontRequests, 0);
  }
});

test('resource-bearing CSS and escapes are rejected before parsing/layout', async () => {
  for (const css of ['url("/api/probe")', 'image-set("/api/probe")', '-webkit-image-set("/api/probe")', 'image("/api/probe")', '\\69mage-set("/api/probe")', '&#105;mage-set("/api/probe")', '#105;mage-set("/api/probe")']) {
    const r = renderer();
    await assert.rejects(r.context.planeRenderMermaid(`graph TD; A-->B;\nclassDef default background-image:${css};`, false, 'css'), /Unsupported embedded media/);
    assert.equal(r.fontRequests, 0);
  }
});

test('diagram directives cannot change themeCSS or security level', async () => {
  for (const source of [
    '%%{init: {"themeCSS":"body{color:red}","securityLevel":"loose"}}%%\ngraph TD; A-->B;',
    '---\nconfig:\n  themeCSS: "body{color:red}"\n  securityLevel: loose\n---\ngraph TD; A-->B;',
  ]) {
    const r = renderer();
    await assert.rejects(r.context.planeRenderMermaid(source, true, 'directive'), /FONT_SENTINEL/);
    await r.context.mermaid.parse(source);
    const config = r.context.mermaid.mermaidAPI.getConfig();
    assert.equal(config.themeCSS, '');
    assert.equal(config.securityLevel, 'strict');
    assert.equal(config.htmlLabels, false);
  }
});
