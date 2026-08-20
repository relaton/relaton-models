PNG_MAGIC = "\x89PNG\r\n\x1a\n".b

# Every top-level module directory that carries models (base + flavours).
MODULES = (Dir["*/models"].map { |d| File.dirname(d) } + Dir["*/views"].map { |d| File.dirname(d) })
  .uniq.reject { |m| m == "basicdoc" }.sort

VIEWS = Rake::FileList["*/views/*.lml"]
IMAGES = VIEWS.pathmap("%{views,images}d/%n.png")

desc "Render diagrams from views (default)"
task render: IMAGES

rule(%r{/images/.+\.png$}) do |t|
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
    next if flavour == "relaton" || flavour == "basicdoc"
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

  abort "parity: #{errors.size} issue(s):\n  #{errors.join("\n  ")}" unless errors.empty?
  own = Dir["*/models/**/*.lml"].reject { |p| p.start_with?("basicdoc/") }
  puts "parity: OK (#{Dir['*/grammars/relaton-*.rnc'].size} flavour overlays, #{own.size} LML model files)"
end

desc "Build static model catalog into _site/ from */views/*.lml metadata + */images/"
task :site do
  require_relative "site/generate"
  RelatonSite.build!
end

desc "Render, verify PNGs, and check LML/RNC parity"
task check: %i[render verify parity]

task default: :render
