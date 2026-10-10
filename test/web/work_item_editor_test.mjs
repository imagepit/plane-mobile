import test, { afterEach } from 'node:test';
import assert from 'node:assert/strict';
import { JSDOM } from 'jsdom';

const dom = new JSDOM('<!doctype html><html><head><base href="https://plane.example/mobile/"></head><body></body></html>', { pretendToBeVisual: true });
for (const key of ['window', 'document', 'Node', 'HTMLElement', 'Element', 'MutationObserver', 'DOMParser', 'getComputedStyle'])
  globalThis[key] = key === 'getComputedStyle' ? dom.window[key].bind(dom.window) : dom.window[key];
Object.defineProperty(globalThis, 'navigator', { configurable: true, value: dom.window.navigator });
globalThis.requestAnimationFrame = dom.window.requestAnimationFrame.bind(dom.window);
globalThis.cancelAnimationFrame = dom.window.cancelAnimationFrame.bind(dom.window);
globalThis.ResizeObserver = class { observe() {} disconnect() {} };
dom.window.Range.prototype.getClientRects = () => [];
dom.window.Range.prototype.getBoundingClientRect = () => ({ top: 0, bottom: 0, left: 0, right: 0 });
const { createDocumentEditor, safeLink } = await import('../../scripts/editor/document.mjs');
const { mountEditor } = await import('../../scripts/editor/editor.mjs');
const cleanups = [];
afterEach(() => { for (const close of cleanups.splice(0)) close(); document.body.replaceChildren(); });
const tick = () => new Promise(resolve => setTimeout(resolve, 40));

function open(html) {
  const host = document.createElement('div'); document.body.append(host);
  const result = createDocumentEditor(host, html);
  cleanups.push(() => result.editor.destroy());
  return result;
}
function addText(result, text = '追記') { result.editor.commands.insertContentAt(1, text); }
function ui(html = '<p>テストタスク</p>', onSave = async () => '') {
  const host = document.createElement('div'); document.body.append(host);
  let closes = 0;
  const handle = mountEditor(host, '日本語のタイトル', html, 'IMAGE-9', 'body', false, 1, onSave, () => closes++);
  cleanups.push(() => handle.destroy());
  const click = label => host.querySelector(`button[aria-label="${label}"]`).click();
  return { host, handle, click, closes: () => closes };
}

