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

It prints the overall status (`mdutil -s /`) and then keeps an eye on the files
being indexed. It only prints when the state changes, to avoid flooding the
screen while the same file is being processed. Press `Ctrl+C` to stop.

When a file is being scanned it prints the volume and the file. When there is
indexing activity but no user file is capturable at that instant, it prints a
short `indexing...` line; when there is no activity at all, a `waiting...` line.

Each file entry shows:
- The volume and the current size of its Spotlight index (`.Spotlight-V100`).
- The file (directory + name) currently being scanned.

## How it works

- `mdutil -s /` gives the general indexing state.
- Spotlight does the heavy lifting with `mdworker_shared` processes. The script
  samples the most active ones and, via `lsof`, shows the user file they have
  open in read mode — that is the file being scanned right now.
- The volume name comes from `diskutil` (e.g. "Macintosh HD"). The index size is
  refreshed each printed round with `du -sk` on that volume's `.Spotlight-V100`
  folder, so you can watch it grow while indexing.

## Example output

```
/:
	Indexing enabled.

===========================================================
 Following the file Spotlight is indexing right now...
 Press Ctrl+C to stop.
===========================================================

[19:52:14] Volume: Macintosh HD | Index size: 3,4 GB
Users/fede/Downloads/cheat0264 2/cheat/zx81_cass/
fangamesp.xml
indexing... (no user file capturable right now)
waiting... (no indexing activity right now)
```

## Disclaimer

This script only reads process info and shows you what Spotlight is doing. It
does not modify, delete, or disable anything.
