---
name: Elixir Anti-Patterns
description: A comprehensive guide to common anti-patterns in Elixir development, based on official documentation and community best practices.
---

# Elixir Anti-Patterns

This skill provides a reference for identifying and fixing common anti-patterns in Elixir. Refactoring these will improve code readability, maintainability, and performance.

## 1. Code-Related Anti-Patterns
*Idioms and features usage*

### Non-assertive Map Access
**Anti-pattern**: Using dynamic access `map[:key]` when the key is expected to exist.
**Why**: Returns `nil` instead of raising an error if the key is missing or typoed, leading to "nil" propagating far from the source.
**Refactoring**: Use static access `map.key` for required keys.
```elixir
# Bad
def plot(point), do: {point[:x], point[:y], point[:z]}

# Good - Crashes early if :x or :y are missing
def plot(point), do: {point.x, point.y, point[:z]}
```

### Complex `else` clauses in `with`
**Anti-pattern**: Flattening all error handling into a single complex `else` block in a `with` statement.
**Why**: It becomes unclear which step failed, especially if multiple steps return similar error tuples like `{:error, reason}`.
**Refactoring**: Normalize return values in private helper functions before calling `with`, or use a tagged return in the `with` clauses to identify the source.

### Non-assertive Pattern Matching
**Anti-pattern**: Writing defensive code that accepts any input format instead of matching strictly.
**Why**: Hides bugs by allowing malformed data to pass through, potentially causing confusing errors later.
**Refactoring**: Match on the specific structure you expect.
```elixir
# Bad - Returns invalid result for "university" if format is unexpected
Enum.find_value(parts, fn part ->
  key_val = String.split(part, "=") 
  Enum.at(key_val, 0) == desired_key && ...
end)

# Good - Crashes if format isn't "key=value"
Enum.find_value(parts, fn part ->
  [key, val] = String.split(part, "=")
  key == desired_key && val
end)
```

### Structs with > 32 Fields
**Anti-pattern**: Defining structs with 32 or more fields.
**Why**: The VM switches internal representation from "Flat Map" to "Hash Map", which uses more memory and is slower for struct operations.
**Refactoring**: Nest related fields into sub-structs or tuples.

### Dynamic Atom Creation
**Anti-pattern**: Converting user input directly to atoms (e.g., `String.to_atom/1`).
**Why**: Atoms are not garbage collected. An attacker can crash the VM by exhausting the atom table limit (approx 1M atoms).
**Refactoring**: Use `String.to_existing_atom/1` or maintain an explicit allow-list.

### Namespace Trespassing
**Anti-pattern**: Defining modules outside of your library's namespace (e.g., a library `:my_lib` defining `SomeOtherLib.Extension`).
**Why**: Causes conflicts if the target library eventually defines that module or if another library tries to do the same.
**Refactoring**: Always namespace your modules under your library's top-level module (e.g., `MyLib.Extension`).

## 2. Design-Related Anti-Patterns
*Module and function design*

### Boolean Obsession
**Anti-pattern**: Using multiple boolean options with overlapping or conflicting states.
**Why**: Creates invalid states (e.g., what if both `admin: true` and `guest: true` are passed?).
**Refactoring**: Use a single atom or enum field.
```elixir
# Bad
process(user, admin: true, editor: true)

# Good
process(user, role: :admin)
```

### Alternative Return Types
**Anti-pattern**: Functions that return drastically different types based on options (e.g., returning `integer` vs `{integer, remainder}`).
**Why**: Makes the function signature and usage confusing.
**Refactoring**: Create separate functions for each behavior (e.g., `parse/1` vs `parse_with_remainder/1`).

### Primitive Obsession
**Anti-pattern**: Using raw strings or integers to pass around complex domain concepts (e.g., an address string vs an `%Address{}` struct).
**Refactoring**: Create dedicated structs or modules for domain concepts.

