# Prompt 30: Create MCP Skill (YAML + Markdown)

## Purpose

Create a reusable MCP skill that AI agents can execute directly within the Krista platform. Skills are markdown files with YAML frontmatter that define metadata, execution mode, and instructions for the agent.

## Prerequisites

- Krista MCP Server extension deployed
- Understanding of the target task the skill should perform
- Access to Krista workspace with tool governance enabled

## Input Parameters

Replace these placeholders with your specific values:

| Parameter | Placeholder | Example |
|-----------|-------------|---------|
| Skill Name | `{{SKILL_NAME}}` | `weekly-status-report` |
| Skill Description | `{{SKILL_DESCRIPTION}}` | `Generate a weekly status report from project tools` |
| Model | `{{MODEL}}` | `sonnet` |
| Execution Mode | `{{EXECUTION_MODE}}` | `client` |
| Version | `{{VERSION}}` | `1.0.0` |

---

## Prompt

```
I need you to create a Krista MCP Skill for: {{SKILL_DESCRIPTION}}.

## 1. Skill File Structure

Create a file named `{{SKILL_NAME}}.md` with this exact format:

```yaml
---
name: {{SKILL_NAME}}
description: "{{SKILL_DESCRIPTION}}"
model: {{MODEL}}
execution-mode: {{EXECUTION_MODE}}
version: {{VERSION}}
---
```

## 2. Execution Mode Selection

Choose the execution mode based on the skill's requirements:

- **`client`** — Skill instructions are returned to the LLM which executes them locally. Use for: multi-step reasoning, dynamic tool discovery, conversational workflows. No additional API cost.
- **`server`** — Krista calls the Anthropic API with the skill instructions and enforces structured output. Use for: deterministic output format, JSON schema enforcement, consistent formatting.

## 3. Instruction Body

Write the instruction body in markdown below the YAML frontmatter. Follow these patterns:

### For multi-step workflows:

```markdown
## Instructions

You are an expert at {{SKILL_DESCRIPTION}}.

### Step 1: Discover available tools
- Call `krista_list_invokers` to find relevant integrations
- Call `krista_list_agents` to find available workflows
- Do NOT hardcode tool or invoker names — discover them at runtime

### Step 2: Gather data
- Use the discovered tools to collect the required information
- Handle missing or unavailable tools gracefully (skip with a note, don't fail)

### Step 3: Process and analyze
- [Describe the analysis or transformation logic]

### Step 4: Format output
- Present results in a clear, structured format
- Use markdown tables for tabular data
- Include timestamps and source attribution

### Error Handling
- If a tool is unavailable, note it in the output and continue
- If data is incomplete, present what you have with a "Data gaps" section
- Never fabricate data — clearly mark estimates or assumptions
```

### For simple query skills:

```markdown
## Instructions

Answer the user's question about {{SKILL_DESCRIPTION}}.

### Available context
- Use `krista_list_invokers` to find relevant data sources
- Use `krista_execute_tool` to query specific tools

### Output format
- Be concise and actionable
- Cite the source tool for each piece of information
```

## 4. Dynamic Discovery Pattern

Skills should discover tools at runtime, never hardcode names:

```markdown
### Discovery
1. Call `krista_list_invokers` to find all connected integrations
2. Match invokers by type (look for keywords in name/description):
   - Email: "outlook", "gmail", "mail"
   - Calendar: "calendar", "365", "google"
   - Tasks: "jira", "monday", "asana"
3. Use `krista_invoker_details` to get available operations
4. Select the appropriate tool for each data source
```

## 5. Multi-Workspace Support (Optional)

If the skill may run across multiple Krista workspaces:

```markdown
### Multi-Workspace
- Detect all available Krista workspaces by namespace prefix
- Run operations in parallel per workspace
- Deduplicate results across workspaces
- Label each result with its workspace name
```

## 6. Upload and Governance

After creating the skill file:

1. Upload via `krista_upload_skill` tool or Setup Guide tab
2. Skill enters `PENDING_REVIEW` state
3. Workspace admin approves and assigns to roles
4. Users in assigned roles can execute the skill

## Best Practices

- **Keep skills focused** — one skill per task, not a Swiss Army knife
- **Discover, don't hardcode** — use runtime tool discovery
- **Graceful degradation** — handle missing tools without failing
- **Clear output format** — define what the output looks like
- **Version incrementally** — bump version when changing behavior
- **Test in private catalog first** before deploying to global

## Related Prompts

- [Prompt 05: Add QUERY_SYSTEM Request](05-add-query-system-request.md) — for building the tools skills call
- [Prompt 12: Configure Setup Tab](12-configure-setup-tab.md) — for configuring the MCP Server extension
```

---

## Notes

- Skill names must be lowercase with hyphens (no spaces or underscores)
- Description should explain *when* to use the skill, not just *what* it does
- Model options: `haiku` (fast/cheap), `sonnet` (balanced), `opus` (most capable)
- Skills with `client` execution mode are free (no additional API cost)
