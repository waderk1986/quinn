import globals from "globals";

/** @type {import("eslint").Linter.Config[]} */
export default [
  {
    files: ["**/*.js"],
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: "script", // plain browser script, no ES modules
      globals: {
        ...globals.browser,
      },
    },
    rules: {
      // ── Errors ──────────────────────────────────────────────
      "no-undef":              "error",
      "no-unused-vars":        ["error", { "argsIgnorePattern": "^_", "varsIgnorePattern": "^_" }],
      "no-console":            ["warn", { "allow": ["warn", "error"] }],

      // ── Code quality ────────────────────────────────────────
      "eqeqeq":                ["error", "always"],
      "no-var":                "error",
      "prefer-const":          ["warn", { "destructuring": "all" }],
      "curly":                 ["warn", "multi-line"],
      "no-implicit-globals":   "error",

      // ── Style (what Prettier doesn't handle) ────────────────
      "no-trailing-spaces":    "warn",
      "no-multiple-empty-lines": ["warn", { "max": 2 }],

      // ── Relax for this codebase ──────────────────────────────
      // GLSL source is stored in template literals — long lines are fine
      "max-len":               "off",
      // setTimeout used for animation delays
      "no-restricted-globals": "off",
    },
  },
];
