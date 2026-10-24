# Capture and Sharing

Read this before taking screenshots or screen recordings, extracting text from
the screen, or sharing files with other machines.

## Screenshots

```bash
doxia screenshot                            # Interactive smart-region flow
doxia capture screenshot region             # Select a region
doxia capture screenshot windows            # Pick a window
doxia capture screenshot fullscreen save    # Full screen, straight to disk (no editor)
```

The first argument picks the mode (`smart|region|windows|fullscreen`), the
second what happens with it (`slurp|copy|save`). `save` skips the annotation
editor and prints the saved path. Screenshots land in the configured Pictures
directory (override with `DOXIA_SCREENSHOT_DIR`).

## Screen Recording

```bash
doxia screenrecord --fullscreen             # Start recording the full screen
# ...exercise whatever you want on film...
doxia screenrecord --stop-recording         # Stop; prints the saved path
```

Optional flags: `--with-desktop-audio`, `--with-microphone-audio`,
`--with-webcam` (plus `--webcam-device=` and `--webcam-size=`), and
`--resolution=<size>`. Without `--fullscreen` a region picker opens first.
Recordings land in the configured Videos directory (override with
`DOXIA_SCREENRECORD_DIR`). Resize a live webcam overlay with
`doxia capture webcam resize <smaller|larger|reset|small|medium|large>`.

If recording fails to start, rerun with `DOXIA_SCREENRECORD_DEBUG=true` to
collect a log at `/tmp/doxia-screenrecord.log` worth attaching to a bug
report.

## Text Capture (OCR)

```bash
doxia capture text    # Select a region; extracted text goes to the clipboard
```

## Sharing Files

```bash
doxia share clipboard               # Share the clipboard via LocalSend
doxia share file <path...>          # Share files with nearby devices
doxia share folder <path>           # Share a folder

doxia tailscale send <machine> <file...>    # Taildrop to a tailnet machine
doxia tailscale receive [directory]         # Save incoming Taildrop files
```

Shrink large captures before sharing them:

```bash
doxia transcode <input> [format] [resolution]   # Re-encode pictures/videos for sharing
```
