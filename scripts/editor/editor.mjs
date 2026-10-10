import { createDocumentEditor, safeLink } from './document.mjs';

const icons = {
  plus: '<path d="M12 5v14M5 12h14"/>', close: '<path d="m6 6 12 12M18 6 6 18"/>',
  undo: '<path d="m9 5-5 5 5 5M4 10h9a6 6 0 0 1 0 12"/>',
  redo: '<path d="m15 5 5 5-5 5M20 10h-9a6 6 0 0 0 0 12"/>',
  link: '<path d="m10 13 4-4M8 15l-2 2a4 4 0 0 1-6-6l5-5a4 4 0 0 1 6 0M16 9l2-2a4 4 0 0 1 6 6l-5 5a4 4 0 0 1-6 0" transform="translate(1 0) scale(.9)"/>',
  keyboard: '<rect x="2" y="3" width="20" height="13" rx="2"/><path d="M6 7h1m3 0h1m3 0h1m3 0h1M6 11h1m3 0h1m3 0h1m3 0h1M8 14h8m-7 6 3 3 3-3"/>',
};
function icon(name) {
  return `<svg viewBox="0 0 24 24" aria-hidden="true" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">${icons[name]}</svg>`;
}
function button(label, content, action, className = '') {
  const el = document.createElement('button');
  el.type = 'button'; el.className = className;
  el.setAttribute('aria-label', label); el.title = label;
  el.innerHTML = content; // Only trusted, static UI icons/labels.
  el.addEventListener('click', action);
  return el;
}

/** Public bridge: text/HTML in, asynchronous save result out. No credentials,
 * network calls or Flutter store are exposed to the editable document. */
