# MrTrojan-Hunter

Full-spectrum bug bounty & recon automation framework. Takes a single domain
through 21 phases of subdomain enumeration, web probing, crawling, parameter
discovery, and vulnerability testing — plus a dedicated OWASP Top 10 (2021)
module stack — and writes everything to a structured output directory with a
final Markdown report.

```
  ███╗   ███╗██████╗ ████████╗██████╗  ██████╗      ██╗ █████╗ ███╗   ██╗
  ████╗ ████║██╔══██╗╚══██╔══╝██╔══██╗██╔═══██╗     ██║██╔══██╗████╗  ██║
  ██╔████╔██║██████╔╝   ██║   ██████╔╝██║   ██║     ██║███████║██╔██╗ ██║
  ██║╚██╔╝██║██╔══██╗   ██║   ██╔══██╗██║   ██║██   ██║██╔══██║██║╚██╗██║
  ██║ ╚═╝ ██║██║  ██║   ██║   ██║  ██║╚██████╔╝╚█████╔╝██║  ██║██║ ╚████║
  ╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝  ╚════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝

  ██╗  ██╗██╗   ██╗███╗   ██╗████████╗███████╗██████╗
  ██║  ██║██║   ██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗
  ███████║██║   ██║██╔██╗ ██║   ██║   █████╗  ██████╔╝
  ██╔══██║██║   ██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗
  ██║  ██║╚██████╔╝██║ ╚████║   ██║   ███████╗██║  ██║
  ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝
```

## ⚠️ Legal notice

This tool is for authorized security testing only — bug bounty programs you
are enrolled in, pentest engagements you have written authorization for, or
assets you personally own. Running active scans, brute-forcing, or injection
tests against a target you don't have explicit permission to test is illegal
in most jurisdictions. You are solely responsible for how you use this.

## Features

- **21 recon/testing phases**, run automatically in sequence
- **Dedicated OWASP Top 10 (2021) module stack** (A01–A10), run after the
  core phases for deeper, categorized coverage
- **Stall detection** — a hung/frozen tool (zero output for a configurable
  window) is killed automatically; tools that are actively producing output
  always run to natural completion, so no findings get cut short
- **Parallelized passive subdomain enumeration** to save time
- **Checkpoint-friendly, resumable output structure** — every phase writes to
  its own numbered subdirectory
- **Graceful degradation** — any missing tool is skipped with a log line
  instead of crashing the run
- **Animated startup splash** on a real terminal; falls back to plain output
  automatically in CI/logs, or skip it entirely with `--no-banner`
- **Final Markdown report** summarizing counts and every confirmed/candidate
  finding across all phases

### Phase list

| # | Phase | # | Phase |
|---|-------|---|-------|
| 01 | Subdomain Enumeration | 12 | Server-Side Request Forgery |
| 02 | DNS & ASN Intel | 13 | Open Redirect |
| 03 | Port Scanning | 14 | CORS Misconfiguration |
| 04 | Web Probing & Tech Detection | 15 | Subdomain Takeover |
| 05 | URL Crawling | 16 | Nuclei Broad Scan |
| 06 | Parameter Discovery | 17 | Secrets & Credentials |
| 07 | Directory Brute-Force | 18 | Cloud Infrastructure |
| 08 | JavaScript Analysis | 19 | WordPress Security |
| 09 | SQL Injection | 20 | Additional Checks |
| 10 | Cross-Site Scripting (XSS) | 21 | Final Report |
| 11 | Local File Inclusion | | |

### OWASP Top 10 (2021) coverage

| ID | Category | Output dir |
|----|----------|------------|
| A01 | Broken Access Control | `owasp_a01_access_control/` |
| A02 | Cryptographic Failures | `owasp_a02_crypto/` |
| A03 | Injection (SQLi, CMDi, SSTi, XXE, LDAPi, NoSQLi, XPATHi) | `owasp_a03_injection/` |
| A04 | Insecure Design | `owasp_a04_insecure_design/` |
| A05 | Security Misconfiguration | `owasp_a05_misconfig/` |
| A06 | Vulnerable & Outdated Components | `owasp_a06_components/` |
| A07 | Identification & Authentication Failures | `owasp_a07_auth/` |
| A08 | Software & Data Integrity Failures | `owasp_a08_integrity/` |
| A09 | Security Logging & Monitoring Failures | `owasp_a09_logging/` |
| A10 | Server-Side Request Forgery (extended) | `owasp_a10_ssrf_ext/` |

## Requirements

- **Bash** 4+ (Linux/macOS; WSL on Windows)
- **Go** 1.20+ — most tools are installed via `go install`
- Standard CLI tools: `curl`, `jq`, `dig`, `git`, `unzip`, `sort`, `awk`,
  `sed`, `grep`, `tee`, `xargs`
