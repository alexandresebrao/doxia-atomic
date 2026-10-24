# Command Metadata

Read this before adding or changing commands in `bin/`.

Commands in `bin/` can declare CLI metadata in comments near the top of the
file. `bin/doxia` scans the first 80 lines, and tests expect command metadata
to remain valid.

Supported metadata keys:

- `# doxia:group=...` - override the command group inferred from the filename
- `# doxia:name=...` - override the command name inferred from the filename
- `# doxia:summary=...` - short help text
- `# doxia:args=...` - usage arguments
- `# doxia:examples=...` - examples separated with ` | `
- `# doxia:alias=...` / `# doxia:aliases=...` - alternate routes
- `# doxia:hidden=true` - hide from default command listings
- `# doxia:requires-sudo=true` - mark commands that require sudo

Only use `doxia:examples` where there are args that need explaining.

Prefer explicit metadata for user-facing commands. Keep routes consistent with
the filename unless there is a deliberate alias or compatibility route.

Example:

```bash
# doxia:summary=Take a screenshot
# doxia:args=[smart|region|windows|fullscreen] [slurp|copy]
# doxia:examples=doxia screenshot | doxia capture screenshot region
```
