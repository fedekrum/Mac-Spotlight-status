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

It prints the overall status (`mdutil -s /`) and then keeps showing, for each
file being indexed, the volume it belongs to and that volume's index size.
Press `Ctrl+C` to stop.

Each line pair shows:
- The volume and the current size of its Spotlight index (`.Spotlight-V100`).
- The file (directory + name) currently being scanned.

## How it works

- `mdutil -s /` gives the general indexing state.
- Spotlight does the heavy lifting with `mdworker_shared` processes. The script
  picks the one using the most CPU and, via `lsof`, shows the user file it has
  open in read mode — that is the file being scanned right now.
- The volume is derived from the file path, and the index size is refreshed
  each round with `du -sk` on that volume's `.Spotlight-V100` folder, so you
  can watch it grow while indexing.

## Example output

```
/:
	Indexing enabled.

===========================================================
 Following the file Spotlight is indexing right now...
 Press Ctrl+C to stop.
===========================================================

[19:06:54] Volume: Development | Index size: 4,0 GB
PHP/qrvcard/phpqrcode/
.DS_Store
[19:06:55] Volume: Development | Index size: 4,0 GB
PHP/qrvcard/phpqrcode/
.DS_Store
```

## Disclaimer

This script only reads process info and shows you what Spotlight is doing. It
does not modify, delete, or disable anything.
