# Keycloak Guides: Vale Split Analysis

## What we ran

Ran the AsciiDocDITA Vale ruleset and `leben.py` splitter against `keycloak-1/docs/guides/` to assess DITA readiness.

## Vale results (raw source, before splitting)

| Severity | Count |
|----------|-------|
| Errors   | 618   |
| Warnings | 860   |
| Files    | 228   |

### Errors by rule

| Count | Rule | Meaning |
|-------|------|---------|
| 603 | NestedSection | `===` or deeper headings — must be split into separate modules for DITA |
| 15 | ExampleBlock | Example blocks not supported in DITA conversion |

### Warnings by rule

| Count | Rule | Meaning |
|-------|------|---------|
| 228 | ContentType | Missing `_mod-docs-content-type` attribute |
| 228 | ShortDescription | Missing `[role="_abstract"]` paragraph |
| 217 | DocumentTitle | Missing `=` document title |
| 81 | CalloutList | Callout lists not supported in DITA |
| 68 | BlockTitle | Block titles need conversion attention |
| 23 | LineBreak | Hard line breaks |
| 11 | DocumentId | Missing document ID anchor |
| 2 | RelatedLinks | Related links markup issue |
| 1 | DiscreteHeading | Discrete heading not supported |
| 1 | AdmonitionTitle | Admonition title issue |

## Splitting with leben.py

96 of the 228 files have nested sections that need splitting. However, `leben.py` only successfully split a subset.

### What worked

Files with `[[id]]` or `[id="..."]` anchors split correctly:

- **23 assemblies** created
- **61 modules** created
- Output in `keycloak-out/assemblies/` and `keycloak-out/modules/`

### What didn't work

Most keycloak guide files failed with "No root id" because they use bare headings without AsciiDoc anchor IDs:

```asciidoc
// Keycloak style (no anchor — leben.py skips these)
== Configuring the database

// What leben.py expects
[[configuring-the-database]]
== Configuring the database
```

The Apicurio docs that `leben.py` was built for use `[[id]]` anchors throughout. Keycloak guides don't follow this convention.

### Recursive glob gap

`leben.py` also missed files in subdirectories like `partials/`, `logging/`, and `high-availability/multi-cluster/`. The Python `glob.glob()` call doesn't recurse by default, so only top-level `.adoc` files within each subdirectory were processed.

## Files needing splits (96 total)

Heaviest areas:

| Directory | Files with nested sections |
|-----------|---------------------------|
| server/ | 20 |
| securing-apps/ (incl. partials/) | 19 |
| high-availability/ (incl. partials/) | 17 |
| observability/ (incl. partials/) | 11 |
| operator/ | 7 |
| admin-api/ | 3 |
| getting-started/ | 2 |
| ui-customization/ | 2 |
| templates/ | 1 |

## Options to get full coverage

1. **Filename-derived ID fallback** -- Modify `leben.py` to derive a root ID from the filename stem when no `[[id]]` anchor is present (e.g., `caching.adoc` becomes `[[caching]]`).

2. **Pre-processing step** -- Inject `[[filename-stem]]` anchors into keycloak files before running `leben.py`. Leaves the splitter unchanged but adds a pipeline step.

## How the Apicurio workflow works (for comparison)

The GitHub Action in `.github/workflows/apicurio-vale.yml`:

1. Cleans `assemblies/` and `modules/`
2. Runs `vale sync` to pull AsciiDocDITA styles
3. Loops over each `.adoc` file individually: `python3 leben.py "$adoc_file"`
4. Runs `vale --output=JSON assemblies/ modules/`
5. Commits results to a dedicated `apicurio` branch

Apicurio source files live in a flat directory and have `[[id]]` anchors, so this works without modification. A keycloak equivalent would need the ID fallback or pre-processing step to handle the different conventions.
