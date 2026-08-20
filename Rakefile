PNG_MAGIC = "\x89PNG\r\n\x1a\n".b

VIEWS = Rake::FileList["*/views/*.lml"]
IMAGES = VIEWS.pathmap("%{views,images}d/%n.png")

desc "Render diagrams from views (default)"
task render: IMAGES

rule(%r{/images/.+\.png$}) do |t|
  source = t.name.sub("/images/", "/views/").sub(/\.png$/, ".lml")
  mkdir_p File.dirname(t.name)
  sh "lutaml-lml generate #{source} -o #{t.name} -t png"
end

VIEWS.map { |v| v.split("/").first }.uniq.sort.each do |mod|
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

task default: :render
