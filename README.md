# 1. How to install

### 1. Install online

```bash
curl  https://github.com/PierNola/BackupBG/raw/master/backup.sh | sh -s installonline
```

Or:

```bash
wget -O -  https://github.com/PierNola/BackupBG/raw/master/backup.sh | sh -s installonline
```

### 2. Install online in a specific directory

```bash
curl  https://github.com/PierNola/BackupBG/raw/master/backup.sh | sh -s installonline <customdir>
```

Or:

```bash
wget -O -  https://github.com/PierNola/BackupBG/raw/master/backup.sh | sh -s installonline <customdir>
```

### 3. Install description
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
