PNG_MAGIC = "\x89PNG\r\n\x1a\n".b

# Every top-level module directory that carries models (base + flavours).
MODULES = (Dir["*/models"].map { |d| File.dirname(d) } + Dir["*/views"].map { |d| File.dirname(d) })
  .uniq.reject { |m| m == "basicdoc" }.sort

VIEWS = Rake::FileList["*/views/*.lml"]
IMAGES = VIEWS.pathmap("%{views,images}d/%n.png")

desc "Render diagrams from views (default)"
task render: IMAGES

rule(
  %r{/images/.+\.png$} => [
    proc do |tn|
      view = tn.sub("/images/", "/views/").sub(/\.png$/, ".lml")
      includes = File.read(view).scan(/^\s*include\s+(\S+)/).flatten
        .map { |inc| File.expand_path(inc, File.dirname(view)) }
        .select { |path| File.exist?(path) }
      [view] + includes
    end
  ]
) do |t|
  source = t.name.sub("/images/", "/views/").sub(/\.png$/, ".lml")
  mkdir_p File.dirname(t.name)
  sh "lutaml-lml", "generate", source, "-o", t.name, "-t", "png"
end

MODULES.each do |mod|
  desc "Render #{mod} diagrams"
  task mod => IMAGES.select { |i| i.start_with?("#{mod}/") }
end

desc "Remove rendered diagrams (only those regenerable from views)"
task :clean do
  rm_f IMAGES.existing
end

desc "Assert PNG magic bytes on every committed diagram"
task :verify do
  pngs = Rake::FileList["*/images/*.png"].existing.sort
  bad = pngs.reject { |p| File.binread(p, 8) == PNG_MAGIC }
  abort "verify: #{bad.size} of #{pngs.size} PNG(s) invalid:\n  #{bad.join("\n  ")}" unless bad.empty?
  puts "verify: #{pngs.size} PNG file(s) OK"
end

