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

It prints the overall status (`mdutil -s /`) and then keeps showing the file
that is being indexed, refreshing every second. Press `Ctrl+C` to stop.

## How it works

- `mdutil -s /` gives the general indexing state.
- Spotlight does the heavy lifting with `mdworker_shared` processes. The script
  picks the one using the most CPU and, via `lsof`, shows the user file it has
  open in read mode — that is the file being scanned right now.

## Example output

```
/:
	Indexing enabled.

===========================================================
 Following the file Spotlight is indexing right now...
 Press Ctrl+C to stop.
===========================================================

[18:45:38] /Volumes/Development/PHP/demo/vendor/swiftmailer/swiftmailer/tests/_samples/smime/encrypt2.key
[18:45:39] /Volumes/Development/PHP/demo/vendor/swiftmailer/swiftmailer/tests/_samples/smime/encrypt2.key
[18:45:40] /Volumes/Development/PHP/demo/vendor/swiftmailer/swiftmailer/tests/_samples/smime/encrypt2.key
```

## Disclaimer

This script only reads process info and shows you what Spotlight is doing. It
does not modify, delete, or disable anything.