### Using Application Config for Libraries
**Anti-pattern**: Libraries reading `Application.get_env/2` for runtime behavior.
**Why**: Prevents multiple applications (or tests) from using the library with different configurations simultaneously.
**Refactoring**: Pass configuration as options to the function or the process `start_link`.

## 3. Process-Related Anti-Patterns
*Processes and OTP*

### Code Organization by Process
**Anti-pattern**: Using a GenServer just to organize code or state that doesn't need concurrency (e.g., a "Calculator" GenServer).
**Why**: Creating a process adds overhead and can become a bottleneck (serialization point) if not needed.
**Refactoring**: Use standard modules and functions.

### Scattered Process Interfaces
**Anti-pattern**: Calling `GenServer.call` or `Agent.get` from many different modules.
**Why**: Leaks implementation details and couples code to the process structure. Hard to refactor later.
**Refactoring**: Encapsulate all interaction in a client API within the process module.
```elixir
# Bad - in some unrelated module
GenServer.call(:my_server, :do_thing)

# Good
MyServer.do_thing()
```

### Unsupervised Processes
**Anti-pattern**: Spawning processes (e.g., `GenServer.start/3` or `Node.spawn/2`) outside of a supervision tree.
**Why**: Makes it impossible to monitor, restart, or gracefully shut down these processes, leading to "zombie" processes or silent failures.
**Refactoring**: Always start processes under a `Supervisor`.

### Sending Large Data
**Anti-pattern**: Passing huge data structures between processes frequently.
**Why**: Messages are copied between process heaps, increasing memory and CPU usage.
**Refactoring**: Pass references (PIDs, ETS keys) or use ETS/persistent_term for shared access.

## 4. Meta-Programming Anti-Patterns
*Macros and compilation dependencies*

### Unnecessary Macros
**Anti-pattern**: Using a macro when a function would suffice.
**Why**: Macros are harder to write, debug, and read. They require `require` to use and obscure control flow.
**Refactoring**: Always prefer functions unless you need to inject code into the caller's context or manipulate AST.

### `use` instead of `import`
**Anti-pattern**: Using `use MyMod` to just import functions.
**Why**: `use` allows mostly anything (AST injection) and hides dependencies. `import` or `alias` is explicit and lexical.
**Refactoring**: Prefer `import` or `alias` for bringing functions into scope.

### Compile-time Dependencies
**Anti-pattern**: Macros that call functions or access data in other modules at expansion time.
**Why**: Creates a dependency graph where changing one file forces recompilation of many others.
**Refactoring**: Use `Macro.expand_literals` or runtime callbacks to avoid evaluating cross-module logic at compile time.

### Large Code Generation
**Anti-pattern**: Macros that generate huge chunks of code repeatedly.
**Why**: Increases compilation time and binary size.
**Refactoring**: Generate a call to a function that contains the logic, rather than the logic itself.
```elixir
# Bad
quote do
  # huge logic block
end

# Good
quote do
  MyHelper.do_logic(...)
end
```

### Untracked Compile-time Dependencies
**Anti-pattern**: Dynamically generating module names (e.g., `Module.concat`) inside macros or compile-time loops.
**Why**: The compiler cannot track which modules you depend on, so it won't recompile your code when they change.
**Refactoring**: Use explicit lists of module atoms or explicit `require`.

## 5. Other Common Pitfalls

### "Pokemon" Exception Handling
**Anti-pattern**: Using `try/rescue` to catch `_` or broad errors.
**Why**: Hides bugs and leaves the system in an unknown state ("Let It Crash").
**Refactoring**: Only catch specific expected errors.

### Accessing Repo in View
**Anti-pattern**: Triggering Ecto queries lazily inside a template/view.
**Why**: N+1 query problems.
**Refactoring**: Pre-load all data in the context/controller.

---
**References**:
- [Elixir Anti-patterns Documentation](https://hexdocs.pm/elixir/what-anti-patterns.html)
