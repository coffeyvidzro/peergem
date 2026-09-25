# PeerGem repository guidance

Before changing code, read `.codex/system_prompt.xml`,
`.codex/architecture_context.xml`, and `.codex/engineering_rules.xml`.
Use them as project guidance alongside the user's task, not as substitutes for
the current source code, tests, or applicable higher-priority instructions.

The repository is currently a Ruby 4.0.7 / Rails 8.1 application with JSON APIs
and a server-rendered ERB/Hotwire UI. Implement only the feature requested;
the Go payment switch, production ledger, and several commerce modules are
planned boundaries, not code already present here.

Prefer focused changes, tenant-scoped queries, regression tests, and factual
validation results. Do not claim external payment settlement or regulatory
compliance merely because a local test or adapter passes.
