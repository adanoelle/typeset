# Typeset

LaTeX and Typst document typesetting environment with live preview.

## Commands

```bash
just build <file>   # Build .tex or .typ to PDF
just watch <file>   # Watch and rebuild on changes
just view <file>    # Open PDF in sioyek
just write <file>   # Edit with live preview (helix + sioyek + watcher)
just clean          # Remove target/
```

## Structure

```
├── latex/example/main.tex   # LaTeX example
├── typst/example/main.typ   # Typst example
└── target/                  # Build output (gitignored)
    └── <project>/
        ├── *.pdf            # Compiled PDFs
        └── logs/            # sioyek.log, watch.log
```

## Environment

Requires `nix develop` or direnv. Provides:
- LaTeX: texlive (scheme-full), latexmk, texlab (LSP)
- Typst: typst, tinymist (LSP)
- Tools: git, sioyek (PDF viewer), just

## Notes

- sioyek auto-reloads PDFs on change
- Watcher output goes to `logs/watch.log` to avoid clobbering helix
- LaTeX compilation is slow (~2s); Typst is fast (~50ms)
