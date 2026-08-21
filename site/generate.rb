# frozen_string_literal: true

require "erb"
require "json"
require "fileutils"
require "pathname"

module RelatonSite
  Plate = Struct.new(
    :module_name, :kind, :slug, :title, :view_file, :image,
    :includes, :associations, :call_no, :github_view_url,
    keyword_init: true
  )

  ModuleInfo = Struct.new(
    :name, :kind, :code, :plates, :model_files, :rnc_overlay,
    keyword_init: true
  )

  module_function

  ROOT = Pathname(__dir__).parent
  SITE = ROOT.join("site")
  OUT  = ROOT.join("_site")
  REPO = "https://github.com/relaton/relaton-models"

  def h(str)
    str.to_s
       .gsub("&", "&amp;")
       .gsub("<", "&lt;")
       .gsub(">", "&gt;")
       .gsub('"', "&quot;")
  end

  # Join parts with cataloguing-red separators, ISBD style.
  def isbd(*parts)
    parts.compact.map { |p| h(p.to_s) }.join(%(<span class="punct"> · </span>))
  end

  def kebab(name)
    name
      .gsub(/([a-z0-9])([A-Z])/, '\1-\2')
      .gsub(/[\s_]+/, "-")
      .downcase
  end

  def modules_with_views
    Dir[ROOT.join("*/views")].map { |d| File.basename(File.dirname(d)) }
                             .reject { |m| m == "basicdoc" }
                             .sort
  end

  def load_modules
    modules_with_views.map do |mod|
      views = Dir[ROOT.join("#{mod}/views/*.lml")].sort
      model_files = Dir[ROOT.join("#{mod}/models/**/*.lml")].size
      rnc = Dir[ROOT.join("#{mod}/grammars/relaton-*.rnc")].first
      ModuleInfo.new(
        name: mod,
        kind: mod == "relaton" ? "base" : "flavour",
        code: mod.upcase,
        plates: views.size,
        model_files: model_files,
        rnc_overlay: rnc ? File.basename(rnc) : nil
      )
    end
  end

  def load_plates(mods)
    seq = Hash.new(0)
    plates = []
    mods.each do |mod|
      Dir[ROOT.join("#{mod.name}/views/*.lml")].sort.each do |path|
        body = File.read(path)
        stem = File.basename(path, ".lml")
        title = body[/^\s*title\s+["']([^"']+)["']/, 1] ||
                stem.gsub(/[_-]/, " ").then { |s| s[0].upcase + s[1..] }
        includes = body.scan(/^\s*include\s+(\S+)/).flatten
        associations = body.scan(/^\s*association\s*\{/).size
        seq[mod.name] += 1
        plates << Plate.new(
          module_name: mod.name,
          kind: mod.kind,
          slug: kebab(stem),
          title: title,
          view_file: File.basename(path),
          image: "#{mod.name}/#{stem}.png",
          includes: includes,
          associations: associations,
          call_no: format("REL/%s/%02d", mod.code, seq[mod.name]),
          github_view_url: "#{REPO}/blob/main/#{mod.name}/views/#{File.basename(path)}"
        )
      end
    end
    plates
  end

  class PageContext
    def initialize(depth:, **vars)
      @depth = depth
      vars.each { |k, v| instance_variable_set("@#{k}", v) }
    end

    def asset_path(rel)
      @depth.zero? ? rel : "#{'../' * @depth}#{rel}"
    end

    def h(str) = RelatonSite.h(str)
    def isbd(*parts) = RelatonSite.isbd(*parts)
  end

  def render(template_name, vars, depth:)
    ctx = PageContext.new(depth: depth)
    b = ctx.instance_eval { binding }
    vars.each { |k, v| b.local_variable_set(k, v) }
    template = File.read(SITE.join("templates/#{template_name}"))
    ERB.new(template, trim_mode: "-").result(b)
  end

  def write_page(path, inner_html, title:, description:, index_page:, depth:)
    layout_html = render("layout.html.erb",
                         { content: inner_html,
                           page_title: title,
                           page_description: description,
                           index_page: index_page },
                         depth: depth)
    File.write(path, layout_html)
  end


  def build_inventory(mods)
    modules = mods.map do |m|
      classes = []
      Dir[ROOT.join("#{m.name}/models/**/*.lml")].sort.each do |f|
        body = File.read(f)
        body.scan(/^\s*(class|enum|data_type|primitive)\s+(\w+)(?:\s*<\s*(\w+))?\s*(?:<<[^>]*>>)?\s*\{/).each do |kind, name, parent|
          attrs = body.scan(/^\s*[+#-]([a-zA-Z][\w-]*)\s*:\s*([^\[{?\n]+)/)
                      .map { |n, t| { "name" => n, "type" => t.gsub(/<<[^>]*>>/, "").strip } }
          values = kind == "enum" ? body.scan(/^  ([A-Za-z][\w-]*)[ ]*\{/).flatten - ["definition"] : []
          entry = { "name" => name, "kind" => kind,
                    "file" => f.sub(ROOT.to_s + "/", ""), "module" => m.name }
          entry["parent"] = parent if parent
          entry["attributes"] = attrs if attrs.any?
          entry["values"] = values if values.any?
          classes << entry
        end
      end
      { "module" => m.name, "kind" => m.kind,
        "modelFiles" => Dir[ROOT.join("#{m.name}/models/**/*.lml")].size,
        "types" => classes }
    end
    relation = Dir[ROOT.join("relaton/models/DocumentRelationType.lml")].first
    body = File.read(relation) if relation
    { "generated" => Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
      "source" => REPO,
      "modules" => modules,
      "vocabularies" => {
        "relationTypes" => body.to_s.scan(/^  ([A-Za-z][\w-]*)[ ]*\{/).flatten - ["definition"]
      } }
  end

  def build!
    mods = load_modules
    plates = load_plates(mods)
    own_models = Dir[ROOT.join("*/models/**/*.lml")]
                  .reject { |p| p.start_with?("basicdoc/") }.size
    overlays = Dir[ROOT.join("*/grammars/relaton-*.rnc")].size

    FileUtils.rm_rf(OUT)
    mods.each { |m| FileUtils.mkdir_p(OUT.join("plates/#{m.name}")) }
    FileUtils.mkdir_p(OUT.join("assets/css"))
    FileUtils.mkdir_p(OUT.join("assets/js"))
    FileUtils.mkdir_p(OUT.join("images"))

    FileUtils.cp(SITE.join("assets/css/site.css"), OUT.join("assets/css/site.css"))
    FileUtils.cp(SITE.join("assets/js/site.js"), OUT.join("assets/js/site.js"))
    mods.each do |m|
      FileUtils.mkdir_p(OUT.join("images/#{m.name}"))
      Dir[ROOT.join("#{m.name}/images/*.png")].each do |png|
        FileUtils.cp(png, OUT.join("images/#{m.name}", File.basename(png)))
      end
    end

    index_html = render("index.html.erb",
                        { mods: mods, plates: plates,
                          own_models: own_models, overlays: overlays },
                        depth: 0)
    write_page(OUT.join("index.html"), index_html,
               title: "Relaton Models — card catalog",
               description: "Card catalog of the Relaton bibliographic information model (ISO 690): RelBib base and 29 SDO flavour diagrams, rendered from LutaML.",
               index_page: true, depth: 0)

    plates.each_with_index do |plate, i|
      vars = {
        plate: plate,
        mod: mods.find { |m| m.name == plate.module_name },
        plate_index: i,
        plate_total: plates.size,
        prev_plate: i.positive? ? plates[i - 1] : nil,
        next_plate: plates[i + 1]
      }
      page_html = render("plate.html.erb", vars, depth: 2)
      write_page(OUT.join("plates/#{plate.module_name}/#{plate.slug}.html"), page_html,
                 title: "#{plate.title} — #{plate.module_name} · Relaton Models",
                 description: "UML card for #{plate.title} (#{plate.module_name}) in the Relaton model catalog.",
                 index_page: false, depth: 2)
    end

    File.write(OUT.join("inventory.json"), JSON.pretty_generate(build_inventory(mods)))

    File.write(OUT.join(".nojekyll"), "")
    puts "site: wrote #{plates.size + 1} pages -> #{OUT}"
  end
end
