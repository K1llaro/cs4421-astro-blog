export default [
  {
    ignores: ["dist/**", ".astro/**", "node_modules/**"]
  },
  {
    files: ["**/*.{js,mjs,cjs,ts}"],
    rules: {
      "no-unused-vars": "warn",
      "no-undef": "warn"
    }
  }
];
