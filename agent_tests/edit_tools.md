# Neovim Boss - Buffer & Edit Tools Integration Test

You are an autonomous AI agent testing the 4 buffer/file operations provided by the `neovim-boss` MCP server:
- `read_full_buf`
- `read_buf_range`
- `find_and_replace_buf`
- `write_full_buf`

Alongside these, you will use `get_state` (or `get_state_brief`), `send_command`, and `send_keys` to verify editor state, test undo behavior, and clean up.

---

## Agent Execution Instructions

1. **Autonomous Execution**:
   - Execute all test steps sequentially from Section 1 through Section 5.
   - Do **NOT** pause or prompt the user for confirmation between steps.
   - Run each step, verify the tool response against the expected outcome, and record the result (`PASS` or `FAIL`).

2. **Verification & Success Criteria**:
   - For read operations (`read_full_buf`, `read_buf_range`): Check that returned lines are 1-indexed prefixed (`"<line_number>: <content>"`), total line counts match, and line ranges adhere to requested bounds.
   - For edit operations (`write_full_buf`, `find_and_replace_buf`): Check returned metadata (`total_lines`, `lines_added`, `lines_removed`, `start_line`), verify buffer state in `get_state` (`modified_buffers`), and verify that changes can be undone cleanly with `send_keys("u")`.
   - For error cases: Ensure proper structured error messages are returned (e.g., string not found, ambiguous multiple matches, invalid buffer, empty search string).
   - Keep an internal scorecard of `[PASSED]`, `[FAILED]`, and error details for each test case.

3. **Final Report Format**:
   - At the conclusion of the test run, output a clear summary scorecard table:
     - Test ID & Description
     - Tool(s) Tested
     - Status (`PASS` / `FAIL`)
     - Details / Observations
   - Conclude with an overall verdict: **`ALL PASSED`** or **`N FAILED`**.

---

## Setup

1. Call `get_state` to verify active connection to Neovim and record initial state.
2. Ensure a clean working environment:
   - Use `send_command("enew")` to ensure an empty buffer is active.

---

## 1 — `write_full_buf` Operations

### 1.1 Populate a New Scratch Buffer
- **Action**: Call `write_full_buf("edit_test_scratch.txt", "line one\nline two\nline three\nline four\nline five\n")`
- **Expected Outcome**:
  - Success response with `total_lines: 5`
- **Verification**:
  - Call `get_state`.
  - Verify `"edit_test_scratch.txt"` appears in `buffers` and `modified_buffers`.

### 1.2 Overwrite Entire Buffer
- **Action**: Call `write_full_buf("edit_test_scratch.txt", "alpha\nbeta\ngamma\n")`
- **Expected Outcome**:
  - Success response with `total_lines: 3`
- **Verification**:
  - Call `read_full_buf("edit_test_scratch.txt")`.
  - Verify lines: `["1: alpha", "2: beta", "3: gamma"]` with `total_lines: 3`.

### 1.3 Undo Buffer Overwrite
- **Action**:
  - Switch/focus buffer: `send_command("b edit_test_scratch.txt")`
  - Undo edit: `send_keys("u")`
- **Expected Outcome**:
  - Previous content (`line one` ... `line five`) restored.
- **Verification**:
  - Call `read_full_buf("edit_test_scratch.txt")`.
  - Verify lines match original 5 lines.

### 1.4 Write Empty Content
- **Action**: Call `write_full_buf("edit_test_scratch.txt", "")`
- **Expected Outcome**:
  - Success response with `total_lines: 1` (an empty single-line buffer in Vim).
- **Verification**:
  - Call `read_full_buf("edit_test_scratch.txt")`.
  - Verify line count is 1 and content is `["1: "]` or empty.
  - Undo: `send_keys("u")`.

---

## 2 — `read_full_buf` Operations

### 2.1 Read Full Active Buffer with Line Numbers
- **Action**: Call `read_full_buf("edit_test_scratch.txt")` (or buffer `0`).
- **Expected Outcome**:
  - Returns `total_lines: 5` and array of 5 numbered strings:
    - `1: line one`
    - `2: line two`
    - `3: line three`
    - `4: line four`
    - `5: line five`

### 2.2 Read by Buffer Number
- **Action**:
  - Call `get_state` to obtain the integer buffer number for `edit_test_scratch.txt`.
  - Call `read_full_buf(<buf_id>)` using the integer buffer number.
- **Expected Outcome**:
  - Returns identical 5-line numbered content as reading by name.

### 2.3 Read Non-Existent Buffer
- **Action**: Call `read_full_buf("this_buffer_does_not_exist_xyz.txt")`
- **Expected Outcome**:
  - Returns an error object or failure indicating the buffer was not found.

