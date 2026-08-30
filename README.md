# Mac-Spotlight-status

A simple bash script to get more info on what Spotlight is indexing.

Sometimes Spotlight indexing status is unclear. It just says "Indexing" and there
is no way to tell if there is any real progress or if it is stuck on a folder.

I made a script to show, in real time, **in what file** the indexing process
(mdworker_shared) is currently working on, the same way I did for Time Machine
in [Mac-Time-Machine-status](https://github.com/fedekrum/Mac-Time-Machine-status).

It must be run as root, so you will be prompted for credentials if you are not.

No modification is made on any file and no risky commands are run on the script
as you can check.

## Usage

```bash
sudo ./SpotlightStatus.sh
```

While it runs you will see one of three things:

- **A file** → Spotlight is currently scanning that file.
- **`indexing...`** → there is indexing activity, but at that exact split
  second no user file was open to capture (files open and close fast).
- **`waiting...`** → no indexing activity at all right now.

It only prints when the **state changes**, so it does not flood the screen
while Spotlight stays on the same file. Press `Ctrl+C` to stop.

Each file entry shows:
- The volume and the current size of its Spotlight index (`.Spotlight-V100`).
- The file (directory + name) currently being scanned.

## How it works — what it does

Spotlight tells you *"Indexing"*, but not **what** it is doing. This script
sits behind Spotlight and shows you the actual file it is scanning, so you can
tell it is moving forward and not stuck. It only **reads** process info and
prints it — it does not touch, delete, or modify any file.

## How it works — how it does it

### Background

Spotlight indexes through two kinds of processes:

- `mds` / `mds_stores` — the metadata server keeping the index database.
- `mdworker_shared` — workers that walk the disk and read each file to build
  its metadata.

When indexing, several `mdworker_shared` run at once, each holding an **open
file descriptor** to the file it is currently reading. That descriptor tells us
exactly which file is being scanned right now.

### The loop

Every `0.2` seconds the script repeats:

1. **Make sure it runs as root** — `sudo lsof` and `du` on the index need
   privileges, so if needed it re-launches with `sudo`. If there is no
   `mds_stores`, indexing is not happening and it exits early.

2. **Print the official status** — `mdutil -s /` shows whether indexing is on.

3. **Find the active workers** — list processes, keep the `mdworker_shared`
   ones. `LC_ALL=C` forces a dot as decimal separator in `%CPU`, which in
   Spanish-locale Macs would otherwise be a comma and break sorting.

4. **Find what file a worker is reading** — `sudo lsof` lists the worker's open
   file descriptors. We keep those opened in read mode (`r`) on a regular file
   (type `REG`) with a real path, then **discard the "infrastructure" ones**
   (the index itself `.Spotlight-V100`, system libraries in `/usr` and
   `/System`, `dyld`, `.csstore`, `/dev`). What's left is the **user file**
   being scanned. The script tries the active workers in turn and keeps the
   first one that has such a file open.

5. **Build the status** — a real file, or `__INDEXING__` (workers active but no
   capturable file), or `__IDLE__` (nothing active).

6. **Print only if the status changed** — to avoid spam.

7. **When printing a real file**, build the block:

   - **Volume name** → derive the volume from the path (`/Users/...` is the
     system volume; `/Volumes/<X>/...` is volume `<X>`). The real system name
     (e.g. "Macintosh HD") comes from `diskutil`.
   - **Index size** → `du -sk` on that volume's `.Spotlight-V100` folder,
     formatted nicely. This only runs when we are about to print. On APFS the
     system index lives at `/System/Volumes/Data/.Spotlight-V100`.
   - **Relative path** → split the full path into the relative directory
     (volume stripped) and the file name, then print the block.

## Example output

```
/:
	Indexing enabled.

===========================================================
 Following the file Spotlight is indexing right now...
 Press Ctrl+C to stop.
===========================================================

[20:02:29] Volume: Macintosh HD | Index size: 3,6 GB
Users/fede/Downloads/cheat0264/cheat/
.DS_Store
indexing... (no user file capturable right now)
waiting... (no indexing activity right now)
```

## Disclaimer

This script only reads process info and shows you what Spotlight is doing. It
does not modify, delete, or disable anything.
