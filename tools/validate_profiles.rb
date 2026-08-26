# frozen_string_literal: true

# Validates profiles/*.yaml against the LML model.
#
# Profile rules: a profile may only narrow the base — exclude constructs,
# tighten cardinalities, subset enumerations. It may never widen, add,
# or rename. Extensions live above a profile, as flavour modules.
#
# Only parses the LML files referenced by profiles (fast).

require "yaml"
require "lutaml/lml"

ROOT = File.expand_path("..", __dir__)

def parse_enum_values(path)
  doc = Lutaml::Lml::Pipeline.call(File.read(path))
  e = doc.enums.first
  return [] unless e
  e.respond_to?(:values) && e.values.to_a.any? ?
    e.values.map(&:to_s) :
    (e.respond_to?(:attributes) ? e.attributes.map { |a| a.name.to_s } : []) - %w[definition]
rescue StandardError
  # fallback to regex for unparseable files
  File.read(path).scan(/^  ([^\s}]+?)[ ]*(?:\{|$)/).flatten - %w[definition]
end

def find_lml_file(type_name)
  own = Dir[File.join(ROOT, "*/models/**/#{type_name}.lml")]
          .reject { |p| p.include?("/basicdoc/") }
  own.first || Dir[File.join(ROOT, "basicdoc/models/**/#{type_name}.lml")].first
end

@errors = []
Dir[File.join(ROOT, "profiles", "*.yaml")].sort.each do |path|
  @profile = YAML.safe_load_file(path, permitted_classes: [], aliases: false)
  name = @profile["profile"] || File.basename(path, ".yaml")
  @errors.clear

  # enums: must be subsets of the base LML enum values
  (@profile["enums"] || {}).each do |enum_name, subset|
    # support module-scoped: "ccsds/DocumentType" or bare: "DocumentType"
    if enum_name.include?("/")
      mod, bare = enum_name.split("/", 2)
      lml = Dir[File.join(ROOT, mod, "models/**/#{bare}.lml")].first
    else
      lml = find_lml_file(enum_name)
    end
    if lml.nil?
      @errors << "#{name}: enum #{enum_name} has no LML file"
      next
    end
    base_vals = parse_enum_values(lml)
    extras = subset.map(&:to_s) - base_vals.map(&:to_s)
    @errors << "#{name}: enum #{enum_name} values not in base: #{extras.inspect}" unless extras.empty?
  end

  # constrain: targets must exist (regex check; parser-based in TODO)
  (@profile["constrain"] || {}).each_key do |target|
    type, attr = target.split(".")
    type_file = find_lml_file(type)
    if type_file.nil?
      @errors << "#{name}: constrain target type #{type} has no LML file"
      next
    end
    body = File.read(type_file)
    @errors << "#{name}: constrain #{target}: attribute #{attr} not found in #{type}" unless body =~ /^\s*[+#-]#{attr}\s*:/
  end

  if @errors.empty?
    puts "profiles: OK #{File.basename(path)}"
  else
    puts "profiles: FAIL #{File.basename(path)}"
    @errors.each { |e| puts "  #{e}" }
    exit 1
  end
end