---

## 3 — `read_buf_range` Operations

### 3.1 Read Middle Line Range
- **Action**: Call `read_buf_range("edit_test_scratch.txt", 2, 4)`
- **Expected Outcome**:
  - Returns `total_lines: 5` and `lines`:
    - `2: line two`
    - `3: line three`
    - `4: line four`
  - Exactly 3 lines returned.

### 3.2 Read Single Line
- **Action**: Call `read_buf_range("edit_test_scratch.txt", 3, 3)`
- **Expected Outcome**:
  - Returns exactly 1 line: `["3: line three"]`.

### 3.3 Read First and Last Boundaries
- **Action 3.3a**: Call `read_buf_range("edit_test_scratch.txt", 1, 1)` -> Returns `["1: line one"]`.
- **Action 3.3b**: Call `read_buf_range("edit_test_scratch.txt", 5, 5)` -> Returns `["5: line five"]`.

### 3.4 Inverted Range Order (start > end)
- **Action**: Call `read_buf_range("edit_test_scratch.txt", 4, 2)`
- **Expected Outcome**:
  - Tool automatically normalizes range to `[2, 4]` and returns lines 2, 3, and 4.

### 3.5 Out-of-Bounds Clamping
- **Action**: Call `read_buf_range("edit_test_scratch.txt", -5, 100)`
- **Expected Outcome**:
  - Clamps start to 1 and end to 5, returning all 5 lines without error.

### 3.6 Range Beyond Buffer Length
- **Action**: Call `read_buf_range("edit_test_scratch.txt", 10, 20)`
- **Expected Outcome**:
  - Returns empty `lines: []` with `total_lines: 5`.

---

## 4 — `find_and_replace_buf` Operations

### 4.1 Single-Line Exact Replacement
- **Action**: Call `find_and_replace_buf("edit_test_scratch.txt", "line three", "line THREE modified")`
- **Expected Outcome**:
  - Success response with `start_line: 3`, `lines_removed: 1`, `lines_added: 1`, `total_lines: 5`.
- **Verification**:
  - Call `read_buf_range("edit_test_scratch.txt", 2, 4)`.
  - Verify line 3 is now `"3: line THREE modified"`.
  - Call `get_state` -> verify `edit_test_scratch.txt` in `modified_buffers`.

### 4.2 Multi-Line Replacement (Expanding Lines)
- **Action**: Call `find_and_replace_buf("edit_test_scratch.txt", "line four\nline five", "line four expanded A\nline four expanded B\nline five preserved")`
- **Expected Outcome**:
  - Success response with `start_line: 4`, `lines_removed: 2`, `lines_added: 3`, `total_lines: 6`.
- **Verification**:
  - Call `read_full_buf("edit_test_scratch.txt")`.
  - Verify 6 total lines and updated contents.

### 4.3 Multi-Line Replacement (Shrinking Lines)
- **Action**: Call `find_and_replace_buf("edit_test_scratch.txt", "line four expanded A\nline four expanded B", "line four condensed")`
- **Expected Outcome**:
  - Success response with `start_line: 4`, `lines_removed: 2`, `lines_added: 1`, `total_lines: 5`.
- **Verification**:
  - Call `read_full_buf("edit_test_scratch.txt")`.
  - Verify 5 total lines.

### 4.4 Partial Line Match (Prefix / Suffix Preservation)
- **Action**: Call `find_and_replace_buf("edit_test_scratch.txt", "THREE modified", "3")`
- **Expected Outcome**:
  - Line 3 (`line THREE modified`) becomes `line 3`.
- **Verification**:
  - Call `read_buf_range("edit_test_scratch.txt", 3, 3)`.
  - Verify line 3 content is `"3: line 3"`.

### 4.5 Error Case — String Not Found
- **Action**: Call `find_and_replace_buf("edit_test_scratch.txt", "nonexistent search target text", "replacement")`
- **Expected Outcome**:
  - Returns an error stating `"find string not found in buffer"`.
  - Buffer remains unmodified.

### 4.6 Error Case — Ambiguous Multiple Matches
- Setup: Call `write_full_buf("edit_test_scratch.txt", "repeat item\nmiddle\nrepeat item\n")`
- **Action**: Call `find_and_replace_buf("edit_test_scratch.txt", "repeat item", "single item")`
- **Expected Outcome**:
  - Returns an error indicating multiple occurrences / ambiguous match:
    `"find string matches multiple locations; add context to make it unique"`.
  - Buffer remains unmodified.

