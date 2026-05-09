defmodule HamsterTravel.Utilities.HtmlScrubber do
  use HtmlSanitizeEx

  allow_tag_with_uri_attributes("a", ["href"], ["http", "https", "mailto"])
  allow_tag_with_these_attributes("a", ["target", "rel", "class"])

  allow_tag_with_uri_attributes("img", ["src"], ["http", "https", "data"])
  allow_tag_with_these_attributes("img", ["class", "alt", "title", "width", "height"])

  # YouTube embeds
  allow_tag_with_uri_attributes("iframe", ["src"], ["http", "https"])

  allow_tag_with_these_attributes("iframe", [
    "class",
    "width",
    "height",
    "frameborder",
    "allowfullscreen"
  ])

  # Text formatting
  allow_tag_with_these_attributes("p", ["class"])
  allow_tag_with_these_attributes("span", ["class"])
  allow_tag_with_these_attributes("br", [])
  allow_tag_with_these_attributes("strong", [])
  allow_tag_with_these_attributes("b", [])
  allow_tag_with_these_attributes("em", [])
  allow_tag_with_these_attributes("i", [])
  allow_tag_with_these_attributes("u", [])
  allow_tag_with_these_attributes("s", [])
  allow_tag_with_these_attributes("strike", [])
  allow_tag_with_these_attributes("blockquote", [])
  allow_tag_with_these_attributes("code", [])
  allow_tag_with_these_attributes("pre", [])
  allow_tag_with_these_attributes("div", ["class"])

  # Lists and Tasks
  allow_tag_with_these_attributes("ul", ["class", "data-task-list"])
  allow_tag_with_these_attributes("ol", ["class"])
  allow_tag_with_these_attributes("li", ["class", "data-checked", "data-type"])
  allow_tag_with_these_attributes("label", [])
  allow_tag_with_these_attributes("input", ["type", "checked", "disabled"])
end
