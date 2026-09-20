require "nokogiri"
require "pathname"

root = Pathname("_site").realpath
errors = []

stylesheet = root.join("assets/css/site.css")
unless stylesheet.file?
  errors << "missing generated stylesheet: #{stylesheet}"
else
  css = stylesheet.read
  unless css.include?('font-family: "Vazirmatn", Tahoma, Arial, sans-serif;')
    errors << "stylesheet does not set Vazirmatn as the site font"
  end

  {
    "Vazirmatn-Regular.woff2" => 400,
    "Vazirmatn-Bold.woff2" => 700
  }.each do |filename, weight|
    font = root.join("assets/fonts/#{filename}")
    errors << "missing generated Vazirmatn font: #{font}" unless font.file?
    errors << "#{font} is not a WOFF2 file" if font.file? && File.binread(font, 4) != "wOF2"
    unless css.include?("#{filename}") && css.include?("font-weight: #{weight};")
      errors << "stylesheet does not declare Vazirmatn #{weight}"
    end
  end
end

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

homepage = Nokogiri::HTML5(File.read("_site/index.html"))
home_images = homepage.css(".artwork-card img")
unless home_images.empty?
  errors << "first homepage artwork should be prioritized, not lazy-loaded" if home_images.first["loading"] == "lazy"
  home_images.drop(1).each do |image|
    errors << "non-first homepage artwork must lazy-load" unless image["loading"] == "lazy"
  end
end

errors << "existing /works/lim-v2/ route was not generated" unless root.join("works/lim-v2/index.html").file?

abort(errors.join("\n")) unless errors.empty?
puts "Verified #{Dir.glob("_site/**/*.html").length} HTML files, local links, RTL document roots, local Vazirmatn assets, and artwork loading behavior."