- Optional, used if present (everything degrades gracefully if missing):
  `nmap`, `ffuf`, `dirsearch`, `wpscan`, [SecLists](https://github.com/danielmiessler/SecLists)

## Installation

```bash
git clone https://github.com/mrtrojan223/mrtrojan-hunter-v2.git
cd mrtrojan-hunter-v2
chmod +x mrtrojan-hunter.sh install_missing_tools.sh
```

### 1. Install Go (if you don't have it)

```bash
# Debian/Ubuntu/Parrot
sudo apt update && sudo apt install golang-go -y

# or grab the latest directly from https://go.dev/doc/install
```

Make sure `$HOME/go/bin` is on your `PATH`:

```bash
echo 'export PATH=$PATH:$HOME/go/bin:$HOME/.local/bin' >> ~/.bashrc   # or ~/.zshrc
source ~/.bashrc
```

### 2. Run the dependency installer

This installs every recon/scanning tool the framework uses — subdomain
enumeration, HTTP probing, crawling, parameter discovery, XSS/vuln scanning,
screenshots, etc. Each tool gets its own timeout and retries, so one hanging
install can't freeze the rest.

```bash
./install_missing_tools.sh
```

At the end it prints a verification pass showing which tools installed
successfully and which still need attention (with a log file per tool under
`~/.tool_install_logs/` for anything that failed).

### 3. (Optional) Install extras not covered by the installer

A few heavier/optional tools aren't auto-installed — grab what you want:

```bash
sudo apt install nmap -y                       # port/service scanning extras
pip3 install dirsearch                         # directory brute-forcing
sudo gem install wpscan                        # WordPress-specific scanning

# SecLists (wordlists used by ffuf/dirsearch deep scans)
sudo git clone --depth 1 https://github.com/danielmiessler/SecLists /usr/share/seclists
```

### 4. Verify

```bash
./mrtrojan-hunter.sh --help
```

If the colorized logo and the usage/help text print cleanly, you're set.

## Usage

```bash
./mrtrojan-hunter.sh -d target.com [OPTIONS]
```

### Basic examples

```bash
# Full run against a target
./mrtrojan-hunter.sh -d example.com

# With API keys for extra subdomain/OSINT sources
./mrtrojan-hunter.sh -d example.com --github-token ghp_xxx --vt-key abc123 --shodan-key xyz789

# Skip slow phases you don't need
./mrtrojan-hunter.sh -d example.com --skip-portscan --skip-dns

# Deep scan (slower, more thorough: active amass, full port range, big wordlists)
./mrtrojan-hunter.sh -d example.com --deep -t 100

# Custom output directory and a shorter stall-kill timeout
./mrtrojan-hunter.sh -d example.com -o ./results_example --stall-timeout 60

# CI / non-interactive run (no animated splash, no ANSI codes)
./mrtrojan-hunter.sh -d example.com --no-banner
```

### Options

| Flag | Description |
|------|-------------|
| `-d, --domain` | **Required.** Target domain |
| `-o, --output` | Output directory (default: `./mth_<domain>_<date>`) |
| `--github-token` | GitHub API token (subdomain scraping) |
| `--vt-key` | VirusTotal API key |
| `--shodan-key` | Shodan API key |
| `--collaborator` | Burp Collaborator / OAST URL (blind SSRF/XSS callbacks) |
| `--bxss` | Blind XSS callback endpoint |
| `-t, --threads` | Threads (default: `50`) |
| `-r, --rate` | Rate limit, req/s (default: `100`) |
| `-w, --wordlist-dir` | SecLists base dir (default: `/usr/share/seclists`) |
| `--nuclei-templates` | Nuclei templates dir (default: `~/nuclei-templates`) |
| `--stall-timeout` | Seconds of zero output before a stalled tool is killed (default: `120`) |
| `--deep` | Enable deep/slow scans (active amass, full port scan, big wordlists) |
| `--no-banner` | Skip the startup logo/splash (useful for CI, logs, piping) |
| `-v, --verbose` | Verbose output |
| `-h, --help` | Show help |

### Skip flags

Disable any single phase: `--skip-subdomain`, `--skip-dns`, `--skip-portscan`,
`--skip-webprobe`, `--skip-crawl`, `--skip-params`, `--skip-dirscan`,
`--skip-js`, `--skip-sqli`, `--skip-xss`, `--skip-lfi`, `--skip-ssrf`,
`--skip-redirect`, `--skip-cors`, `--skip-takeover`, `--skip-nuclei`,
`--skip-secrets`, `--skip-tech`, `--skip-cloud`, `--skip-wordpress`,
`--skip-report`.

## Output

Each run creates `mth_<domain>_<timestamp>/` (or your `-o` path) with one
numbered subdirectory per phase, plus one `owasp_a0X_*` directory per OWASP
module:

```
mth_example.com_20260101_120000/
├── 00_meta/            – run log
├── 01_subdomains/      – all_subdomains.txt, dns_resolved.txt, source-by-source results
├── 02_dns/             – ASN/IP intel, zone transfer attempts, SPF/DMARC/DKIM
├── 03_portscan/        – naabu/nmap results
├── 04_webprobe/        – alive_urls.txt, tech stack, screenshots, missing headers
├── 05_crawl/           – all_urls.txt, sensitive file URLs, robots/sitemap
├── 06_params/          – parameterized URLs, gf pattern matches
├── 07_dirscan/         – directory brute-force, .git exposure, backup files
├── 08_javascript/      – JS files, extracted secrets, API endpoints
├── 09_sqli/ … 16_nuclei/  – per-vulnerability-class results
├── 17_secrets/         – exposed config files, grepped secrets
├── 19_cloud/           – S3/GCP/Azure bucket enumeration
├── 20_wordpress/       – WPScan results, XML-RPC checks
├── owasp_a01_access_control/ … owasp_a10_ssrf_ext/
└── 99_report/
    └── report.md       – final summary + all confirmed findings
```

Open `99_report/report.md` first — it links out to every file with actual
findings.

## Companion script

`install_missing_tools.sh` can also be run standalone any time to catch up on
newly-missing tools (e.g. after a fresh machine setup, or if a tool update
broke something) — it's idempotent and safe to re-run.

## Disclaimer

Provided as-is, for educational and authorized-testing purposes only. The
author is not responsible for misuse or damage caused by this tool.
