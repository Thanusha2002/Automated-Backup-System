Automated Backup System
A. Project Overview

What the script does

backup.sh is a small Bash utility that:

.Creates compressed archives of a chosen source folder (tar.gz).

.Saves a SHA-256 checksum file for each archive.

.Can list available backups.

.Can restore (extract) a chosen backup into a target directory (safe default).

.Performs a simple retention/rotation to keep only the newest N backups.

.Uses a PID lock to avoid running two backups at the same time.

.Writes messages to backup.log.

Why this is useful

.Keeps copies of important files in a compressed, verifiable format.

.Checksums protect against accidental corruption.

.Easy to restore files or full project state if something is deleted or broken.

B. How to Use It
Requirements

.bash (4+ recommended)

.tar (gz support)

.sha256sum (or openssl as fallback)

.Git Bash / WSL or Linux environment recommended on Windows.

Installation

.Clone or copy repository to your machine:

git clone <your-repo-url> backup-system
cd backup-system


.Make the script executable:

chmod +x backup.sh


.Edit backup.config to match your environment (see configuration below).

Configuration (backup.config)

Example:

SOURCE_DIR=./test_data
BACKUP_DIR=./backups
RETENTION_KEEP=3
EXCLUDE_FILE=./backup.exclude

Basic usage examples

Create a new backup (default):

./backup.sh


List available backups:

./backup.sh --list


Restore a backup into ./restored:

./backup.sh --restore backup-2025-11-06-2132.tar.gz --to ./restored


Dry-run (show what would be done but do not create archive):

./backup.sh --dry-run


Show checksum verification:

sha256sum -c backups/backup-2025-11-06-2132.tar.gz.sha256


Restore a single file from the archive:

tar -tzf backups/backup-2025-11-06-2132.tar.gz | grep path/you/want
tar -xzf backups/backup-2025-11-06-2132.tar.gz -C ./restored path/inside/archive/file.txt

C. How It Works
Folder structure produced by the script
backup-system/
├── backups/
│   ├── backup-2025-11-06-2132.tar.gz
│   ├── backup-2025-11-06-2132.tar.gz.sha256
│   ├── backup-2025-11-06-2226.tar.gz
│   └── ...
├── logs/
│   └── backup.log
├── test_data/
│   └── ...  # files you backed up
├── backup.config
└── backup.sh

How we create checksums

After creating backup-YYYY-MM-DD-HHMM.tar.gz the script runs:

sha256sum "$archive" > "$archive.sha256"


This creates a file with the checksum and the archive filename. To verify:

sha256sum -c "$archive.sha256"


If sha256sum is not available, the script can fallback to openssl dgst -sha256 (compare output manually).

Rotation algorithm (simple, robust)

Algorithm used:

Keep RETENTION_KEEP most recent backups (value from backup.config).

Determine backups by filename timestamps (lexicographic sort works with YYYY-MM-DD-HHMM).

Delete older backups and their .sha256 files.

Rotation snippet (conceptual):

# find archive files (sorted newest first) and delete older than RETENTION_KEEP
backups=( $(ls -1t "$BACKUP_DIR"/backup-*.tar.gz 2>/dev/null) )
if [ "${#backups[@]}" -gt "$RETENTION_KEEP" ]; then
  to_delete=( "${backups[@]:$RETENTION_KEEP}" )
  for f in "${to_delete[@]}"; do
    rm -f "$f" "$f.sha256"
  done
fi


ls -1t sorts by modification time (newest first). Using the timestamp in the filename also works and is consistent.

D. Design Decisions

Why this approach

tar.gz chosen for wide compatibility and simplicity.

sha256sum chosen because SHA-256 is a strong, broadly available checksum tool.

PID lock prevents multiple simultaneous backups which could corrupt archives or exhaust disk I/O.

Extracting into a restored directory by default to avoid accidental overwrite.

Challenges & solutions

Windows path differences — solution: recommend Git Bash or WSL.

