import { Editor } from "@tiptap/core";
import StarterKit from "@tiptap/starter-kit";
import Underline from "@tiptap/extension-underline";
import Link from "@tiptap/extension-link";
import { Markdown } from "@tiptap/markdown";
import TaskList from "@tiptap/extension-task-list";
import TaskItem from "@tiptap/extension-task-item";
import Youtube from "@tiptap/extension-youtube";
import Image from "@tiptap/extension-image";

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
        TaskList.configure({
          HTMLAttributes: {
            class: "list-none pl-0 flex flex-col",
            "data-task-list": "true",
          },
        }),
        TaskItem.configure({
          nested: false,
          HTMLAttributes: {
            class: "inline-flex items-center gap-2 shrink-0 cursor-default",
          },
        }),
        Youtube.configure({
          addPasteHandler: false,
          controls: true,
          allowFullscreen: true,
          width: 640,
          height: 360,
          HTMLAttributes: {
            class: "formatted-video",
          },
        }),
        Image.configure({
          allowBase64: false,
          HTMLAttributes: {
            class: "formatted-image",
            loading: "lazy",
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

    // Prevent task list checkboxes from triggering parent form phx-change events
    // This fixes an issue where clicking a task checkbox in a form with phx-change
    // would cause the change to be reverted due to the form update cycle.
    const stopPropagationForCheckboxes = (e) => {
      if (e.target.matches('input[type="checkbox"]')) {
        e.stopPropagation();
      }
    };

    this.el.addEventListener("change", stopPropagationForCheckboxes);
    this.el.addEventListener("input", stopPropagationForCheckboxes);
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
          case "image":
            this.promptForImage();
            break;
          case "bulletList":
            this.editor.chain().focus().toggleBulletList().run();
            break;
          case "orderedList":
            this.editor.chain().focus().toggleOrderedList().run();
            break;
          case "taskList":
            this.editor.chain().focus().toggleTaskList().run();
            break;
          case "youtube":
            this.promptForYoutube();
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
        case "image":
          isActive = this.editor.isActive("image");
          break;
        case "bulletList":
          isActive = this.editor.isActive("bulletList");
          break;
        case "orderedList":
          isActive = this.editor.isActive("orderedList");
          break;
        case "taskList":
          isActive = this.editor.isActive("taskList");
          break;
        case "youtube":
          isActive = this.editor.isActive("youtube");
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

  promptForImage() {
    const url = prompt("Enter image URL", "https://");

    if (url === null) {
      return;
    }

    const sanitizedUrl = sanitizeImageUrl(url);

    if (!sanitizedUrl) {
      alert("Please enter a valid image URL (http/https).");
      return;
    }

    this.editor.chain().focus().setImage({ src: sanitizedUrl }).run();
  },

  promptForYoutube() {
    const url = prompt("Enter YouTube URL", "https://www.youtube.com/watch?v=");

    if (url === null) {
      return;
    }

    const embedUrl = buildYoutubeEmbedUrl(url);

    if (!embedUrl) {
      alert("Please enter a valid YouTube URL.");
      return;
    }

    this.editor
      .chain()
      .focus()
      .setYoutubeVideo({ src: embedUrl })
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
    const handlePaste = (event) => {
      if (!this.editor?.storage?.markdown) {
        return;
      }

      const text = event.clipboardData?.getData("text/plain");
      const html = event.clipboardData?.getData("text/html");

      if (
        !text ||
        (html && html.trim() !== "") ||
        looksLikePlainUrl(text) ||
        !looksLikeMarkdown(text)
      ) {
        return;
      }

      event.preventDefault();
      event.stopPropagation();
      if (event.stopImmediatePropagation) {
        event.stopImmediatePropagation();
      }

      this.editor.commands.insertContent(text, { contentType: "markdown" });
    };

    editorTarget.addEventListener("paste", handlePaste, true);
    this.cleanupMarkdownPaste = () =>
      editorTarget.removeEventListener("paste", handlePaste, true);
  },

  beforeDestroy() {
    if (this.editor) {
      this.editor.destroy();
    }

    if (this.cleanupMarkdownPaste) {
      this.cleanupMarkdownPaste();
      this.cleanupMarkdownPaste = null;
    }
  },
};

function looksLikePlainUrl(text) {
  return /^https?:\/\/\S+$/i.test(text.trim());
}

function looksLikeMarkdown(text) {
  const trimmed = text.trim();

  const markdownPatterns = [
    /^\s{0,3}(#{1,6})\s+\S+/, // headings
    /\*\*[^*]+\*\*/, // bold
    /__[^_]+__/, // bold underscores
    /\*[^*]+\*/, // italics
    /_[^_]+_/, // italics underscores
    /`{1,3}[^`]+`{1,3}/, // inline code or fenced
    /^(\s*(-|\d+\.)\s+)/m, // lists
    /^>\s+\S+/m, // blockquote
    /!\[[^\]]*]\([^)]+\)/, // images
    /\[[^\]]+]\([^)]+\)/, // links
    /-{3,}/, // horizontal rule
    /^(\s*(-|\d+\.)\s+\[( |x|X)\]\s+)/m, // task list items
  ];

  return markdownPatterns.some((regex) => regex.test(trimmed));
}

function buildYoutubeEmbedUrl(url) {
  if (!url) {
    return null;
  }

  let parsed;

  try {
    parsed = new URL(url.trim());
  } catch (_error) {
    return null;
  }

  const hostname = parsed.hostname.replace(/^www\./i, "").toLowerCase();
  let videoId = null;

  if (hostname === "youtu.be") {
    videoId = parsed.pathname.replace("/", "");
  } else if (hostname.endsWith("youtube.com")) {
    if (parsed.pathname.startsWith("/watch")) {
      videoId = parsed.searchParams.get("v");
    } else if (parsed.pathname.startsWith("/shorts/")) {
      videoId = parsed.pathname.split("/")[2];
    } else if (parsed.pathname.startsWith("/embed/")) {
      videoId = parsed.pathname.split("/")[2];
    } else {
      videoId = parsed.pathname.replace("/", "");
    }
  }

  const sanitizedId = sanitizeYoutubeId(videoId);

  if (!sanitizedId) {
    return null;
  }

  return `https://www.youtube.com/embed/${sanitizedId}`;
}

function sanitizeYoutubeId(value) {
  if (!value) {
    return null;
  }

  const match = value.match(/[a-zA-Z0-9_-]{11}/);
  return match ? match[0] : null;
}

function sanitizeImageUrl(url) {
  if (!url) {
    return null;
  }

  let parsed;

  try {
    parsed = new URL(url.trim());
  } catch (_error) {
    return null;
  }

  const protocol = parsed.protocol.toLowerCase();

  if (protocol !== "http:" && protocol !== "https:") {
    return null;
  }

  return parsed.toString();
}

export default { FormattedTextArea };
