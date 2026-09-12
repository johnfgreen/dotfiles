// memory-routing — auto-set OPCODE_AGENT for shell tools so opencode-memory routes correctly
// Handles: `opencode --agent X` CLI wrapper, `cd ~/Projects/inclusion-specialist` chpwd hook,
//          `/agent inclusion-specialist` TUI switch, and `@inclusion-specialist` mentions.
// Precedence: explicit OPCODE_AGENT/OPCODE_MEMORY_PATH in output.env is preserved.

export const MemoryRouting = async ({ client, directory }) => {
  return {
    // Inject OPCODE_AGENT into every bash/tool shell so opencode-memory can route
    "shell.env": async (input, output) => {
      try {
        // Respect explicit env already set (e.g. by zsh wrapper or user export)
        if (output.env.OPCODE_AGENT || output.env.OPCODE_MEMORY_PATH) return;

        const cwd = input.cwd || directory || "";

        // 1) PWD-based: inclusion-specialist project directory
        if (cwd.includes("inclusion-specialist")) {
          output.env.OPCODE_AGENT = "inclusion-specialist";
          return;
        }

        // 2) Session-based: if shell is running inside an opencode session, use that session's agent
        //    This covers `/agent inclusion-specialist` switches where PWD is not the project dir.
        const sessionID = input.sessionID;
        if (sessionID) {
          // Try SDK client first (most reliable, respects server state)
          try {
            const res = await client.session.get({ path: { id: sessionID } });
            // SDK returns { data: Session } — handle a few possible shapes
            const session = res?.data ?? res;
            const agent = session?.agent ?? session?.session?.agent;
            if (agent && agent !== "system") {
              output.env.OPCODE_AGENT = agent;
              return;
            }
            // If agent is system but cwd hints at inclusion-specialist, still route (fallback)
            if (agent === "system" && cwd.includes("inclusion-specialist")) {
              output.env.OPCODE_AGENT = "inclusion-specialist";
              return;
            }
          } catch (_) {
            // Fall through to DB fallback
          }

          // Fallback: direct DB read (bun:sqlite) — useful if SDK shape changes
          try {
            const home = process.env.HOME || "";
            const dbPath = `${home}/.local/share/opencode/opencode.db`;
            const fs = await import("fs");
            if (fs.existsSync(dbPath)) {
              try {
                const { Database } = await import("bun:sqlite");
                const db = new Database(dbPath, { readonly: true });
                const row = db.query("SELECT agent FROM session WHERE id = ?").get(sessionID);
                if (row && row.agent && row.agent !== "system") {
                  output.env.OPCODE_AGENT = row.agent;
                  db.close();
                  return;
                }
                db.close();
              } catch (_) {
                // bun:sqlite not available or query failed — ignore
              }
            }
          } catch (_) {}
        }

        // 3) Check for project marker in cwd hierarchy (opencode.jsonc or .opencode/agents)
        //    Walk up a few levels looking for inclusion-specialist marker
        try {
          const fs = await import("fs");
          const path = await import("path");
          let cur = cwd;
          for (let i = 0; i < 8; i++) {
            if (!cur || cur === "/" || cur === path.dirname(cur)) break;
            const marker1 = path.join(cur, ".opencode", "agents", "inclusion-specialist.md");
            const marker2 = path.join(cur, "opencode.jsonc");
            if (fs.existsSync(marker1)) {
              output.env.OPCODE_AGENT = "inclusion-specialist";
              return;
            }
            if (fs.existsSync(marker2)) {
              try {
                const content = fs.readFileSync(marker2, "utf8");
                if (content.includes("inclusion-specialist")) {
                  output.env.OPCODE_AGENT = "inclusion-specialist";
                  return;
                }
              } catch (_) {}
            }
            cur = path.dirname(cur);
          }
        } catch (_) {}
      } catch (_) {
        // Never throw — shell.env must not break bash tools
      }
    },
  };
};
