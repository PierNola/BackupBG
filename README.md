# Backup utility for PostgreSQL databases

## Summary
Linux backup utility for PostgreSQL databases for linux.

Supports the following postgreSQL versions
-   postgresql-12.X
-   postgresql-11.X
-   postgresql-10.X

## How to install

### Install online

```bash
curl  https://raw.githubusercontent.com/PierNola/BackupBG/main/backup.sh | sh -s installonline
```

Or:

```bash
wget -O -  https://raw.githubusercontent.com/PierNola/BackupBG/main/backup.sh | sh -s installonline
```

### Install online in a specific directory

```bash
curl  https://raw.githubusercontent.com/PierNola/BackupBG/main/backup.sh | sh -s installonline <customdir>
```

Or:

```bash
wget -O -  https://raw.githubusercontent.com/PierNola/BackupBG/main/backup.sh | sh -s installonline <customdir>
```

### Install description
The installer will perform 3 actions:

1. Create and copy `backup.sh` to `/opt/backup` or to a specific directory
2. Create 3 subdirectory :
    - `archive` which contains archived dumps
    - `data` which contains the dumps of the day
    - `log` which contains the logs
3. Create daily cron job to for daily backup.

Cron entry example:

```bash
30 22 * * * /opt/backup/backup.sh --run > /dev/null
```
