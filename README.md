🗂️ Automated Backup System
📘 Overview

The Automated Backup System is a Bash-based tool that automatically creates, verifies, and manages backups of important directories.
It ensures that your data remains safe by compressing folders, verifying integrity through checksums, and maintaining a clean backup rotation policy.

This project is designed for Linux/Mac (bash) and works well on Windows Git Bash too.

⚙️ Features

✅ Automated Backups – Creates .tar.gz backups of any directory you choose.
✅ Checksum Verification – Verifies backup integrity using SHA-256 checksums.
✅ Backup Rotation – Automatically deletes old backups according to configurable rules.
✅ Configurable Exclusions – Skip unwanted folders like .git, node_modules, .cache, etc.
✅ Dry Run Mode – Simulate a backup run without modifying anything.
✅ Lock Protection – Prevents multiple concurrent backup runs.
✅ Logging – Tracks every action with timestamps in backup.log.
✅ Restore Function – Restore any backup to a directory of your choice.
✅ List Command – Displays all available backups with sizes and dates.
✅ Disk Space Check – Ensures enough free space before starting.
✅ Email Simulation (optional) – Simulates success/failure notifications via a log file.

🧰 Project Structure
backup-system/
│
├── backup.sh              # Main backup automation script
├── backup.config          # Configuration file for user-defined settings
├── README.md              # Project documentation
│
├── logs/
│   ├── backup.log         # Records all backup operations
│   └── last_email.txt     # Simulated email notifications (optional)
│
├── backups/
│   ├── backup-2025-11-09-1200.tar.gz
│   ├── backup-2025-11-09-1200.tar.gz.sha256
│   └── ...
│
└── test_data/
    ├── documents/
    ├── media/
    ├── data.log
    └── data.lo

⚙️ Configuration File (backup.config)

The configuration file defines paths, exclusions, and retention settings.

# backup.config

# Folder to back up
BACKUP_SOURCE="./test_data"

# Destination folder for backups
BACKUP_DESTINATION="./backups"

# Skip these folders from backup
EXCLUDE_PATTERNS=".git,node_modules,.cache"

# How many backups to keep
DAILY_KEEP=7
WEEKLY_KEEP=4
MONTHLY_KEEP=3

# Log file path
LOG_FILE="./logs/backup.log"

# Prevent multiple runs
LOCK_FILE="/tmp/backup.lock"

# Optional email simulation (writes to file)
EMAIL_SIM_FILE="./logs/last_email.txt"

# Minimum free space (MB)
MIN_FREE_MB=50

🚀 How to Use
🧩 1. Give Permission

Make the script executable:

chmod +x backup.sh

📦 2. Create a Backup

Run:

./backup.sh test_data


✅ Output:

[2025-11-09 12:00:10] INFO: Starting backup for ./test_data
[2025-11-09 12:00:15] SUCCESS: Created backup ./backups/backup-2025-11-09-1200.tar.gz
[2025-11-09 12:00:15] SUCCESS: Checksum verified


A backup .tar.gz and .sha256 file will appear in the backups/ folder.

🧪 3. Dry Run (Simulation)
./backup.sh --dry-run test_data


✅ Output:

[INFO] DRY RUN: Would create archive: backup-2025-11-09-1200.tar.gz
[INFO] DRY RUN: Would create checksum file
[INFO] DRY RUN: Would run rotation policy


No files are actually created or deleted.

🧾 4. List Available Backups
./backup.sh --list


✅ Example Output:

-rw-r--r-- 1 user user 15K Nov 9 12:00 backup-2025-11-09-1200.tar.gz
-rw-r--r-- 1 user user 120 Nov 9 12:00 backup-2025-11-09-1200.tar.gz.sha256

🔁 5. Automatic Rotation (Cleanup)

The script automatically deletes old backups based on these rules:

Keep last 7 daily backups

Keep last 4 weekly backups

Keep last 3 monthly backups

