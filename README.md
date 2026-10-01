# CloudOps Toolkit

A set of Bash automation scripts for Linux system administration, built as a hands-on project to learn Git workflows, CI/CD, and cloud infrastructure (AWS) from the ground up.

This isn't just a script collection — it's also a record of practicing real engineering workflow: feature branches, pull requests, code review via CI, and now, extending into cloud deployment.

## What's in here

| Script | What it does |
|---|---|
| `backup.sh` | Creates a compressed, timestamped backup of a given folder and keeps the 5 most recent copies |
| `disk-alert.sh` | Checks disk usage and prints a warning if it cross a set threshold (e.g. 80%) |
| `memory-alert.sh` | Checks available memory and alerts if usage crosses a set threshold |
| `log-cleaner.sh` | Deletes or archieves log files older than a set number of days to free up disk space |
| `log-analyzer.sh` | Parses a log file and reports things like error counts, top IPs, or most requested paths |

## How to use

\`\`\`bash
git clone https://github.com/srushtirevoor99-beep/cloudops-toolkit.git
cd cloudops-toolkit
chmod +x scripts/*.sh
\`\`\`

### backup.sh
\`\`\`bash
./scripts/backup.sh /path/to/folder
\`\`\`

### disk-alert.sh
\`\`\`bash
./scripts/disk-alert.sh          # uses default threshold
./scripts/disk-alert.sh 85       # custom threshold, e.g. 85%
\`\`\`

### memory-alert.sh
\`\`\`bash
./scripts/memory-alert.sh
\`\`\`

### log-cleaner.sh
\`\`\`bash
./scripts/log-cleaner.sh /var/log 7     # deletes logs older than 7 days
\`\`\`

### log-analyzer.sh
\`\`\`bash
./scripts/log-analyzer.sh /var/log/nginx/access.log
\`\`\`

## Engineering practices used in this project

- **Feature branches** for each new script/feature, merged via pull request rather than committing directly to `main`
- **GitHub Issues → branch → PR → merge** workflow (used for the `memory-alert.sh` feature)
- Resolved a real **merge conflict**, including a UTF-16 encoding issue in `README.md`
- Used **interactive rebase** to squash commits into a clean history, and **cherry-pick** to move specific commits between branches
- **SSH authentication** set up with GitHub; all branches pushed, with releases tagged (`v0.1.0`, `v0.2.0`)
- **Continuous Integration**: a GitHub Actions workflow (`.github/workflows/lint.yml`) runs [ShellCheck](https://www.shellcheck.net/) on every push and pull request to `main`

## Cloud extension (in progress)

- An EC2 (t2.micro, Ubuntu) instance to run and serve these scripts in a real cloud environment
- `backup.sh` is being modified to upload backups to an **S3 bucket** instead of storing them only locally
- An IAM user/role scoped to **least-privilege S3 access** (not root/admin credentials) for the backup upload

## What I learned

## What I learned

- How to actually resolve a merge conflict instead of just reading about one, including fixing a UTF-16 encoding issue in README.md that made Git treat the whole file as changed
- How to write Bash scripts that take arguments and validate input before running, instead of hardcoding values
- The difference between committing directly to main and using a proper branch → PR → merge workflow, and why it matters even as a solo developer
- How GitHub Actions CI works: writing a workflow file, debugging YAML indentation errors, and getting ShellCheck to pass on every push
- Why using an IAM role with least-privilege access is safer than using AWS root/admin credentials, while extending this project into EC2 and S3

## Setup requirements

- Bash (Linux/WSL2 — developed and tested on Ubuntu via WSL2 on Windows)

## Project status

🚧 Actively being extended — currently adding AWS EC2/S3 integration and IAM-based access control.

---

*Built by [Srushti](https://github.com/srushtirevoor99-beep) while learning Linux, Git, and cloud infrastructure.*