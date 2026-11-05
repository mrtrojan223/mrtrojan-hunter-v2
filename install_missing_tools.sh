#!/bin/bash
# install_missing_tools.sh
# Install all missing bug bounty/recon tools for MrTrojan
# Optimized: per-tool timeouts, retries, and parallel installs so one
# hanging download/build can't freeze the whole script.

set -uo pipefail   # no -e: we want to keep going even if one tool fails

TIMEOUT_SEC=180          # kill any single install after 3 min
GO_TIMEOUT_SEC=240       # go installs can be slower (compiling)
MAX_RETRIES=2
LOG_DIR="$HOME/.tool_install_logs"
mkdir -p "$LOG_DIR"

echo "[*] Checking for Go..."
if ! command -v go &> /dev/null; then
    echo "[!] Go is not installed. Many tools require it."
    echo "    Install Go first: https://go.dev/doc/install"
    exit 1
fi

export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin:$HOME/.local/bin
export GOPROXY=https://proxy.golang.org,direct
export GOFLAGS="-mod=mod"

go env -w GO111MODULE=on

# ─── HELPERS ──────────────────────────────────────────────────
# run <name> <timeout_secs> <cmd...>  — retries with per-attempt timeout,
# logs output instead of dumping to screen, never lets one tool hang the rest.
run_with_timeout() {
    local name="$1" secs="$2"; shift 2
    local attempt=1 log="$LOG_DIR/$name.log"
    while [ "$attempt" -le "$MAX_RETRIES" ]; do
        echo "[*] Installing $name (attempt $attempt/$MAX_RETRIES, timeout ${secs}s)..."
        if timeout "$secs" "$@" > "$log" 2>&1; then
            echo "[+] $name OK"
            return 0
        else
            local rc=$?
            if [ "$rc" -eq 124 ]; then
                echo "[!] $name timed out after ${secs}s (see $log)"
            else
                echo "[!] $name failed (exit $rc, see $log)"
            fi
            attempt=$((attempt + 1))
        fi
    done
    echo "[x] $name gave up after $MAX_RETRIES attempts — skipping"
    return 1
}

go_install() {
    # $1 = binary name, $2 = go module path
    run_with_timeout "$1" "$GO_TIMEOUT_SEC" go install -v "$2"
}

# ─── SUBDOMAIN ENUMERATION (parallel — independent of each other) ──
echo "[*] Installing subdomain enum tools in parallel..."
go_install subfinder  github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest &
go_install assetfinder github.com/tomnomnom/assetfinder@latest &
go_install dnsx        github.com/projectdiscovery/dnsx/cmd/dnsx@latest &
wait

echo "[*] Installing findomain (prebuilt binary, curl with timeout)..."
if ! command -v findomain &> /dev/null; then
    if curl --fail --location --max-time "$TIMEOUT_SEC" --retry 2 \
        -o /tmp/findomain-linux.zip \
        https://github.com/findomain/findomain/releases/latest/download/findomain-linux.zip; then
        unzip -o /tmp/findomain-linux.zip -d /tmp/ > /dev/null
        chmod +x /tmp/findomain
        sudo mv /tmp/findomain /usr/local/bin/ 2>/dev/null || mv /tmp/findomain "$GOPATH/bin/"
        rm -f /tmp/findomain-linux.zip
        echo "[+] findomain OK"
    else
        echo "[!] findomain download failed/timed out — skipping"
    fi
fi

# amass is notorious for hanging on slow OSINT sources — give it its own
# longer timeout, isolated from everything else, and don't let it block the batch.
run_with_timeout amass "$GO_TIMEOUT_SEC" go install -v github.com/owasp-amass/amass/v4/...@latest

# ─── HTTP PROBING / CRAWLING (parallel) ────────────────────────────
echo "[*] Installing HTTP/crawling tools in parallel..."
go_install httprobe  github.com/tomnomnom/httprobe@latest &
go_install katana    github.com/projectdiscovery/katana/cmd/katana@latest &
go_install hakrawler github.com/hakluke/hakrawler@latest &
go_install gau       github.com/lc/gau/v2/cmd/gau@latest &
wait

# ─── PORT SCANNING ──────────────────────────────────────────────────
go_install naabu github.com/projectdiscovery/naabu/v2/cmd/naabu@latest

# ─── PARAMETER DISCOVERY ─────────────────────────────────────────────
run_with_timeout arjun "$TIMEOUT_SEC" pip3 install --quiet arjun || \
run_with_timeout arjun "$TIMEOUT_SEC" pip install --quiet arjun

# ─── PATTERN MATCHING / FILTERING (parallel) ─────────────────────────
echo "[*] Installing pattern tools in parallel..."
go_install gf         github.com/tomnomnom/gf@latest &
go_install qsreplace  github.com/tomnomnom/qsreplace@latest &
wait

if [ ! -d "$HOME/.gf" ]; then
    run_with_timeout gf-patterns "$TIMEOUT_SEC" git clone --depth 1 \
        https://github.com/1ndianl33t/Gf-Patterns "$HOME/.gf" || {
        run_with_timeout gf-patterns-fallback "$TIMEOUT_SEC" git clone --depth 1 \
            https://github.com/tomnomnom/gf "$HOME/.gf-tmp" && \
        cp -r "$HOME/.gf-tmp/examples" "$HOME/.gf" && rm -rf "$HOME/.gf-tmp"
    }
fi

# ─── XSS TESTING (parallel) ──────────────────────────────────────────
echo "[*] Installing XSS tools in parallel..."
go_install dalfox github.com/hahwul/dalfox/v2@latest &
go_install Gxss   github.com/KathanP19/Gxss@latest &
go_install kxss   github.com/Emoe/kxss@latest &
wait

# ─── VULNERABILITY SCANNING ──────────────────────────────────────────
go_install nuclei github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
# template updates hit the network too — don't let it hang the script
run_with_timeout nuclei-templates "$TIMEOUT_SEC" nuclei -update-templates -silent

go_install subzy github.com/LukaSikic/subzy@latest
run_with_timeout subzy-update "$TIMEOUT_SEC" subzy --update

# ─── SCREENSHOTS ──────────────────────────────────────────────────────
go_install gowitness github.com/sensepost/gowitness@latest

# ─── VERIFY ─────────────────────────────────────────────────────────
echo ""
echo "[*] Verification — checking installed tools:"
for tool in subfinder assetfinder findomain amass dnsx httprobe katana hakrawler gau naabu arjun gf qsreplace dalfox Gxss kxss nuclei subzy gowitness; do
    if command -v "$tool" &> /dev/null; then
        echo "[+] $tool installed"
    else
        echo "[!] $tool still missing — check $LOG_DIR/$tool.log"
    fi
done

echo ""
echo "[*] Logs for any failed/timed-out installs are in: $LOG_DIR"
echo "[*] Add this to your ~/.bashrc or ~/.zshrc if not already present:"
echo '    export PATH=$PATH:$HOME/go/bin:$HOME/.local/bin'
