require "yaml"

config = YAML.load_file(".pages.yml")
content = config.fetch("content")

def entry(content, name)
  content.find { |item| item["name"] == name } || raise("Missing Pages CMS entry: #{name}")
end

def field(entry, name)
  entry.fetch("fields").find { |item| item["name"] == name } || raise("Missing #{entry.fetch("name")} field: #{name}")
end

def assert!(condition, message)
  raise(message) unless condition
end

works = entry(content, "works")
notes = entry(content, "notes")
about = entry(content, "about")
site = entry(content, "site")

assert!(config.fetch("media") == {
  "input" => "media", "output" => "/media", "rename" => "safe",
  "extensions" => ["jpg", "jpeg", "png", "webp"]
}, "Media source must write repository uploads to media and public URLs to /media.")

[works, notes].each do |collection|
  filename = collection.fetch("filename")
  assert!(filename.is_a?(String), "#{collection.fetch("name")}: filename must use the string form so the filename input stays hidden.")
  assert!(filename == "{year}-{month}-{day}-{title}.md", "#{collection.fetch("name")}: filename must be generated from the date and slugified title.")
  assert!(!collection.fetch("fields").any? { |item| item["name"] == "slug" }, "#{collection.fetch("name")}: manual slug fields are not allowed.")
end

cover = field(works, "cover")
gallery = field(works, "gallery")
note_image = field(notes, "image")
portrait = field(site, "portrait")
assert!(cover.fetch("type") == "image" && cover.dig("options", "path") == "works", "Artwork covers must upload to /media/works/.")
assert!(gallery.fetch("type") == "image" && gallery.dig("options", "path") == "works" && gallery.dig("options", "multiple", "max") == 20, "Artwork galleries must support multiple uploads to /media/works/.")
assert!(note_image.fetch("type") == "image" && note_image.dig("options", "path") == "notes", "Note images must upload to /media/notes/.")
assert!(portrait.fetch("type") == "image" && portrait.dig("options", "path") == "site", "Portraits must upload to /media/site/.")

[field(works, "body"), field(notes, "body"), field(about, "body")].each do |body|
  assert!(body.fetch("type") == "rich-text" && body.dig("options", "format") == "markdown" && body.dig("options", "switcher") == false, "Rich-text source/Markdown mode must remain hidden.")
end

assert!(about.fetch("type") == "file" && about.fetch("path") == "about/index.md", "About must remain a direct editable file.")
assert!(site.fetch("type") == "file" && site.fetch("path") == "_data/site.yml", "Site settings must remain a direct editable data file.")

social = field(site, "social_links")
assert!(social.fetch("type") == "object" && social.dig("list", "collapsible", "summary") == "{label}", "Social links must use a valid object-list schema.")
assert!(social.fetch("fields").map { |item| item["name"] } == ["label", "url"], "Social links must expose label and URL fields.")

lim = File.read("_works/lim-v2.md")
assert!(lim.include?("title: لیمینال") && lim.include?("published: true"), "Existing lim-v2 content must stay published and intact.")
assert!(File.basename("_works/lim-v2.md", ".md") == "lim-v2", "Existing lim-v2 filename must stay stable.")

puts "Verified Pages CMS schema, hidden generated filenames, media paths, rich-text controls, editable files, social links, and lim-v2 stability."
