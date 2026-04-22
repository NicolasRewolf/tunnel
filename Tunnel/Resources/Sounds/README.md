# Ringtone resources

The default bundled ringtone is `default_ringtone.wav`. The runtime
`RingtonePlayer` will look up any of these extensions for a configured
ringtone name, in this order:

- `.caf`
- `.m4a`
- `.wav`
- `.mp3`

So you can drop in a `.caf` to override the default without touching the code.

If no bundled file is found, Tunnel falls back to a repeated system sound so
incoming fake calls remain audible in development builds.

The Xcode 16 project uses `PBXFileSystemSynchronizedRootGroup`, so any audio
file added to this folder is automatically included in the app bundle.
