# Analysis of the test prompt in paulburgess1357/nvim-mcp

Reading through Paul Burgess's test prompt is incredibly illuminating. It reveals the exact operational philosophy of
how an AI agent actually drives Neovim in practice.

Here are the key insights and takeaways from analyzing this test suite:
──────
### 1. send_command and send_keys Already Do 70% of the Work!

Notice how much of this entire test suite does not use dedicated tools, but instead relies entirely on the escape
hatches we just built:

• Windows & Splits (Section 5): :vsplit, :split, :wincmd l, :only → send_command
• Tabs (Section 6): :tabnew, :tabprev, :tablast \| tabclose → send_command
• Buffer switching & cleanup (Sections 1, 11, 15, Cleanup): :e, :b, :bd, :enew, :%bd \| e# \| bd# → send_command
• Terminal (Section 11): :terminal → send_command
• Undo (Sections 3.3, 3.4, 4.2, 7.7, 16.12): send_keys("u") → send_keys
• Modes & Selection (Section 7): i, <Esc>, ggVG, ggvw, gg<C-v>jj, R, : → send_keys
• Folds & Marks (Section 12): ggVGzf, zR, 10Gma, 20Gmb → send_keys

Paul Burgess didn't build tools like split_window, switch_tab, undo, create_fold, or set_mark. Neovim already has the
world's best grammar for these actions.
──────
### 2. get_state is the Heartbeat (Called 35+ Times)

In this test prompt, get_state is called after almost every single step:

• After opening a split
• After changing modes
• After sending keys
• After undoing
• After find-and-replace

#### The Lesson for exec_lua:

If the agent had to write a 30-line Lua block to inspect the editor state 35 times, the session would have generated
~7,000 extra output tokens of Lua boilerplate and suffered huge latency.

A dedicated get_state / get_state_brief tool is the single most valuable tool we can add next. It acts as the agent's
eyes, providing a complete situational snapshot (mode, cursor, windows, modified buffers, diagnostic count) in a single
~20-token tool call.
──────
### 3. find_and_replace_buf is Purpose-Built for LLM Safety

Notice tests 4.3 and 4.4:

• 4.3: String not found → Return clear error.
• 4.4: Multiple matches ("return a") → Return clear error indicating ambiguity!
• Undo compatibility: Every edit is immediately testable with send_keys("u").

When an LLM uses exec_lua or Ex commands (:%s/.../) for find-and-replace:

1. It is prone to escaping hell with quotes and regex specials.
2. If the search string isn't unique, it accidentally alters unintended parts of the codebase.
find_and_replace_buf eliminates that entire category of agent blunders.
──────
### 4. Buffer Reading (read_buf_range, read_full_buf) is Pure Convenience

Sections 2.1–2.7 test reading buffers.

• Could an agent do exec_lua("return vim.api.nvim_buf_get_lines(...)")? Yes.
• But read_buf_range(path, start, end) formatted with line numbers makes reading code effortless and uniform for the
model.
──────
### 5. Extmarks (Highlights & Virtual Text) are Cosmetic

Sections 9 & 10 test highlight_range and add_virtual_text.

• They are non-destructive UI decorations so the human user watching Neovim can see what the agent is thinking or
proposing.
• These can easily be either dedicated lightweight tools or provided as canonical Lua snippets in prompts.
──────
### What This Means for neovim-boss

To be able to run this entire test workflow in neovim-boss, here is the minimal high-leverage checklist:

1. get_state / get_state_brief: The sensory feedback loop.
2. read_buf_range / read_full_buf: Clean, line-numbered buffer inspection.
3. find_and_replace_buf / write_full_buf: Unambiguous, undo-safe in-memory editing.
4. (Optional) Extmarks (highlight_range, add_virtual_text): Non-destructive visual feedback.

With just get_state and find_and_replace_buf added to our existing exec_lua, send_command, and send_keys, we would cover
>90% of everything in this test suite.

Would you like to start on get_state_brief / get_state (Domain 1: Situational Awareness)?

──────────────────────────────────────────────────────────
what do you think of the trade offs between implementing get_state_brief / get_state as tools vs resources in mcp

Thought for 6s, 1.5k tokens
This dual approach provides flexibility in different client setups. It also ensures universal compatibility as the tool...
This is one of the most fundamental design questions in the Model Context Protocol (MCP).

