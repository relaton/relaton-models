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

ROOT = File.expand_path("..", __dir__)

def model_files
  @model_files ||= Dir[File.join(ROOT, "*/models/**/*.lml")]
                  .reject { |p| p.include?("/basicdoc/") } + Dir[File.join(ROOT, "basicdoc/models/**/*.lml")]
end

def defined_types
  @defined_types ||= model_files.each_with_object({}) do |f, acc|
    File.read(f).scan(/^\s*(?:class|enum|data_type|primitive)\s+([A-Za-z_]\w*)/).flatten.each do |t|
      acc[t] ||= f
    end
  end
end

def duplicates
  # Duplicate type names across modules are by design (flavours reuse
  # generic names like DocumentType); duplicates within one module are not.
  @duplicates ||= model_files.each_with_object(Hash.new { |h, k| h[k] = Hash.new { |hh, kk| hh[kk] = [] } }) do |f, acc|
    mod = f.sub(ROOT + "/", "").split("/").first
    File.read(f).scan(/^\s*(?:class|enum|data_type|primitive)\s+([A-Za-z_]\w*)/).flatten.each do |t|
      acc[mod][t] << f
    end
  end.flat_map { |mod, types| types.select { |_, files| files.size > 1 }.map { |t, files| [t, files] } }
end

def body_of(type)
  File.read(defined_types[type]) if defined_types[type]
end

def parent_of
  @parent_of ||= begin
    parents = {}
    # native LML inheritance
    model_files.each do |f|
      File.read(f).scan(/^\s*(?:class|enum|data_type)\s+(\w+)\s*<\s*(\w+)/).each do |child, parent|
        parents[child] ||= parent
      end
    end
    # view associations (owner parent of member)
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
    own = body_of(type).to_s.lines.filter_map do |line|
      m = line.match(/^\s*[+#-]([a-zA-Z][\w-]*)\s*:\s*(.+)$/)
      next unless m
      type_str = m[2].split("[")[0].split("{")[0].strip
      type_str = type_str.gsub(/<<[^>]*>>/, "").strip
      [m[1], type_str]
    end
    inherited = parent_of[type] ? attributes_of(parent_of[type]) : []
    (own + inherited).reject { |n, _| n == "definition" }
  end
end

def enum_values_of(type)
  return [] unless body_of(type).to_s =~ /^\s*enum\s/
  body_of(type).scan(/^\s{2,}([a-zA-Z][\w-]*)\s*\{$/).flatten - %w[definition]
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
