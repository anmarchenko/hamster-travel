import { Editor } from "@tiptap/core";
import StarterKit from "@tiptap/starter-kit";
import Underline from "@tiptap/extension-underline";
import Link from "@tiptap/extension-link";
import { Markdown } from "@tiptap/markdown";

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
          heading: false,
          paragraph: {
            HTMLAttributes: {
              class: "leading-relaxed mb-1.5",
            },
          },
          bulletList: {
            HTMLAttributes: {
              class: "list-disc pl-5 mb-1.5 space-y-1",
            },
          },
          orderedList: {
            HTMLAttributes: {
              class: "list-decimal pl-5 mb-1.5 space-y-1",
            },
          },
          listItem: {
            HTMLAttributes: {
              class: "mb-1",
            },
          },
          bold: {
            HTMLAttributes: {
              class: "font-semibold",
            },
          },
          italic: {
            HTMLAttributes: {
              class: "italic",
            },
          },
        }),
        Link.configure({
          openOnClick: false,
          HTMLAttributes: {
            class:
              "text-primary-600 dark:text-primary-400 underline underline-offset-2",
          },
        }),
        Underline.configure({
          HTMLAttributes: {
            class: "underline decoration-gray-400 dark:decoration-gray-300",
          },
        }),
        Markdown.configure({
          indentation: { style: "space", size: 2 },
          markedOptions: {
            gfm: true,
            breaks: false,
            mangle: false,
            headerIds: false,
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

    // Enable markdown-aware paste handling
    this.handleMarkdownPaste(editorTarget);

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
          case "underline":
            this.editor.chain().focus().toggleUnderline().run();
            break;
          case "link":
            this.promptForLink();
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
        case "underline":
          isActive = this.editor.isActive("underline");
          break;
        case "link":
          isActive = this.editor.isActive("link");
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

  promptForLink() {
    const previousUrl = this.editor.getAttributes("link").href || "";
    const url = prompt("Enter URL", previousUrl || "https://");

    if (url === null) {
      return;
    }

    if (url === "") {
      this.editor.chain().focus().extendMarkRange("link").unsetLink().run();
      return;
    }

    this.editor
      .chain()
      .focus()
      .extendMarkRange("link")
      .setLink({ href: url })
      .run();
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

  handleMarkdownPaste(editorTarget) {
    editorTarget.addEventListener("paste", (event) => {
      if (!this.editor?.storage?.markdown) {
        return;
      }

      const text = event.clipboardData?.getData("text/plain");
      const html = event.clipboardData?.getData("text/html");

      if (!text || (html && html.trim() !== "")) {
        return;
      }

      event.preventDefault();
      this.editor.commands.insertContent(text, { contentType: "markdown" });
    });
  },

  beforeDestroy() {
    if (this.editor) {
      this.editor.destroy();
    }
  },
};

export default { FormattedTextArea };