The short answer is: Tools are essential for autonomous agent loops; Resources are ideal for ambient context and human
inspection. The best design is a unified Zig backend that exposes both.

Here is the breakdown of trade-offs:
──────
### 1. The Core Semantic Difference

 Dimension        │ Tool (get_state_brief)                           │ Resource (neovim://state)
──────────────────┼──────────────────────────────────────────────────┼──────────────────────────────────────────────────
 Grammar          │ Active Verb ("Look at the editor now")           │ Passive Noun ("Current editor state")
 Who initiates    │ The LLM Agent, dynamically mid-turn              │ The User (by attaching @neovim://state) or the
                  │                                                  │ Client UI
 Execution Timing │ Can be called multiple times mid-turn (e.g.      │ Usually read once at the start of a turn or when
                  │ split → check → resize → check)                  │ refreshed
 Parameters       │ Accepts arguments (e.g. buffer: "notes.md",      │ Fixed URI or URI template
                  │ lines: 5)                                        │
──────
### 2. Detailed Trade-off Analysis

#### A. Client Support & Agent Autonomy (Winner: Tool)

• The Reality of Current LLM Clients:
    • Tools are universally supported across Claude Code, Claude Desktop, Cursor, OpenCode, Cline, and Roo-Code. LLMs
    are trained to actively call tools when they need information.
    • Resources, by contrast, are treated inconsistently across clients. In Claude Desktop, resources are mostly for the
    human to click and attach. In Cursor and Claude Code, agents rarely query resources/read autonomously unless
    explicitly instructed.
• Verdict: If you want an agent to autonomously run multi-step workflows (like Paul Burgess's test prompt: "split window,
verify state, edit buffer, verify state"), it must be a Tool.

#### B. Mid-Turn Re-Act Loops (Winner: Tool)

• Look at Section 16 of Paul Burgess's test:
    1. send_command("vsplit ...")
    2. get_state() (verifies 2 windows)
    3. find_and_replace_buf(...)
    4. get_state() (verifies modified flag)
    5. send_keys("u")
    6. get_state() (verifies clean flag)
• All of this happens within a single conversation turn.
• A tool allows the model to interleave actions with state checks. With resources, the agent is stuck with whatever
snapshot was loaded before the turn started, unless the client equips the agent with a generic read_resource tool.

#### C. Token Efficiency & "Ambient" Context (Winner: Resource)

• If get_state is a tool:
    • The model has to spend tokens to call it: {"name": "get_state_brief"}.
    • The response is appended to the message history.
• If neovim://state is a resource:
    • Advanced MCP clients can automatically subscribe to neovim://state via resources/subscribe and inject the fresh
    state into the system prompt at the beginning of each turn.
    • The model gets immediate orientation without making an extra tool call round-trip.


#### D. Subscriptions & Push Updates (Winner: Resource)

• MCP Resources natively support notifications/resources/updated.
• When the user types in Neovim, switches buffers, or changes modes, neovim-boss can emit a resource notification to the
client. Tools cannot do push notifications.
──────
### 3. Summary Comparison

  +------------------------------------+------------------------------------+
  |               TOOL                 |              RESOURCE              |
  +------------------------------------+------------------------------------+
  | [+] Works in 100% of MCP agents    | [-] Inconsistent agent access      |
  | [+] Essential for multi-step tasks | [-] Cannot interleave mid-turn     |
  | [+] Allows parameters/filtering    | [-] Static URI structure           |
  | [-] Incurs a tool-call round-trip  | [+] Zero-effort ambient context    |
  | [-] No push notification support   | [+] Supports subscriptions/push    |
  +------------------------------------+------------------------------------+
──────
### 4. The Recommendation: The "Symbiotic" Model

Because neovim-boss is written in Zig with a clean decoupled architecture, we don't have to choose!

1. Write the Core State Engine in src/nvim.zig:
    • Build nvim.getState(arena) and nvim.getStateBrief(arena) which gathers mode, cursor, windows, modified buffers,
    and diagnostics in a single RPC round-trip.
2. Expose it as a Tool (get_state_brief / get_state):
    • This gives AI agents the active sensory tool they need to drive Neovim and run tests autonomously.
3. Expose it as a Resource (neovim://state and neovim://state/brief):
    • Just like our existing neovim://buffers resource, this allows humans to attach @neovim://state in IDEs and enables
    clients that support ambient resource subscriptions.


This gives us the best of both worlds with zero redundant logic.
