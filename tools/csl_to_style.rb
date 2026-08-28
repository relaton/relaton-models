# frozen_string_literal: true

# Minimal CSL-to-CitationStyle importer.
# Takes a simplified CSL style description (YAML) and produces a
# CitationStyle instance validated against the generated schema.
# Full CSL XML parsing is a follow-up; this handles the common patterns.

require "yaml"
require "json"

ROOT = File.expand_path("..", __dir__)
MAPPING = YAML.safe_load_file(File.join(ROOT, "mapping", "csl.yaml"), permitted_classes: [], aliases: false)

# Map CSL variable names to Relaton attribute names
def map_variable(csl_var)
  aliases = {"author" => "creator", "editor" => "contributor"}
  return aliases[csl_var] if aliases.key?(csl_var)
  spec = MAPPING["variables"][csl_var]
  return csl_var if spec.nil?
  spec.is_a?(String) ? spec : spec["attribute"]
end

# Map CSL type to BibItemType
def map_type(csl_type)
  MAPPING["types"][csl_type] || "misc"
end

# Convert a CSL-style template string to a CitationStyle template
# CSL: "author-date" becomes "{{creator}} {{date}}"
def convert_template(csl_template)
  csl_template.gsub(/\b(author|editor|translator|publisher)\b/) do |m|
    case m
    when "author" then "{{creator}}"
    when "editor" then "{{creator}}"
    when "translator" then "{{creator}}"
    when "publisher" then "{{production}}"
    end
  end.gsub(/\(issued-year\)/, "({{date}})")
     .gsub(/\bissued\b/, "{{date}}")
     .gsub(/\b(title)\b/, "{{title}}")
     .gsub(/\b(container-title)\b/, "{{series}}")
     .gsub(/\b(page)\b/, "{{pages}}")
     .gsub(/\b(DOI|URL)\b/) { |m| m == "DOI" ? "{{identifier}}" : "{{access}}" }
     .gsub(/\b(volume|issue)\b/, "{{extent}}")
     .gsub(/\b(edition)\b/, "{{edition}}")
     .gsub(/\b(note)\b/, "{{note}}")
     .gsub(/\b(accessed)\b/, "{{date}}")
end

# Import a simplified CSL style YAML to a CitationStyle instance
def import(input_path, output_path = nil)
  csl = YAML.safe_load_file(input_path, permitted_classes: [], aliases: false)
  
  style = {
    "class" => "CitationStyle",
    "name" => csl["name"] || File.basename(input_path, ".*"),
    "scheme" => {
      "class" => "CitationScheme",
      "system" => csl.dig("citation-format") == "author-date" ? "name-date" :
                  csl.dig("citation-format") == "numeric" ? "numeric" :
                  csl.dig("citation-format") || "name-date",
    },
    "templates" => {
      "class" => "TemplateMap",
      "citation" => convert_template(csl.dig("citation", "template") || "author-date"),
      "reference" => convert_template(csl.dig("bibliography", "template") || "author-date. title."),
    },
  }

  # per-type templates
  if csl["types"]
    style["perType"] = csl["types"].map do |csl_type, template|
      { "class" => "TypeTemplate", "type" => map_type(csl_type), "template" => convert_template(template) }
    end
  end

  # sort rules
  if csl["sort"]
    style["sortKey"] = csl["sort"].map do |key, order|
      { "class" => "SortRule", "attribute" => map_variable(key), "descending" => order == "desc" }
    end
  end

  output = output_path || input_path.sub(/\.(ya?ml)$/, ".style.yml")
  File.write(output, YAML.dump(style, default_flow_style: false, sort_keys: false))
  puts "csl:import #{File.basename(input_path)} -> #{File.basename(output)}"
  output
end

if __FILE__ == $PROGRAM_NAME
  if ARGV.empty?
    puts "Usage: ruby tools/csl_to_style.rb <input.yml> [output.yml]"
    puts "  Converts a simplified CSL style YAML to a CitationStyle instance"
    exit 1
  end
  import(ARGV[0], ARGV[1])
end
