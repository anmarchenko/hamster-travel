const NOTEBOOK_SELECTOR = '[data-offline-notebook]';

function showNote(notebook, noteId) {
  const template = noteId && document.getElementById(`offline-note-template-${noteId}`);
  const reader = notebook.querySelector('[data-offline-note-reader]');
  const content = reader.querySelector('[data-offline-note-content]');

  reader.hidden = !template;
  content.dataset.noteId = template ? noteId : '';
  content.replaceChildren();
  if (template) content.append(template.content.cloneNode(true));
}

export function initOfflineNotes() {
  let readOnly = false;

  window.addEventListener('hamster:offline-read-only', (event) => {
    if (readOnly === event.detail.readOnly) return;

    readOnly = event.detail.readOnly;
    document.querySelectorAll(NOTEBOOK_SELECTOR).forEach((notebook) => {
      showNote(notebook, readOnly ? notebook.dataset.readingNote : null);
    });
  });

  document.addEventListener('click', (event) => {
    if (!readOnly) return;

    const open = event.target.closest?.('[data-open-offline-note]');
    const back = event.target.closest?.('[data-back-offline-note]');
    const notebook = (open || back)?.closest(NOTEBOOK_SELECTOR);
    if (!notebook) return;

    if (open) {
      showNote(notebook, open.dataset.openOfflineNote);
      notebook.querySelector('[data-offline-note-content] h2')?.focus();
    } else {
      const { noteId } = notebook.querySelector('[data-offline-note-content]').dataset;
      showNote(notebook, null);
      notebook.querySelector(`[data-open-offline-note="${CSS.escape(noteId)}"]`)?.focus();
    }
  });
}

export function updateOfflineNoteTemplate(from, to) {
  // LiveView's DOM patch walks element children, while a template uses a fragment.
  if (from.matches('template[data-offline-note-template]') && !from.content.isEqualNode(to.content)) {
    from.content.replaceChildren(to.content.cloneNode(true));
  }
}
