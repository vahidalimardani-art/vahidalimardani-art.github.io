require "nokogiri"
require "pathname"

root = Pathname("_site").realpath
errors = []

Dir.glob("_site/**/*.html").each do |file|
  document = Nokogiri::HTML5(File.read(file))
  html = document.at_css("html")

  unless html&.[]("lang") == "fa" && html["dir"] == "rtl"
    errors << "#{file}: expected <html lang=\"fa\" dir=\"rtl\">"
  end

  document.css("a[href], img[src]").each do |node|
    value = node["href"] || node["src"]
    next if value.nil? || value.empty? || value.start_with?("#", "//") || value.match?(%r{^[a-z][a-z0-9+.-]*:}i)

    path = value.split(/[?#]/, 2).first
    next if path.empty?

    target = if path.start_with?("/")
      root.join(path.delete_prefix("/"))
    else
      Pathname(file).dirname.join(path)
    end

    candidates = [target, Pathname("#{target}.html"), target.join("index.html")]
    next if candidates.any?(&:exist?)

    errors << "#{file}: unresolved #{value}"
  end
end

abort(errors.join("\n")) unless errors.empty?
puts "Verified #{Dir.glob("_site/**/*.html").length} HTML files, local links, and RTL document roots."