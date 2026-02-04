# Default recipe - show available commands
default:
    @just --list

# Build a document (auto-detects LaTeX or Typst)
build file:
    #!/usr/bin/env bash
    set -euo pipefail
    outdir="target/$(dirname "{{file}}")"
    mkdir -p "$outdir"
    case "{{file}}" in
        *.tex) latexmk -pdf -outdir="$outdir" -interaction=nonstopmode "{{file}}" ;;
        *.typ) typst compile "{{file}}" "$outdir/$(basename "{{file}}" .typ).pdf" ;;
        *) echo "Unknown file type: {{file}}"; exit 1 ;;
    esac

# Watch a document with hot reload
watch file:
    #!/usr/bin/env bash
    set -euo pipefail
    outdir="target/$(dirname "{{file}}")"
    mkdir -p "$outdir"
    case "{{file}}" in
        *.tex) latexmk -pvc -pdf -outdir="$outdir" -interaction=nonstopmode "{{file}}" ;;
        *.typ) typst watch "{{file}}" "$outdir/$(basename "{{file}}" .typ).pdf" ;;
        *) echo "Unknown file type: {{file}}"; exit 1 ;;
    esac

# Open PDF in viewer (derives path from source file)
view file:
    #!/usr/bin/env bash
    set -euo pipefail
    outdir="target/$(dirname "{{file}}")"
    logdir="$outdir/logs"
    mkdir -p "$logdir"
    base=$(basename "{{file}}")
    sioyek "$outdir/${base%.*}.pdf" >"$logdir/sioyek.log" 2>&1 &

# Edit a document with live preview (editor + watcher + viewer)
write file:
    #!/usr/bin/env bash
    set -euo pipefail

    outdir="target/$(dirname "{{file}}")"
    logdir="$outdir/logs"
    base=$(basename "{{file}}")
    pdf="$outdir/${base%.*}.pdf"
    mkdir -p "$outdir" "$logdir"

    # Build (output visible if it fails)
    case "{{file}}" in
        *.tex) latexmk -pdf -outdir="$outdir" -interaction=nonstopmode "{{file}}" ;;
        *.typ) typst compile "{{file}}" "$pdf" ;;
        *) echo "Unknown file type: {{file}}"; exit 1 ;;
    esac

    # Background processes (redirect output to log files)
    sioyek "$pdf" >"$logdir/sioyek.log" 2>&1 &
    watchlog="$logdir/watch.log"
    case "{{file}}" in
        *.tex) latexmk -pvc -pdf -outdir="$outdir" -interaction=nonstopmode "{{file}}" >"$watchlog" 2>&1 & ;;
        *.typ) typst watch "{{file}}" "$pdf" >"$watchlog" 2>&1 & ;;
    esac
    watcher_pid=$!
    trap "kill $watcher_pid 2>/dev/null" EXIT

    # Clear screen and open editor
    clear
    hx "{{file}}"

# Clean all build artifacts
clean:
    rm -rf target/
