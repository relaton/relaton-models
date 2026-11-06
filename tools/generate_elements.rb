# frozen_string_literal: true

# Generate RNC definitions from the LML models, driven by the explicit
# LML↔wire mapping table (mapping/elements.yml).
#
# Stage B of the LML-to-RNC generation (TODO.cc-citation/09): the wire
# grammar carries decisions the flat LML cannot express — class→element
# renames, attribute-vs-child-element, enum-or-open-text widening,
# mutual-exclusivity groups — so those live as data in the mapping;
# everything derivable (names, `##` annotations from the LML `definition`
# bodies, attribute types) comes from the LML.
#
# Ownership is structural: the generator owns the REGION between the
# GENERATED begin/end markers around each class's definitions. First
# adoption replaces the span anchor..`through` and wraps it in markers;
# every later run replaces the marked region. No heuristics.
#
#   ruby tools/generate_elements.rb          # splice generated blocks
#   ruby tools/generate_elements.rb --check  # fail if the tree would change
#
# Stage C: `rake grammar` runs this; CI asserts a clean tree.

require_relative "lml_model"
require "yaml"

class GenerateElements
  MAPPING = File.expand_path("../mapping/elements.yml", __dir__)
  MARKER = "GENERATED(%s):"

  # Each entry: "<rnc path>: <anchor> <changed|already generated>"
  attr_reader :changes

  def initialize
    @tables = YAML.safe_load_file(MAPPING)
    @changes = []
  end

  def run(check: false)
    @tables.each do |lml_class, spec|
      rnc_path = File.expand_path("../#{spec['file']}", __dir__)
      src = File.read(rnc_path)
      blocks = spec["definitions"].map { |name, d| render(lml_class, name, d) }
      region = region_text(lml_class, blocks)
      updated = adopt_or_replace(src, spec, region, lml_class)
      if updated == src
        @changes << "#{spec['file']}: #{spec['anchor']} already generated"
      else
        @changes << "#{spec['file']}: #{spec['anchor']} regenerated"
        File.write(rnc_path, updated) unless check
      end
    end
    @changes
  end

  private

  def begin_marker(class_name) = "# {#{format(MARKER, class_name)}} begin — rake grammar owns this region"
  def end_marker(class_name) = "# {#{format(MARKER, class_name)}} end"

  def region_text(lml_class, blocks)
    "#{begin_marker(lml_class)}\n#{blocks.join("\n\n")}\n#{end_marker(lml_class)}"
  end

  # Markers present: replace their inner region. Absent: replace the span
  # from the anchor definition through the `through` definition and insert
  # the markers around it (first adoption).
  def adopt_or_replace(src, spec, region, lml_class)
    if (m = /#{Regexp.escape(begin_marker(lml_class))}\n.*?^#{Regexp.escape(end_marker(lml_class))}\n?/m.match(src))
      return src[0...m.begin(0)] + region + "\n" + src[m.end(0)..]
    end

    start = src.match(/^#{Regexp.escape(spec['anchor'])}\s*=/) or raise "anchor #{spec['anchor']} not found"
    through = spec["through"] ? src.match(/^#{Regexp.escape(spec['through'])}\s*=/) : nil
    from = start.begin(0)
    to = through ? definition_end(src, through.begin(0)) : definition_end(src, from)
    src[0...from] + region + "\n" + src[to..]
  end

  # End offset of the definition beginning at `from`: these files separate
  # definitions with blank lines, so it runs to the first blank-line
  # boundary (keeping the newline that precedes it) or EOF.
  def definition_end(src, from)
    m = src[from..].match(/\n\n(?!\s)/)
    m ? from + m.begin(0) + 1 : src.length
  end

  # Render one mapping entry into an RNC definition block.
  def render(lml_class, name, d)
    if d["attributes"]
      attributes_block(lml_class, name, d["attributes"])
    else
      element_block(lml_class, name, d)
    end
  end

  # `name =\n  ## def\n  attribute a { T },\n  ## def\n  attribute b { T }?`
  def attributes_block(lml_class, name, attributes)
    parts = attributes.map do |attr, w|
      "  ## #{definition_line(lml_class, attr)}\n" \
        "  attribute #{attr} { #{w['type'] || lml_type(lml_class, attr)} }#{w['required'] ? '' : '?'}"
    end
    "#{name} =\n#{parts.join(",\n")}"
  end

  # `name = element <element> {\n  <attributes_ref line>\n  <group lines>\n}`;
  # `@attr:` tokens in the group pull the LML definition as a `##` annotation.
  def element_block(lml_class, name, d)
    lines = []
    lines << "  #{d['attributes_ref']}" if d["attributes_ref"]
    d["group"].each do |line|
      indent = line[/\A\s*/]
      lines << line.gsub(/@([a-z]+):\s*/) do
        "## #{definition_line(lml_class, Regexp.last_match(1))}\n#{indent}"
      end
    end
    "#{name} = element #{d['element']} {\n#{lines.join("\n")}\n}"
  end

  def lml_type(lml_class, attr)
    lml = LmlModel.attributes_of(lml_class).to_h.fetch(attr) { "String" }
    { "String" => "text" }.fetch(lml, lml)
  end

  def definition_line(lml_class, attr)
    LmlModel.definition_of(lml_class, attr).to_s.gsub(/\s+/, " ")
  end
end

if __FILE__ == $PROGRAM_NAME
  gen = GenerateElements.new
  gen.run(check: ARGV.include?("--check"))
  puts gen.changes
  if ARGV.include?("--check") && gen.changes.any? { |c| c.end_with?("regenerated") }
    warn "generated RNC differs from the committed tree - run `rake grammar`"
    exit 1
  end
end