Missing tools (sha256sum) — fallback to openssl.

Atomic operations — create the archive with a temporary name then rename into backups/ when complete.

E. Testing
Test folder creation

Create a test_data folder and add sample files:

mkdir -p test_data
echo "first file" > test_data/file1.txt
echo "second file" > test_data/file2.txt
mkdir -p test_data/documents
echo "doc" > test_data/documents/doc1.txt

Example: Creating a backup

Run:

./backup.sh


Expected log lines (similar to screenshot):

[2025-11-06 21:31:30] DRY RUN: Would create tarball /c/Users/lenovo/backups/backup-2025-11-06-2131.tar.gz
[2025-11-06 21:32:23] INFO: Creating backup backup-2025-11-06-2132.tar.gz
[2025-11-06 21:32:23] SUCCESS: Created backup /c/Users/lenovo/backups/backup-2025-11-06-2132.tar.gz
[2025-11-06 21:32:23] INFO: Created checksum file /c/Users/lenovo/backups/backup-2025-11-06-2132.tar.gz.sha256
[2025-11-06 21:32:23] SUCCESS: Checksum verified

Creating multiple backups over several "days" (fake dates)

Simplest: create backups with different timestamped names by passing an override environment variable or by running the script and creating archives with chosen filenames. Example (manual approach):

# safe manual method: create archives with chosen timestamps
cp -r test_data test_data_snapshot
tar -czf backups/backup-2025-11-01-1200.tar.gz test_data_snapshot
sha256sum backups/backup-2025-11-01-1200.tar.gz > backups/backup-2025-11-01-1200.tar.gz.sha256

# make a second fake-day backup
tar -czf backups/backup-2025-11-02-1200.tar.gz test_data_snapshot
sha256sum backups/backup-2025-11-02-1200.tar.gz > backups/backup-2025-11-02-1200.tar.gz.sha256


Alternatively, add an environment variable in the script to override timestamp:

TS=${TS_OVERRIDE:-$(date +"%Y-%m-%d-%H%M")}
archive="backup-${TS}.tar.gz"


Then call:

TS_OVERRIDE=2025-11-01-1200 ./backup.sh
TS_OVERRIDE=2025-11-02-1200 ./backup.sh

Automatic deletion of old backups

With RETENTION_KEEP=3, create 4+ backups and run script — older ones should be removed. Example log lines:

[2025-11-08 10:00:00] INFO: Rotation: keeping 3 newest backups
[2025-11-08 10:00:00] INFO: Deleted old backup backup-2025-10-30-0900.tar.gz

Restoring from a backup

Extract into ./restored:

./backup.sh --restore backup-2025-11-06-2132.tar.gz --to ./restored
# then inspect restored/
ls -la restored

Dry run mode

If --dry-run is implemented:

./backup.sh --dry-run
# Output example:
[2025-11-06 21:31:30] DRY RUN: Would create tarball /c/Users/lenovo/backups/backup-2025-11-06-2131.tar.gz

Error handling example

Try backing up a non-existent folder:

SOURCE_DIR=./no_such_folder ./backup.sh


Expected behavior:

.Script prints a helpful error:

[2025-11-06 21:40:00] ERROR: Source directory not found: ./no_such_folder


.Exits non-zero without creating files.

F. Known Limitations

.Permissions/ownership on Windows: Unix permissions may not be preserved on NTFS / Git Bash.

.No encryption: backups are stored as plain tar.gz (you can add gpg encryption later).

.Rotation is a simple “keep N newest” algorithm — no daily/weekly/monthly buckets.

.No remote copy / cloud sync included — only local backups.

.Large backups could take time; no parallel chunking/rsync delta support.

Extra ideas (future improvements)

1.Add gpg encryption option.

2.Add remote sync (rsync / rclone).

3.Improve rotation to support monthly/weekly/daily retention buckets.

4.Add email alert on failure.

5.Add incremental backups using tar --listed-incremental or rsync.
