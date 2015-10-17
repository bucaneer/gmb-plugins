Custom plugin for (gmusicbrowser)[https://github.com/squentin/gmusicbrowser].

Installation: copy file to ~/.config/gmusicbrowser/plugins

## Precache

Aids gapless playback by caching (the beginning of) the next song in virtual memory (i.e. RAM). Eliminates the likeliest cause of gaps between songs when using mpv and gstreamer backends; mplayer can't be truly gapless due to design limitations.

Requires (vmtouch)[https://github.com/hoytech/vmtouch] (version >=1.0.1 needed for partial cache)