desc "Assert LML/RNC parity: every flavour has LML models and an RNC overlay"
task :parity do
  errors = []

  # Base module must carry the shared grammars and LML models.
  %w[relaton/models relaton/views relaton/grammars/biblio.rnc].each do |p|
    errors << "missing base path: #{p}" unless File.exist?(p)
  end

  # basicdoc is a submodule providing the Basicdoc types RelBib depends on.
  errors << "missing basicdoc submodule (run: git submodule update --init)" unless File.directory?("basicdoc/models")

  Dir["*/grammars/relaton-*.rnc"].each do |rnc|
    flavour = rnc.split("/").first
    next if flavour == "relaton"
    models = Dir["#{flavour}/models/**/*.lml"]
    views  = Dir["#{flavour}/views/*.lml"]
    if models.empty?
      errors << "#{flavour}: has RNC overlay but no LML models under #{flavour}/models/"
    end
    if views.empty?
      errors << "#{flavour}: has RNC overlay but no LML views under #{flavour}/views/"
    end
  end

  # Every LML-bearing flavour should also have its RNC overlay (or be the base).
  Dir["*/models"].map { |d| File.dirname(d) }.each do |flavour|
    next if %w[relaton basicdoc citation].include?(flavour)
    rnc = Dir["#{flavour}/grammars/relaton-*.rnc"]
    errors << "#{flavour}: has LML models but no grammars/relaton-*.rnc overlay" if rnc.empty?
  end


  # Views vs models hard separation.
  Dir["*/models/**/*.lml", "relaton/models/**/*.lml"].each do |f|
    if File.read(f) =~ /^\s*(diagram|view)\b/
      errors << "#{f}: definition module contains diagram/view (belongs in views/)"
    end
  end
  Dir["*/views/*.lml", "relaton/views/*.lml"].each do |f|
    body = File.read(f)
    # class/enum/data_type at the start of a line inside a view = leaked definition
    if body =~ /^\s*(class|enum|data_type)\s+/
      errors << "#{f}: view contains class/enum/data_type body (extract to models/ and include)"
    end
  end

  # 02 — Vocabulary parity: every mapped LML enum must equal its RNC vocabulary.
  # Adding a vocabulary = adding one entry here (OCP).
  vocab_parity = {
    # LML enum => [RNC definition name, RNC path]
    "DocumentRelationType" => ["DocRelationType", "relaton/grammars/biblio.rnc"],
    "BibItemType" => ["BibItemType", "relaton/grammars/biblio.rnc"],
    "BibliographicDateType" => ["BibliographicDateType", "relaton/grammars/biblio.rnc"],
    "ContributorRoleType" => ["ContributorRoleType", "relaton/grammars/biblio.rnc"],
    "BsiDocumentType" => ["DocumentType", "bsi/grammars/relaton-bsi.rnc"],
    "GbDocumentType" => ["DocumentType", "gb/grammars/relaton-gb.rnc"],
    "IeeeDocumentType" => ["DocumentType", "ieee/grammars/relaton-ieee.rnc"],
    "IsoDocumentType" => ["DocumentType", "iso/grammars/relaton-iso.rnc"],
    "EtsiDocumentType" => ["DocumentType", "etsi/grammars/relaton-etsi.rnc"],
    "IecDocumentType" => ["DocumentType", "iec/grammars/relaton-iec.rnc"],
    "IetfDocumentType" => ["DocumentType", "ietf/grammars/relaton-ietf.rnc"],
    "JisDocumentType" => ["DocumentType", "jis/grammars/relaton-jis.rnc"],
    "PlateauDocumentType" => ["DocumentType", "plateau/grammars/relaton-plateau.rnc"],
    "CsaDocumentType" => ["DocumentType", "csa/grammars/relaton-csa.rnc"],
    "M3aawgDocumentType" => ["DocumentType", "m3aawg/grammars/relaton-m3aawg.rnc"],
    "RiboseDocumentType" => ["DocumentType", "ribose/grammars/relaton-ribose.rnc"],
    "UnDocumentType" => ["DocumentType", "un/grammars/relaton-un.rnc"],
    "ItuDocumentType" => ["DocumentType", "itu/grammars/relaton-itu.rnc"]
  }
  vocab_parity.each do |lml_type, (rnc_name, rnc_path)|
    lml_file = Dir["*/models/**/#{lml_type}.lml"].first || Dir["*/models/#{lml_type}.lml"].first
    if lml_file.nil?
      errors << "vocab parity: no LML enum file for #{lml_type}"
      next
    end
    lml_vals = File.read(lml_file).scan(/^  ([^\s}]+?)[ ]*(?:\{|$)/).flatten - ["definition"]
    rnc = File.read(rnc_path)
    best_vals = nil
    rnc.scan(/^\s*#{Regexp.escape(rnc_name)}\s*=/) do
      region = Regexp.last_match.post_match
      stop = region.index(/^([A-Za-z-]+ =|^## |^\})/, 1) || region.size
      vals = region[0, stop].scan(/"([^"]+)"/).flatten
      best_vals = vals if best_vals.nil? || vals.size > best_vals.size
    end
    if best_vals.nil?
      errors << "vocab parity: #{rnc_path} has no definition #{rnc_name}"
      next
    end
    rnc_vals = best_vals
        fold = ->(v) { v.tr("ÉÈÊËÀÂÄÇÎÏÔÖÛÜéèêëàâäçîïôöûü", "EEEEAAACIIOOUUeeeeaaaciioouu") }
    kebab = ->(v) { fold.call(v).gsub(/([a-z0-9])([A-Z])/, "\1-\2").downcase.tr("_ ", "--").squeeze("-") }
    if lml_vals.uniq.map(&kebab).sort != rnc_vals.uniq.map(&kebab).sort
      errors << "vocab parity #{lml_type}: LML-only=#{(lml_vals.uniq.map(&kebab) - rnc_vals.uniq.map(&kebab)).inspect} RNC-only=#{(rnc_vals.uniq.map(&kebab) - lml_vals.uniq.map(&kebab)).inspect}"
    end
  end

  abort "parity: #{errors.size} issue(s):\n  #{errors.join("\n  ")}" unless errors.empty?
  own = Dir["*/models/**/*.lml"].reject { |p| p.start_with?("basicdoc/") }
  puts "parity: OK (#{Dir['*/grammars/relaton-*.rnc'].size} flavour overlays, #{own.size} LML model files)"
end

desc "Build static model catalog into _site/ from */views/*.lml metadata + */images/"
task :site do
  require_relative "site/generate"
  RelatonSite.build!
end

BUILTIN_TYPES = %w[Integer Boolean Float Text String Date DateTime].freeze

def lml_modules
  Dir["*/models"].map { |d| File.dirname(d) }.reject { |m| m == "basicdoc" }.sort + ["basicdoc"]
end

def lml_defined_types(path)
  File.read(path).scan(/^\s*(?:class|enum|data_type|primitive)\s+(\w+)/).flatten
end

desc "Lint LML semantics: names, duplicate types, type resolution, view references"
task :lint do
  errors = []

  all_types = {}
  lml_modules.each do |mod|
    files = Dir["#{mod}/models/**/*.lml"]
    defined = {}
    files.each do |f|
      types = lml_defined_types(f)
      stem = File.basename(f, ".lml")
      errors << "#{f}: file name is not a type defined in this file (defines: #{types.join(', ')})" unless types.include?(stem)
      types.each { |t| (defined[t] ||= []) << f }
    end
    defined.each do |t, files2|
      errors << "#{mod}: duplicate type #{t}: #{files2.join(', ')}" if files2.size > 1
      all_types[t] = true
    end
  end

  # attribute types must resolve somewhere in the repo or be builtins
  Dir["*/models/**/*.lml"].each do |f|
    File.foreach(f).with_index do |line, i|
      m = line.match(/^\s*[+#-]([a-zA-Z][\w-]*)\s*:\s*(.+)$/)
      next unless m

      raw = m[2].split("[")[0].split("{")[0].gsub(/<<[^>]*>>/, "").strip
      next if raw.empty? || raw.start_with?('"') || BUILTIN_TYPES.include?(raw)
      next if all_types.key?(raw)

      errors << "#{f}:#{i + 1}: attribute '#{m[1]}' references undefined type '#{raw}'"
    end
  end

  # view association endpoints must resolve to a known type (own include
  # closure or a cross-module reference rendered as a collapsed box)
  Dir["*/views/*.lml"].each do |v|
    File.foreach(v).with_index do |line, i|
      m = line.match(/^\s*(owner|member)\s+(\w+)/)
      next unless m

      errors << "#{v}:#{i + 1}: association #{m[1]} '#{m[2]}' is not a known type" unless all_types.key?(m[2])
    end
  end

  abort "lint: #{errors.size} issue(s):\n  #{errors.join("\n  ")}" unless errors.empty?
  puts "lint: OK (#{all_types.size} types across #{lml_modules.size} modules)"
end

desc "Validate examples/*.xml against relaton/grammars/biblio-standoc.rnc (needs python3 + rnc2rng + lxml)"
task :"fixtures:xml" do
  sh "python3", "tools/validate_xml.py"
end

desc "Validate examples/*.yaml against the LML model"
task :"fixtures:yaml" do
  sh "bundle", "exec", "ruby", "tools/validate_yaml.rb"
end

desc "Generate the JSON Schema from the LML models"
task :schema do
  sh "python3", "tools/generate_schema.py"
end

desc "Validate examples/*.yaml against the generated JSON Schema (needs python3 + jsonschema + pyyaml)"
task :"fixtures:schema" do
  sh "python3", "tools/validate_schema.py"
end

desc "Validate mapping/csl.yaml against the generated schema (needs python3 + pyyaml)"
task :csl do
  sh "python3", "tools/validate_csl.py"
end

desc "Check LML-generated RNC vocabularies against committed"
task :"rnc:check" do
  sh "python3", "tools/generate_rnc.py", "--check"
end

desc "Validate XML, YAML, and schema fixtures"
task fixtures: %i[fixtures:xml fixtures:yaml fixtures:schema csl rnc:check]

desc "Validate profiles/*.yaml against the LML model (narrowing-only enforced)"
task :profiles do
  sh "bundle", "exec", "ruby", "-I", "tools", "tools/validate_profiles.rb"
end

desc "Render, verify PNGs, lint, and check LML/RNC parity"
task check: %i[render verify lint parity profiles]

desc "ALL gates: render, verify, lint, parity, profiles, fixtures, schema, CSL, RNC"
task ci: %i[render verify lint parity profiles fixtures csl rnc:check]

task default: :render
