# frozen_string_literal: true

require "rexml/document"

PROMPT_ROOTS = {
  ".codex/system_prompt.xml" => "peer_gem_code_collaboration",
  ".codex/architecture_context.xml" => "peer_gem_architecture",
  ".codex/engineering_rules.xml" => "peer_gem_engineering_rules"
}.freeze

guidance = File.read("AGENTS.md")

PROMPT_ROOTS.each do |path, root_name|
  abort "Missing Codex reference in AGENTS.md: #{path}" unless guidance.include?(path)

  document = REXML::Document.new(File.read(path))
  abort "Unexpected XML root in #{path}" unless document.root&.name == root_name
  abort "Empty XML guidance in #{path}" unless document.root.has_elements?

  puts "Validated #{path}"
end
