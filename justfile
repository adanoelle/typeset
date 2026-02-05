# Default recipe - show available commands
default:
    @just --list

# Detect TeX engine from magic comment (%!TEX TS-program = ...)
[private]
tex-engine file:
    #!/usr/bin/env bash
    if grep -q '%!TEX TS-program = xelatex' "{{file}}" 2>/dev/null; then
        echo "-xelatex"
    elif grep -q '%!TEX TS-program = lualatex' "{{file}}" 2>/dev/null; then
        echo "-lualatex"
    else
        echo "-pdf"
    fi

# Build a document (auto-detects LaTeX or Typst)
build file:
    #!/usr/bin/env bash
    set -euo pipefail
    root=$(pwd)
    outdir="$root/target/$(dirname "{{file}}")"
    mkdir -p "$outdir"
    case "{{file}}" in
        *.tex)
            engine=$(just tex-engine "{{file}}")
            srcdir=$(dirname "{{file}}")
            srcfile=$(basename "{{file}}")
            cd "$srcdir" && latexmk $engine -outdir="$outdir" -interaction=nonstopmode "$srcfile"
            ;;
        *.typ) typst compile "{{file}}" "$outdir/$(basename "{{file}}" .typ).pdf" ;;
        *) echo "Unknown file type: {{file}}"; exit 1 ;;
    esac

# Watch a document with hot reload
watch file:
    #!/usr/bin/env bash
    set -euo pipefail
    root=$(pwd)
    outdir="$root/target/$(dirname "{{file}}")"
    mkdir -p "$outdir"
    case "{{file}}" in
        *.tex)
            engine=$(just tex-engine "{{file}}")
            srcdir=$(dirname "{{file}}")
            srcfile=$(basename "{{file}}")
            cd "$srcdir" && latexmk -pvc $engine -outdir="$outdir" -interaction=nonstopmode "$srcfile"
            ;;
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

    root=$(pwd)
    outdir="$root/target/$(dirname "{{file}}")"
    logdir="$outdir/logs"
    base=$(basename "{{file}}")
    pdf="$outdir/${base%.*}.pdf"
    mkdir -p "$outdir" "$logdir"

    # Detect TeX engine and source location if needed
    engine=""
    srcdir="."
    srcfile="{{file}}"
    case "{{file}}" in
        *.tex)
            engine=$(just tex-engine "{{file}}")
            srcdir=$(dirname "{{file}}")
            srcfile=$(basename "{{file}}")
            ;;
    esac

    # Build (output visible if it fails)
    case "{{file}}" in
        *.tex) cd "$srcdir" && latexmk $engine -outdir="$outdir" -interaction=nonstopmode "$srcfile" ;;
        *.typ) typst compile "{{file}}" "$pdf" ;;
        *) echo "Unknown file type: {{file}}"; exit 1 ;;
    esac

    # Background processes (redirect output to log files)
    sioyek "$pdf" >"$logdir/sioyek.log" 2>&1 &
    sioyek_pid=$!
    watchlog="$logdir/watch.log"
    case "{{file}}" in
        *.tex) (cd "$srcdir" && latexmk -pvc $engine -outdir="$outdir" -interaction=nonstopmode "$srcfile") >"$watchlog" 2>&1 & ;;
        *.typ) typst watch "{{file}}" "$pdf" >"$watchlog" 2>&1 & ;;
    esac
    watcher_pid=$!
    trap "kill $watcher_pid $sioyek_pid 2>/dev/null" EXIT

    # Clear screen and open editor
    clear
    hx "{{file}}"

# Clean all build artifacts
clean:
    rm -rf target/
