# frozen_string_literal: true

# Validates examples/*.yaml instances against the LML model.
#
# YAML convention: every typed node carries `class` (the LML class name);
# keys are LML attribute names (inherited attributes count); plain scalars
# are date/URI/code values; `{text: ...}` maps are leaves of BasicElement
# content sequences.
#
# Inheritance is resolved from both LML native syntax (`class X < Y`) and
# view associations with owner_type inheritance, across every module.

require "yaml"
require "lutaml/lml"

ROOT = File.expand_path("..", __dir__)

def model_files
  @model_files ||= Dir[File.join(ROOT, "*/models/**/*.lml")]
                  .reject { |p| p.include?("/basicdoc/") } + Dir[File.join(ROOT, "basicdoc/models/**/*.lml")]
end

# Parser-based model extraction (lutaml-lml Pipeline.call, not regex)
def parsed_models
  @parsed_models ||= model_files.each_with_object({}) do |f, acc|
    begin
      doc = Lutaml::Lml::Pipeline.call(File.read(f))
      file_key = f
      (doc.classes || []).each { |k| acc[k.name] ||= { kind: "class", obj: k, file: file_key } }
      (doc.enums || []).each { |e| acc[e.name] ||= { kind: "enum", obj: e, file: file_key } }
    rescue StandardError
      warn "validate_yaml: skipping unparseable #{f.sub(ROOT + "/", "")}"
    end
  end
end

def defined_types
  parsed_models.transform_values { |v| v[:file] }
end

def duplicates
  parsed_models.each_with_object(Hash.new { |h, k| h[k] = Hash.new { |hh, kk| hh[kk] = [] } }) do |(name, info), acc|
    mod = info[:file].sub(ROOT + "/", "").split("/").first
    acc[mod][name] << info[:file]
  end.flat_map { |mod, types| types.select { |_, files| files.size > 1 }.map { |t, files| [t, files] } }
end

def body_of(type)
  File.read(defined_types[type]) if defined_types[type]
end

def parent_of
  @parent_of ||= begin
    parents = {}
    parsed_models.each_value do |info|
      next unless info[:kind] == "class"
      parent = info[:obj].respond_to?(:parent_class) ? info[:obj].parent_class : nil
      parents[info[:obj].name] ||= parent if parent
    end
    Dir[File.join(ROOT, "*/views/*.lml")].each do |v|
      File.read(v).scan(/association\s*\{[^}]*?owner\s+(\w+)[^}]*?member\s+(\w+)[^}]*?owner_type\s+inheritance/m).each do |parent, child|
        parents[child] ||= parent
      end
    end
    parents
  end
end

def attributes_of(type)
  @attributes_of ||= {}
  @attributes_of[type] ||= begin
    info = parsed_models[type]
    own = if info && info[:obj].respond_to?(:attributes) && info[:obj].attributes
      info[:obj].attributes.map do |a|
        type_str = a.type.to_s.gsub(/<<[^>]*>>/, "").strip
        [a.name.to_s, type_str]
      end
    else
      []
    end
    inherited = parent_of[type] ? attributes_of(parent_of[type]) : []
    (own + inherited).reject { |n, _| n == "definition" }
  end
end

def enum_values_of(type)
  info = parsed_models[type]
  return [] unless info && info[:kind] == "enum"
  if info[:obj].respond_to?(:values) && info[:obj].values.to_a.any?
    info[:obj].values.map(&:to_s)
  elsif info[:obj].respond_to?(:attributes) && info[:obj].attributes
    info[:obj].attributes.map(&:name).map(&:to_s) - %w[definition]
  else
    []
  end
end

RESERVED = %w[class text].freeze

@errors = []

def check_node(node, where)
  case node
  when Hash
    return if node.keys == ["text"]

    klass = node["class"]
    if klass.nil?
      @errors << "#{where}: node without class"
      return
    elsif !defined_types.key?(klass)
      @errors << "#{where}: unknown class #{klass}"
      return
    end

    attrs = attributes_of(klass)
    attr_names = attrs.map(&:first)
    enum_types = attrs.each_with_object({}) do |(n, t), h|
      h[n] = t if enum_values_of(t).any?
    end

    node.each do |k, v|
      if RESERVED.include?(k)
        check_node(v, "#{where}.#{k}") if v.is_a?(Hash) || v.is_a?(Array)
      elsif attr_names.include?(k)
        if enum_types[k] && v.is_a?(String) && !enum_values_of(enum_types[k]).include?(v)
          @errors << "#{where}: #{klass}.#{k} value '#{v}' not in enum #{enum_types[k]} (#{enum_values_of(enum_types[k]).first(12).join(', ')}...)"
        end
        check_node(v, "#{where}.#{k}") if v.is_a?(Hash) || v.is_a?(Array)
      else
        @errors << "#{where}: '#{k}' is not an attribute of #{klass} (has: #{(attr_names + RESERVED).uniq.join(', ')})"
      end
    end
  when Array
    node.each_with_index { |child, i| check_node(child, "#{where}[#{i}]") }
  end
end

dupes = duplicates.map { |t, files| "#{t}: #{files.map { |f| f.sub(ROOT + "/", "") }.join(", ")}" }
unless dupes.empty?
  warn "duplicate type definitions (first definition wins):"
  dupes.each { |d| warn "  #{d}" }
end

Dir[File.expand_path("../examples/*.yaml", __dir__)].sort.each do |path|
  @errors.clear
  data = YAML.safe_load_file(path, permitted_classes: [], aliases: false)
  data = data.values.first while data.is_a?(Hash) && data.keys.size == 1 && data.values.first.is_a?(Hash) && !data.key?("class")
  check_node(data, File.basename(path))
  if @errors.empty?
    puts "fixtures:yaml OK #{File.basename(path)}"
  else
    puts "fixtures:yaml FAIL #{File.basename(path)}"
    @errors.each { |e| puts "  #{e}" }
    exit 1
  end
end
