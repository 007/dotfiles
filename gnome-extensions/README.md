First, set up glib schema for the impatience extension:
```
sudo cp impatience@gfxmonk.net/schemas/org.gnome.shell.extensions.net.gfxmonk.impatience.gschema.xml /usr/share/glib-2.0/schemas/
```

Then, link each extension dir where `gnome-shell` can find it:
```
cd ~/.local/share/gnome-shell/extensions/
for i in ~/dotfiles/gnome-extensions/*; do
  ln -snf $i
done
```

Then restart `gnome-shell` with Alt-F2 and `r`, and launch `gnome-tweak-tool` to enable and configure your extensions.