### 4.7 Error Case — Empty Find String
- **Action**: Call `find_and_replace_buf("edit_test_scratch.txt", "", "something")`
- **Expected Outcome**:
  - Returns an error stating `"find string cannot be empty"`.

### 4.8 Undo Verification
- **Action**:
  - Make `edit_test_scratch.txt` active if not already: `send_command("b edit_test_scratch.txt")`
  - Perform a valid replacement: `find_and_replace_buf("edit_test_scratch.txt", "middle", "CENTER")`
  - Verify edit applied: `read_full_buf("edit_test_scratch.txt")` contains `CENTER`.
  - Undo: `send_keys("u")`
- **Expected Outcome**:
  - `read_full_buf("edit_test_scratch.txt")` confirms original text (`middle`) is restored.

---

## 5 — Combined Multi-Buffer Workflow & Teardown

### 5.1 Operating on Background (Non-Active) Buffer
- **Action**:
  - Create second buffer: `write_full_buf("edit_test_secondary.txt", "sec 1\nsec 2\nsec 3\n")`
  - Ensure primary buffer is active: `send_command("b edit_test_scratch.txt")`
  - Call `get_state` to confirm active window shows `edit_test_scratch.txt`.
  - Perform edit on background buffer: `find_and_replace_buf("edit_test_secondary.txt", "sec 2", "sec TWO")`
- **Expected Outcome**:
  - Background buffer `edit_test_secondary.txt` is updated without changing the active window.
- **Verification**:
  - Call `read_full_buf("edit_test_secondary.txt")` -> Line 2 is `"2: sec TWO"`.
  - Call `get_state` -> Active window is still `edit_test_scratch.txt`.

### 5.2 Cleanup & Teardown
- **Action**:
  - Delete test buffers: `send_command("bd! edit_test_scratch.txt")`
  - Delete secondary test buffer: `send_command("bd! edit_test_secondary.txt")`
  - Call `get_state`
- **Expected Outcome**:
  - Both test buffers removed from `buffers` and `modified_buffers`.
  - Neovim is left in a clean state.

---

## Final Verification Report Format

Upon finishing all test steps, output the execution summary in the following markdown table format:

| Test ID | Description | Tool(s) Tested | Result | Notes |
|---|---|---|---|---|
| 1.1 | Populate scratch buffer | `write_full_buf`, `get_state` | PASS/FAIL | |
| 1.2 | Overwrite entire buffer | `write_full_buf`, `read_full_buf` | PASS/FAIL | |
| 1.3 | Undo buffer overwrite | `send_keys`, `read_full_buf` | PASS/FAIL | |
| 1.4 | Write empty content | `write_full_buf`, `read_full_buf` | PASS/FAIL | |
| 2.1 | Read full active buffer | `read_full_buf` | PASS/FAIL | |
| 2.2 | Read by buffer number | `read_full_buf`, `get_state` | PASS/FAIL | |
| 2.3 | Read non-existent buffer | `read_full_buf` | PASS/FAIL | |
| 3.1 | Read middle range | `read_buf_range` | PASS/FAIL | |
| 3.2 | Read single line | `read_buf_range` | PASS/FAIL | |
| 3.3 | Read boundary lines | `read_buf_range` | PASS/FAIL | |
| 3.4 | Inverted range handling | `read_buf_range` | PASS/FAIL | |
| 3.5 | Out-of-bounds clamping | `read_buf_range` | PASS/FAIL | |
| 3.6 | Out-of-range lines | `read_buf_range` | PASS/FAIL | |
| 4.1 | Single-line replace | `find_and_replace_buf`, `read_buf_range` | PASS/FAIL | |
| 4.2 | Multi-line expand replace | `find_and_replace_buf`, `read_full_buf` | PASS/FAIL | |
| 4.3 | Multi-line shrink replace | `find_and_replace_buf`, `read_full_buf` | PASS/FAIL | |
| 4.4 | Partial line preservation | `find_and_replace_buf`, `read_buf_range` | PASS/FAIL | |
| 4.5 | Error: String not found | `find_and_replace_buf` | PASS/FAIL | |
| 4.6 | Error: Multiple matches | `find_and_replace_buf`, `write_full_buf` | PASS/FAIL | |
| 4.7 | Error: Empty find string | `find_and_replace_buf` | PASS/FAIL | |
| 4.8 | Undo find and replace | `send_keys`, `read_full_buf` | PASS/FAIL | |
| 5.1 | Background buffer edit | `write_full_buf`, `find_and_replace_buf` | PASS/FAIL | |
| 5.2 | Cleanup & teardown | `send_command`, `get_state` | PASS/FAIL | |

**Overall Result**: [ALL PASSED / N FAILED]