export function mountEditor(host, title, html, identifier, focus, dark, scale, onSave, onClose) {
  host.className = `plane-content-editor${dark ? ' dark' : ''}`;
  host.setAttribute('role', 'dialog');
  host.setAttribute('aria-modal', 'true');
  host.setAttribute('aria-label', 'Edit work item');
  host.style.setProperty('--text-scale', String(scale));
  host.innerHTML = '<div class="editor-grip"></div><header></header><p class="save-error" role="alert" hidden></p><main><textarea class="item-title" aria-label="Work item title" placeholder="Title" maxlength="255" rows="1"></textarea><div class="item-body"></div></main><footer role="toolbar" aria-label="Text formatting"></footer>';
  const header = host.querySelector('header');
  const main = host.querySelector('main');
  const titleInput = host.querySelector('.item-title');
  const error = host.querySelector('.save-error');
  const footer = host.querySelector('footer');
  titleInput.value = title;
  let busy = false, disposed = false, closing = false, panel = null, composing = false;
  let save;
  const tools = [];
  const documentEditor = createDocumentEditor(host.querySelector('.item-body'), html, refresh);
  const { editor } = documentEditor;
  const close = button('Close editor', icon('close'), requestClose, 'square-button');
  const itemId = document.createElement('span'); itemId.textContent = identifier;
  save = button('Save work item', 'Save', saveContent, 'save-button');
  header.append(close, itemId, save);

  function tool(label, content, command, active) {
    const el = button(label, content, () => {
      if (busy || composing) return;
      command(); refresh();
    }, 'tool-button');
    // Retain the ProseMirror selection/caret and the iPhone keyboard.
    el.addEventListener('pointerdown', event => event.preventDefault());
    tools.push({ el, label, active }); footer.append(el);
  }
  tool('Add new block', icon('plus'), blocks);
  tool('Undo', icon('undo'), () => editor.chain().focus().undo().run());
  tool('Redo', icon('redo'), () => editor.chain().focus().redo().run());
  tool('Bold', '<b>B</b>', () => editor.chain().focus().toggleBold().run(), 'bold');
  tool('Italic', '<i>I</i>', () => editor.chain().focus().toggleItalic().run(), 'italic');
  tool('Underline', '<u>U</u>', () => editor.chain().focus().toggleUnderline().run(), 'underline');
  tool('Strikethrough', '<s>S</s>', () => editor.chain().focus().toggleStrike().run(), 'strike');
  tool('Link', icon('link'), links, 'link');
  tool('Dismiss keyboard', icon('keyboard'), () => document.activeElement?.blur());
  editor.on('selectionUpdate', refresh);
  editor.on('transaction', refresh);
  host.addEventListener('compositionstart', compositionStart);
  host.addEventListener('compositionend', compositionEnd);
  host.addEventListener('keydown', keyboard);
  titleInput.addEventListener('input', titleChanged);

  function compositionStart() { composing = true; refresh(); }
  function compositionEnd() { composing = false; refresh(); }
  function resizeTitle() {
    titleInput.style.height = 'auto';
    titleInput.style.height = `${titleInput.scrollHeight}px`;
  }
  function titleChanged() { resizeTitle(); refresh(); }
  function dirty() { return titleInput.value.trim() !== title || documentEditor.changed(); }
  function refresh() {
    if (!save) return;
    save.disabled = busy || composing || !titleInput.value.trim();
    save.textContent = busy ? 'Saving…' : 'Save';
    close.disabled = busy;
    titleInput.readOnly = busy;
    for (const { el, label, active } of tools) {
      el.disabled = busy || composing ||
        (label === 'Undo' && !editor.can().undo()) || (label === 'Redo' && !editor.can().redo());
      if (active) el.setAttribute('aria-pressed', String(editor.isActive(active)));
    }
  }
  function closePanel(refocus = true) {
    if (!panel) return;
    panel.remove(); panel = null;
    for (const child of host.children) child.inert = false;
    if (refocus) editor.commands.focus();
  }
  function newPanel(label) {
    closePanel(false); document.activeElement?.blur();
    for (const child of host.children) child.inert = true;
    panel = document.createElement('section'); panel.className = 'editor-panel';
    panel.setAttribute('role', 'dialog'); panel.setAttribute('aria-label', label); panel.setAttribute('aria-modal', 'true');
    const panelHeader = document.createElement('header');
    const name = document.createElement('h2'); name.textContent = label;
    panelHeader.append(button(`Close ${label}`, icon('close'), () => closePanel(), 'square-button'), name);
    const content = document.createElement('div'); content.className = 'panel-content';
    panel.append(panelHeader, content); host.append(panel);
    return content;
  }
  function blocks() {
    const content = newPanel('Add new block');
    function group(label, options) {
      const heading = document.createElement('h3'); heading.textContent = label;
      const grid = document.createElement('div'); grid.className = 'block-grid';
      for (const [name, symbol, action] of options) {
        const el = button(name, `<span aria-hidden="true">${symbol}</span>${name}`, () => {
          closePanel(false); action(); editor.commands.focus(); refresh();
        }, 'block-button');
        grid.append(el);
      }
      content.append(heading, grid);
    }
    group('Text', [['Text', 'Aa', () => editor.chain().focus().setParagraph().run()]]);
    group('Heading', [1, 2, 3, 4, 5, 6].map(level => [`Heading ${level}`, `H${level}`, () => editor.chain().focus().setHeading({ level }).run()]));
    group('List & Table', [
      ['Bullet List', '☷', () => editor.chain().focus().toggleBulletList().run()],
      ['Numbered List', '≡', () => editor.chain().focus().toggleOrderedList().run()],
      ['To-do List', '☑', () => editor.chain().focus().toggleTaskList().run()],
      ['Table', '▦', () => editor.chain().focus().insertTable({ rows: 3, cols: 2, withHeaderRow: true }).run()],
    ]);
    group('Others', [
      ['Divider', '―', () => editor.chain().focus().setHorizontalRule().run()],
      ['Quote', '❞', () => editor.chain().focus().toggleBlockquote().run()],
      ['Code', '&lt;/&gt;', () => editor.chain().focus().setCodeBlock({ language: null }).run()],
      ['Mermaid', '◇', () => editor.chain().focus().setCodeBlock({ language: 'mermaid' }).run()],
      ['File tree', '⌘', () => editor.chain().focus().setCodeBlock({ language: 'tree' }).run()],
    ]);
    if (editor.isActive('table')) group('Edit table', [
      ['Add row', '+', () => editor.chain().focus().addRowAfter().run()],
      ['Add column', '+', () => editor.chain().focus().addColumnAfter().run()],
      ['Delete row', '−', () => editor.chain().focus().deleteRow().run()],
      ['Delete column', '−', () => editor.chain().focus().deleteColumn().run()],
    ]);
    panel.querySelector('button').focus();
  }
  function links() {
    const content = newPanel('Link');
    const label = document.createElement('label'); label.textContent = 'URL';
    const input = document.createElement('input'); input.type = 'url'; input.placeholder = 'https://';
    input.setAttribute('aria-label', 'Link URL'); input.value = editor.getAttributes('link').href ?? '';
    const message = document.createElement('p'); message.className = 'link-error'; message.setAttribute('role', 'alert');
    const apply = button('Apply link', 'Apply', () => {
      const href = input.value.trim();
      if (href && !safeLink(href)) { message.textContent = 'Enter an http, https or mailto link.'; return; }
      closePanel(false);
      const chain = editor.chain().focus().extendMarkRange('link');
      if (href) {
        if (editor.state.selection.empty && !editor.isActive('link'))
          chain.insertContent({ type: 'text', text: href, marks: [{ type: 'link', attrs: { href } }] }).run();
        else chain.setLink({ href }).run();
      } else chain.unsetLink().run();
      refresh();
    }, 'primary-button');
    label.append(input); content.append(label, message, apply);
    input.focus();
  }
  function requestClose() {
    if (busy || disposed) return;
    if (panel) { closePanel(); return; }
    if (!dirty()) { finishClose(); return; }
    const content = newPanel('Discard changes?');
    const text = document.createElement('p'); text.textContent = 'Your changes have not been saved.';
    content.append(text,
      button('Keep editing', 'Keep editing', () => closePanel(), 'primary-button'),
      button('Discard changes', 'Discard', () => { closePanel(false); finishClose(); }, 'discard-button'));
    panel.querySelector('button').focus();
  }
  function finishClose() {
    if (closing || disposed) return;
    closing = true; busy = true; editor.setEditable(false); refresh(); onClose();
  }
  function keyboard(event) {
    if (composing || event.isComposing) return;
    if (event.key === 'Escape') { event.preventDefault(); requestClose(); }
    if (event.key !== 'Tab') return;
    const region = panel ?? host;
    const choices = [...region.querySelectorAll('button:not(:disabled),input,textarea,[contenteditable="true"]')];
    const first = choices[0], last = choices.at(-1);
    if (event.shiftKey && document.activeElement === first) { event.preventDefault(); last?.focus(); }
    if (!event.shiftKey && document.activeElement === last) { event.preventDefault(); first?.focus(); }
  }
  async function saveContent() {
    if (busy || composing || disposed) return;
    // Claim the save synchronously, including unchanged/immediately successful
    // saves, and hold it through the modal's closing animation.
    busy = true; refresh();
    titleInput.blur(); editor.view.dom.blur();
    // Commit the browser's composition/DOM observer before taking the snapshot.
    await new Promise(resolve => requestAnimationFrame(resolve));
    if (disposed) return;
    if (composing) { busy = false; refresh(); return; }
    editor.view.domObserver.flush();
    const name = titleInput.value.trim();
    if (!name || name.length > 255) { busy = false; refresh(); error.hidden = false; error.textContent = 'Enter a title of 1–255 characters.'; return; }
    busy = true; error.hidden = true; editor.setEditable(false); refresh();
    try {
      const message = await onSave(name, documentEditor.html(), documentEditor.changed());
      if (disposed) return;
      if (!message) { finishClose(); return; }
      error.textContent = message;
    } catch { if (!disposed) error.textContent = 'Could not save. Your changes are still here. Please try again.'; }
    if (!disposed) {
      error.hidden = false; busy = false; editor.setEditable(true); refresh();
    }
  }
  // visualViewport handles the iPhone/PWA keyboard, including when Flutter does
  // not report a viewInset for an HTML contenteditable. Scroll stays in <main>.
  function resize() {
    if (disposed) return;
    const rect = host.getBoundingClientRect();
    const viewport = window.visualViewport;
    const bottom = viewport ? viewport.offsetTop + viewport.height : window.innerHeight;
    // Flutter animates the modal's transform without resizing its HTML view.
    // Use its resting position during entrance, so the first keyboard toolbar
    // measurement cannot be stuck halfway up the sheet after that animation.
    const top = Math.min(rect.top, Math.max(0, window.innerHeight - rect.height));
    host.style.setProperty('--editor-height', `${Math.max(120, Math.min(rect.height, bottom - top))}px`);
    resizeTitle();
  }
  const observer = new ResizeObserver(resize); observer.observe(host);
  window.visualViewport?.addEventListener('resize', resize);
  window.visualViewport?.addEventListener('scroll', resize);
  const frame = requestAnimationFrame(() => {
    resize(); refresh();
    if (focus === 'title') titleInput.focus(); else editor.commands.focus();
  });
  document.fonts?.ready.then(() => { if (!disposed) resizeTitle(); });
  return {
    requestClose,
    destroy() {
      disposed = true; cancelAnimationFrame(frame); observer.disconnect();
      window.visualViewport?.removeEventListener('resize', resize);
      window.visualViewport?.removeEventListener('scroll', resize);
      host.removeEventListener('compositionstart', compositionStart);
      host.removeEventListener('compositionend', compositionEnd);
      host.removeEventListener('keydown', keyboard);
      editor.destroy(); host.replaceChildren();
    },
  };
}

globalThis.planeMountWorkItemEditor = mountEditor;