✅ Log Example:

[2025-11-09 12:05:00] INFO: Deleting old backup: backups/backup-2025-10-29-1100.tar.gz

♻️ 6. Restore a Backup
./backup.sh --restore backup-2025-11-09-1200.tar.gz --to ./restored_files


✅ Output:

[2025-11-09 12:10:15] SUCCESS: Restored backup to ./restored_files

🛑 7. Lock File Protection

If another backup is already running:

[2025-11-09 12:12:00] ERROR: Another backup is running. (Lock file exists)

💽 8. Check Backup Integrity (Manual)

You can verify a backup manually anytime:

sha256sum -c backups/backup-2025-11-09-1200.tar.gz.sha256


✅ Output:

backups/backup-2025-11-09-1200.tar.gz: OK

🧠 How It Works
🧩 Backup Creation

Script reads settings from backup.config

Uses tar -czf to compress target directory

Skips excluded folders

Generates SHA256 checksum and verifies it

Logs all events to backup.log

🔁 Rotation Algorithm

Sorts all backups by creation date (newest → oldest)

Keeps:

Last 7 distinct days

Last 4 distinct weeks

Last 3 distinct months

Deletes anything older

Removes matching .sha256 files

🔐 Checksum Verification

After backup creation, script runs:

sha256sum -c backup.tar.gz.sha256


If mismatch or missing file → logs error and marks backup as failed.

⚙️ Lock Mechanism

Creates /tmp/backup.lock when started.

If file exists → prevents duplicate run.

Automatically removed when script exits or stops.

🧩 Design Decisions
Feature	Decision
Checksum	Used SHA-256 (more secure and modern than MD5)
Compression	.tar.gz chosen for cross-platform compatibility
Config file	Allows full customization without editing script
Rotation policy	Greedy algorithm ensuring daily/weekly/monthly quotas
Logging	Human-readable timestamp format
Dry-run mode	Safe preview feature for users
Lock file	Prevents race conditions when running from cron or manually
🧪 Testing Performed
Test Case	Command	Expected Result
Create backup	./backup.sh test_data	Backup created successfully
Verify checksum	sha256sum -c backup.tar.gz.sha256	OK
Dry run	./backup.sh --dry-run test_data	Only logs actions
List backups	./backup.sh --list	Shows available backups
Restore backup	./backup.sh --restore backup.tar.gz --to restored/	Files restored
Lock file test	Run twice	Second run blocked
Rotation test	Run >7 backups	Old ones deleted
Missing config	Rename config	Script prints error and exits
🧩 Example Log Output
[2025-11-09 12:00:10] INFO: Starting backup ./test_data
[2025-11-09 12:00:15] SUCCESS: Created backup ./backups/backup-2025-11-09-1200.tar.gz
[2025-11-09 12:00:15] INFO: Created checksum file ./backups/backup-2025-11-09-1200.tar.gz.sha256
[2025-11-09 12:00:15] SUCCESS: Checksum verified
[2025-11-09 12:00:16] INFO: Rotation complete
[2025-11-09 12:00:17] INFO: Backup run completed successfully

⚠️ Known Limitations

The script is designed for local backups, not remote servers.

Incremental backups (only changed files) are not yet implemented.

Email notifications are simulated (no actual SMTP integration).

Date parsing for week/month rotation depends on system date command compatibility.

🧩 Future Improvements

Add real email/SMS notifications

Add incremental and differential backup modes

Integrate remote backup (e.g., AWS S3 or SCP)

Add progress bar for large backups

👩‍💻 Author

Thanusha2002
DevOps Enthusiast | Automation Learner | GitHub Contributor

🔗 GitHub: @Thanusha2002

🧾 License

This project is released under the MIT License.
You can freely modify and share it with proper attribution.

✅ Summary

Your Automated Backup System is now:

Feature-complete 🟢

Verified & tested 🟢

Professionally documented 🟢
