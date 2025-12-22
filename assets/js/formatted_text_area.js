import { Editor } from "@tiptap/core";
import StarterKit from "@tiptap/starter-kit";

const FormattedTextArea = {
  mounted() {
    const placeholder = this.el.dataset.placeholder || "";
    const editorTarget = this.el.querySelector("[data-editor-target]");
    const hiddenInput = this.el.querySelector("[data-editor-input]");

    // Initialize Tiptap editor
    this.editor = new Editor({
      element: editorTarget,
      extensions: [
        StarterKit.configure({
          heading: {
            levels: [1, 2, 3],
            HTMLAttributes: {
              class:
                "text-gray-900 dark:text-gray-100 font-semibold tracking-tight mt-5 mb-3 leading-tight",
            },
          },
          paragraph: {
            HTMLAttributes: {
              class: "text-gray-700 dark:text-gray-300 leading-relaxed mb-3",
            },
          },
          bulletList: {
            HTMLAttributes: {
              class: "list-disc pl-5 mb-3 text-gray-700 dark:text-gray-300 space-y-1",
            },
          },
          orderedList: {
            HTMLAttributes: {
              class: "list-decimal pl-5 mb-3 text-gray-700 dark:text-gray-300 space-y-1",
            },
          },
          listItem: {
            HTMLAttributes: {
              class: "mb-1",
            },
          },
          bold: {
            HTMLAttributes: {
              class: "font-semibold text-gray-900 dark:text-gray-100",
            },
          },
          italic: {
            HTMLAttributes: {
              class: "italic text-gray-800 dark:text-gray-200",
            },
          },
        }),
      ],
      content: hiddenInput.value || "",
      editorProps: {
        attributes: {
          class: "focus:outline-none",
        },
      },
      onCreate: ({ editor }) => {
        // Set initial content from hidden input
        if (hiddenInput.value && hiddenInput.value !== editor.getHTML()) {
          editor.commands.setContent(hiddenInput.value, false);
        }
      },
      onUpdate: ({ editor }) => {
        // Update hidden input when content changes
        const html = editor.getHTML();
        hiddenInput.value = html;

        // Dispatch input event to notify LiveView
        hiddenInput.dispatchEvent(new Event("input", { bubbles: true }));
      },
    });

    // Add placeholder text if content is empty
    if (
      !hiddenInput.value ||
      hiddenInput.value.trim() === "" ||
      hiddenInput.value === "<p></p>"
    ) {
      editorTarget.setAttribute("data-placeholder", placeholder);
    }

    // Set up toolbar buttons
    this.setupToolbar();

    // Handle clicks outside editor to maintain focus behavior
    this.handleFocusEvents();
  },

  setupToolbar() {
    const toolbar = this.el.querySelector(".toolbar");
    const buttons = toolbar.querySelectorAll("[data-command]");

    buttons.forEach((button) => {
      button.addEventListener("click", (e) => {
        e.preventDefault();
        const command = button.dataset.command;

        switch (command) {
          case "bold":
            this.editor.chain().focus().toggleBold().run();
            break;
          case "italic":
            this.editor.chain().focus().toggleItalic().run();
            break;
          case "heading2":
            this.editor.chain().focus().toggleHeading({ level: 2 }).run();
            break;
          case "heading3":
            this.editor.chain().focus().toggleHeading({ level: 3 }).run();
            break;
          case "bulletList":
            this.editor.chain().focus().toggleBulletList().run();
            break;
          case "orderedList":
            this.editor.chain().focus().toggleOrderedList().run();
            break;
        }

        this.updateButtonStates();
      });
    });

    // Update button states when selection changes
    this.editor.on("selectionUpdate", () => {
      this.updateButtonStates();
    });

    // Initial button state update
    this.updateButtonStates();
  },

  updateButtonStates() {
    const toolbar = this.el.querySelector(".toolbar");
    const buttons = toolbar.querySelectorAll("[data-command]");

    buttons.forEach((button) => {
      const command = button.dataset.command;
      let isActive = false;

      switch (command) {
        case "bold":
          isActive = this.editor.isActive("bold");
          break;
        case "italic":
          isActive = this.editor.isActive("italic");
          break;
        case "heading2":
          isActive = this.editor.isActive("heading", { level: 2 });
          break;
        case "heading3":
          isActive = this.editor.isActive("heading", { level: 3 });
          break;
        case "bulletList":
          isActive = this.editor.isActive("bulletList");
          break;
        case "orderedList":
          isActive = this.editor.isActive("orderedList");
          break;
      }

      if (isActive) {
        button.classList.add("active");
      } else {
        button.classList.remove("active");
      }
    });
  },

  handleFocusEvents() {
    const editorTarget = this.el.querySelector("[data-editor-target]");

    // Update placeholder visibility based on content
    this.editor.on("update", () => {
      const isEmpty = this.editor.isEmpty;
      const placeholder = this.el.dataset.placeholder;

      if (isEmpty && placeholder) {
        editorTarget.setAttribute("data-placeholder", placeholder);
      } else {
        editorTarget.removeAttribute("data-placeholder");
      }
    });

    // Handle focus events
    this.editor.on("focus", () => {
      this.el.classList.add("focused");
    });

    this.editor.on("blur", () => {
      this.el.classList.remove("focused");
    });
  },

  beforeDestroy() {
    if (this.editor) {
      this.editor.destroy();
    }
  },
};

export default { FormattedTextArea };
