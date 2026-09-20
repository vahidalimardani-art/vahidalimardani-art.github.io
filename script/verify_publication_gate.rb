require "fileutils"
require "pathname"

fixtures = {
  "_works/ci-unpublished-work.md" => <<~MARKDOWN,
    ---
    title: CI_UNPUBLISHED_WORK_SHOULD_NOT_APPEAR
    date: 2099-01-01
    category: Test
    summary: This unpublished artwork must never be written to the public site.
    cover: /media/lim1-2.jpg
    published: false
    ---
    This body must not be published.
  MARKDOWN
  "_notes/ci-unpublished-note.md" => <<~MARKDOWN
    ---
    title: CI_UNPUBLISHED_NOTE_SHOULD_NOT_APPEAR
    date: 2099-01-01
    published: false
    ---
    This body must not be published.
  MARKDOWN
}

destination = Pathname(".site-publication-gate")

begin
  fixtures.each do |path, content|
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  FileUtils.rm_rf(destination)
  built = system({ "JEKYLL_ENV" => "production" }, "bundle", "exec", "jekyll", "build", "--trace", "--destination", destination.to_s)
  abort("Jekyll production build failed during publication-gate test.") unless built

  output = {
    homepage: destination.join("index.html"),
    works: destination.join("works/index.html"),
    work_detail: destination.join("works/ci-unpublished-work/index.html"),
    notes: destination.join("notes/index.html"),
    note_detail: destination.join("notes/ci-unpublished-note/index.html")
  }

  errors = []
  {
    homepage: "CI_UNPUBLISHED_WORK_SHOULD_NOT_APPEAR",
    works: "CI_UNPUBLISHED_WORK_SHOULD_NOT_APPEAR",
    notes: "CI_UNPUBLISHED_NOTE_SHOULD_NOT_APPEAR"
  }.each do |page, marker|
    errors << "#{output.fetch(page)} contains #{marker}" if output.fetch(page).read.include?(marker)
  end

  [:work_detail, :note_detail].each do |page|
    errors << "#{output.fetch(page)} was generated for unpublished content" if output.fetch(page).exist?
  end

  abort(errors.join("\n")) unless errors.empty?
  puts "Verified production builds omit unpublished collection indexes and detail pages."
ensure
  fixtures.each_key { |path| FileUtils.rm_f(path) }
  FileUtils.rm_rf(destination)
end