test('untouched HTML is byte-exact, including unsupported blocks and attributes', () => {
  const html = '<p class="custom" style="text-align:center">日本語 <strong>太字</strong></p><img src="https://other.example/a.png"><div data-type="equation" data-latex="x^2">数式</div>';
  const result = open(html);
  assert.equal(result.html(), html);
  assert.equal(result.changed(), false);
  assert.equal(document.querySelectorAll('img[src]').length, 0);
  assert.equal(document.querySelectorAll('[style*="text-align"]').length, 0);
});
test('editing surrounding text preserves Mermaid/tree language metadata, source and unknown attributes', () => {
  const html = '<p data-custom="keep">本文</p><pre data-language="mermaid" class="original"><code class="language-mermaid" data-code="keep">flowchart RL\nA["日本語"] --&gt; B\n</code></pre><pre class="language-tree"><code>.\n└── ++ 日本語.dart &lt;--[新規]</code></pre>';
  const result = open(html); addText(result);
  const output = document.createElement('template'); output.innerHTML = result.html();
  assert.equal(output.content.querySelector('p').getAttribute('data-custom'), 'keep');
  const blocks = output.content.querySelectorAll('pre');
  assert.equal(blocks[0].getAttribute('data-language'), 'mermaid');
  assert.equal(blocks[0].querySelector('code').getAttribute('data-code'), 'keep');
  assert.equal(blocks[0].textContent, 'flowchart RL\nA["日本語"] --> B\n');
  assert.equal(blocks[1].className, 'language-tree');
  assert.equal(blocks[1].textContent, '.\n└── ++ 日本語.dart <--[新規]');
  assert.ok(!result.html().includes('data-plane-'));
});
test('code editing retains BR newlines, entities and language, undo restores original bytes', () => {
  const html = '<pre data-language="mermaid"><code>A &lt; B<br>C &amp; D</code></pre>';
  const result = open(html);
  result.editor.commands.insertContentAt(1, '日本語\n');
  assert.match(result.html(), /data-language="mermaid"/);
  assert.match(result.html(), /日本語\nA &lt; B\nC &amp; D/);
  result.editor.commands.undo();
  assert.equal(result.changed(), false);
  assert.equal(result.html(), html);
});
test('editing other text preserves mixed pre/code source and nonstandard table/list wrappers', () => {
  const blocks = '<pre data-language="mermaid"><code>flowchart LR</code>\nA --&gt; B</pre>' +
    '<table><caption>図の説明</caption><tbody data-custom="keep"><tr><td><p>表の内容</p></td></tr></tbody></table>' +
    '<ol><li data-type="custom"><p>独自の項目</p></li></ol>';
  const result = open(`<p>本文</p>${blocks}`); addText(result);
  assert.ok(result.html().endsWith(blocks));
});
test('nested spans retain both decorations when their own text is edited', () => {
  const result = open('<p><span style="color:red"><span style="font-size:24px">Text</span></span></p>');
  addText(result);
  assert.match(result.html(), /<span style="color:red"><span style="font-size:24px">追記Text<\/span><\/span>/);
});
test('raw block restoration never substitutes token-shaped attribute values or text', () => {
  const result = open('<p title="&lt;!--plane-preserved-0--&gt;">Text</p><div data-type="equation">eq</div>');
  addText(result);
  const output = document.createElement('template'); output.innerHTML = result.html();
  assert.equal(output.content.querySelector('p').title, '<!--plane-preserved-0-->');
  assert.equal(output.content.querySelector('p').textContent, '追記Text');
  assert.equal(output.content.querySelectorAll('[data-type=equation]').length, 1);
});
test('unsupported media, mentions and equations survive a body edit without live requests or event attributes', () => {
  const raw = '<iframe src="https://external.example/embed"></iframe><div data-type="equation" data-latex="x^2">equation</div>';
  const inline = '<span data-type="mention" data-id="u1">@良輔</span><img src="/files/one.png" onerror="alert(1)">';
  const result = open(`<p onclick="alert(1)">本文${inline}</p>${raw}`); addText(result);
  assert.equal(document.querySelectorAll('img[src],iframe,[onclick],[onerror]').length, 0);
  assert.ok(result.html().includes(inline));
  assert.ok(result.html().includes(raw));
});
test('formatting, H1-H6, lists, tasks, table and quote are editable rich nodes', () => {
  const result = open('<p>日本語本文</p>');
  result.editor.commands.selectAll();
  result.editor.commands.toggleBold(); result.editor.commands.toggleItalic();
  result.editor.commands.toggleUnderline(); result.editor.commands.toggleStrike();
  for (const tag of ['strong', 'em', 'u', 's']) assert.ok(result.html().includes(`<${tag}>`));
  result.editor.commands.setHeading({ level: 6 });
  assert.match(result.html(), /<h6>/);
  result.editor.commands.setParagraph(); result.editor.commands.toggleTaskList();
  assert.match(result.html(), /data-type="taskList"/);
  assert.match(result.html(), /data-type="taskItem"/); assert.match(result.html(), /data-checked="false"/);
  result.editor.commands.toggleTaskList(); result.editor.commands.toggleBulletList();
  assert.match(result.html(), /<ul><li>/);
  result.editor.commands.toggleBulletList(); result.editor.commands.toggleOrderedList();
  assert.match(result.html(), /<ol><li>/);
  result.editor.commands.toggleOrderedList(); result.editor.commands.toggleBlockquote();
  assert.match(result.html(), /<blockquote>/);
  result.editor.commands.insertTable({ rows: 3, cols: 2, withHeaderRow: true });
  assert.match(result.html(), /<table[ >]/); assert.match(result.html(), /<th/);
});
test('existing tables and task-list chrome parse without loss of content or checked state', () => {
  const result = open('<p>本文</p><ul data-type="taskList"><li data-type="taskItem" data-checked="true"><label><input type="checkbox" checked></label><div><p>完了済み</p></div></li></ul><table><tbody><tr><td colspan="2"><p>表の内容</p></td></tr></tbody></table>');
  addText(result);
  assert.match(result.html(), /data-checked="true"/);
  assert.match(result.html(), /完了済み/); assert.match(result.html(), /colspan="2"/);
  assert.match(result.html(), /表の内容/); assert.doesNotMatch(result.html(), /preserved/);
});
test('pasted active HTML is removed and unsafe link schemes are rejected', () => {
  const result = open('<p>本文</p>');
  const clean = result.editor.options.editorProps.transformPastedHTML('<p onclick="x()">貼付<img src="https://external.example/x"><a href="javascript:alert(1)">リンク</a><script>evil()</script></p>');
  assert.equal(clean, '<p>貼付リンク</p>');
  for (const href of ['javascript:alert(1)', 'data:text/html,x', '//other.example', 'java\nscript:x']) assert.equal(safeLink(href), false);
  assert.equal(safeLink('https://example.com'), true);
  assert.equal(safeLink('/workspaces/one'), true);
});
test('empty body supports rich content insertion and clear-to-empty is an explicit change', () => {
  const result = open('');
  assert.equal(result.html(), '');
  result.editor.commands.insertContent('新規本文'); assert.match(result.html(), /新規本文/);
  const nonempty = open('<p>元の本文</p>'); nonempty.editor.commands.clearContent();
  assert.equal(nonempty.changed(), true); assert.equal(nonempty.html(), '<p></p>');
});
test('title-only save forwards unchanged body, closes only after successful save', async () => {
  const calls = [];
  const original = '<pre data-language="tree"><code>└── 日本語</code></pre>';
  const view = ui(original, async (...args) => { calls.push(args); return ''; });
  const input = view.host.querySelector('textarea'); input.value = '更新後のタイトル'; input.dispatchEvent(new dom.window.Event('input'));
  view.click('Save work item'); await tick();
  assert.deepEqual(calls, [['更新後のタイトル', original, false]]);
  assert.equal(view.closes(), 1);
});
test('body save sends rendered formatting and a failed request retains title/body for explicit retry', async () => {
  const calls = [];
  const view = ui(undefined, async (...args) => { calls.push(args); return calls.length === 1 ? 'Forbidden' : ''; });
  const body = view.host.querySelector('.tiptap'); body.innerHTML = '<h2>見出し</h2><p><strong>更新した本文</strong></p>';
  body.dispatchEvent(new dom.window.InputEvent('input', { bubbles: true, inputType: 'insertText' }));
  await tick(); view.click('Save work item'); await tick();
  assert.equal(calls[0][2], true); assert.match(calls[0][1], /<h2>見出し<\/h2>/);
  assert.equal(view.closes(), 0); assert.equal(view.host.querySelector('[role=alert]').textContent, 'Forbidden');
  assert.match(body.textContent, /更新した本文/);
  view.click('Save work item'); await tick();
  assert.equal(calls.length, 2); assert.deepEqual(calls[0], calls[1]); assert.equal(view.closes(), 1);
});
test('saving disables duplicate Save and Close; composition prevents taking a partial Japanese snapshot', async () => {
  let resolve; let calls = 0;
  const view = ui(undefined, async () => { calls++; return new Promise(done => { resolve = done; }); });
  view.host.dispatchEvent(new dom.window.CompositionEvent('compositionstart', { bubbles: true }));
  view.click('Save work item'); await tick(); assert.equal(calls, 0);
  view.host.dispatchEvent(new dom.window.CompositionEvent('compositionend', { bubbles: true }));
  view.click('Save work item'); await tick(); view.click('Save work item'); view.click('Close editor');
  await tick(); assert.equal(calls, 1); assert.equal(view.closes(), 0);
  resolve(''); await tick(); assert.equal(view.closes(), 1);
});
test('two same-frame Save clicks invoke even an immediate unchanged save/close only once', async () => {
  let calls = 0;
  const view = ui(undefined, async () => { calls++; return ''; });
  view.click('Save work item'); view.click('Save work item');
  await tick(); view.click('Save work item');
  assert.equal(calls, 1); assert.equal(view.closes(), 1);
});
test('immediate repeated Close cannot pop another route during the exit animation', () => {
  const view = ui();
  view.click('Close editor'); view.handle.requestClose(); view.click('Close editor');
  assert.equal(view.closes(), 1);
});
test('block picker makes underlying editor controls inert until dismissed', () => {
  const view = ui(); view.click('Add new block');
  assert.equal(view.host.querySelector('main').inert, true);
  assert.equal(view.host.querySelector('footer').inert, true);
  view.click('Close Add new block');
  assert.equal(view.host.querySelector('main').inert, false);
});
test('tap plus opens block picker, dirty Close requires discard and never saves', async () => {
  let saves = 0;
  const view = ui(undefined, async () => { saves++; return ''; });
  view.click('Add new block');
  assert.ok(view.host.querySelector('[aria-label="Add new block"][role=dialog]'));
  view.click('Heading 2');
  assert.equal(view.host.querySelectorAll('[role=dialog]').length, 0);
  assert.ok(view.host.querySelector('.tiptap h2'));
  view.click('Close editor'); view.click('Keep editing'); assert.equal(view.closes(), 0);
  view.click('Close editor'); view.click('Discard changes');
  assert.equal(view.closes(), 1); assert.equal(saves, 0);
});
