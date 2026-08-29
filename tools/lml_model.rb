# frozen_string_literal: true

# Shared LML model extraction used by validation tools.
# Provides model-file discovery (own modules first, basicdoc last) and
# parser-based type extraction via lutaml-lml.

module LmlModel
  ROOT = File.expand_path("..", __dir__)

  module_function

  def model_files
    own = Dir[File.join(ROOT, "*/models/**/*.lml")]
              .reject { |p| p.include?("/basicdoc/") }
    vendored = Dir[File.join(ROOT, "basicdoc/models/**/*.lml")]
    own.sort.concat(vendored.sort)
  end

  def find_lml_file(type_name)
    own = Dir[File.join(ROOT, "*/models/**/#{type_name}.lml")]
            .reject { |p| p.include?("/basicdoc/") }
    own.first || Dir[File.join(ROOT, "basicdoc/models/**/#{type_name}.lml")].first
  end

  # Parse a single LML file, returning {classes: [...], enums: [...]}
  # Resilient: returns empty on parse failure.
  def parse_file(path)
    require "lutaml/lml"
    doc = Lutaml::Lml::Pipeline.call(File.read(path))
    { classes: doc.classes || [], enums: doc.enums || [] }
  rescue StandardError
    { classes: [], enums: [] }
  end

  # Build a complete type index: name → {kind, obj, file}
  # Own modules take precedence over basicdoc stubs.
  def type_index
    @type_index ||= begin
      index = {}
      model_files.each do |f|
        parsed = parse_file(f)
        parsed[:classes].each { |k| index[k.name] ||= { kind: "class", obj: k, file: f } }
        parsed[:enums].each { |e| index[e.name] ||= { kind: "enum", obj: e, file: f } }
      end
      index
    end
  end

  # Attributes of a type, with inheritance resolved
  def attributes_of(type_name)
    info = type_index[type_name]
    return [] unless info && info[:obj].respond_to?(:attributes) && info[:obj].attributes
    own = info[:obj].attributes.map do |a|
      type_str = a.type.to_s.gsub(/<<[^>]*>>/, "").strip
      [a.name.to_s, type_str]
    end
    # LML native inheritance
    parent = info[:obj].respond_to?(:parent_class) ? info[:obj].parent_class : nil
    inherited = parent ? attributes_of(parent) : []
    (own + inherited).reject { |n, _| n == "definition" }
  end

  # Enum values
  def enum_values(type_name)
    info = type_index[type_name]
    return [] unless info && info[:kind] == "enum"
    if info[:obj].respond_to?(:values) && info[:obj].values.to_a.any?
      info[:obj].values.map(&:to_s)
    elsif info[:obj].respond_to?(:attributes) && info[:obj].attributes
      info[:obj].attributes.map(&:name).map(&:to_s) - %w[definition]
    else
      []
    end
  end
end
