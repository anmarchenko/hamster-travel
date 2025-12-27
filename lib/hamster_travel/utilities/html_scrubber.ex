defmodule HamsterTravel.Utilities.HtmlScrubber do
  require HtmlSanitizeEx.Scrubber.Meta
  alias HtmlSanitizeEx.Scrubber.Meta

  # Removes XML CDATA sections and comments
  Meta.remove_cdata_sections_before_scrub()
  Meta.strip_comments()

  Meta.allow_tag_with_uri_attributes("a", ["href"], ["http", "https", "mailto"])
  Meta.allow_tag_with_these_attributes("a", ["target", "rel", "class"])

  Meta.allow_tag_with_uri_attributes("img", ["src"], ["http", "https", "data"])
  Meta.allow_tag_with_these_attributes("img", ["class", "alt", "title", "width", "height"])

  # YouTube embeds
  Meta.allow_tag_with_uri_attributes("iframe", ["src"], ["http", "https"])
  Meta.allow_tag_with_these_attributes("iframe", ["class", "width", "height", "frameborder", "allowfullscreen"])

  # Text formatting
  Meta.allow_tag_with_these_attributes("p", ["class"])
  Meta.allow_tag_with_these_attributes("span", ["class"])
  Meta.allow_tag_with_these_attributes("br", [])
  Meta.allow_tag_with_these_attributes("strong", [])
  Meta.allow_tag_with_these_attributes("b", [])
  Meta.allow_tag_with_these_attributes("em", [])
  Meta.allow_tag_with_these_attributes("i", [])
  Meta.allow_tag_with_these_attributes("u", [])
  Meta.allow_tag_with_these_attributes("s", [])
  Meta.allow_tag_with_these_attributes("strike", [])
  Meta.allow_tag_with_these_attributes("blockquote", [])
  Meta.allow_tag_with_these_attributes("code", [])
  Meta.allow_tag_with_these_attributes("pre", [])
  Meta.allow_tag_with_these_attributes("div", ["class"])

  # Lists and Tasks
  Meta.allow_tag_with_these_attributes("ul", ["class", "data-task-list"])
  Meta.allow_tag_with_these_attributes("ol", ["class"])
  Meta.allow_tag_with_these_attributes("li", ["class", "data-checked", "data-type"])
  Meta.allow_tag_with_these_attributes("label", [])
  Meta.allow_tag_with_these_attributes("input", ["type", "checked", "disabled"])

  # Strip everything else
  Meta.strip_everything_not_covered()
end
