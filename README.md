# ZZ⚡Top

ZZ⚡Top is a deceptively simple plug-in manager for
[Zsh](http://www.zsh.org/). It was written out of frustration with the
existing ones, and to ease [local plug-in development](#local-development)
while still allowing fetching plug-ins using Git as a fall-back. Other
goals are avoiding bloat, focusing on the essentials, and staying *both*
under 500 LOC and 8 KiB.

This software and its documentation is distributed under the terms of
the [MIT license](https://opensource.org/licenses/MIT).


## Installation

### Simple

Just download and source `everything.zsh`, which is self-contained:

```sh
mkdir -p ~/.zsh/zz-top
wget -O ~/.zsh/zz-top/everything.zsh \
    https://github.com/aperezdc/zz-top/raw/master/everything.zsh
```

### Recommended

Cloning the Git repository is recommended, as it allows for updating more
easily:

```sh
mkdir -p ~/.zsh
git clone https://github.com/aperezdc/zz-top ~/.zsh/zz-top
```

## Usage

Source `everything.zsh` from your Zsh configuration file, and use `zz-top`
to load plugins:

```sh
source ~/.zsh/zz-top/everything.zsh
zz-top Tarrasch/zsh-autoenv           # From GitHub
zz-top git://githost.com/myproject    # From a custom URL
zz-top ~/devel/zsh/virtualz           # Local plug-in
```

Note that this will immediately load the plug-ins, which means the loading
order or completely up to the user. ZZ⚡Top does *not* even attempt to handle
dependencies: just reorder your plug-in load lines as needed.

The next time you run Zsh (hint: replace the running instance with `exec zsh`)
you will be informed about missing plug-ins. Instead of loading them, they
will be marked as pending fo installation. Note that each missing plug-in is
reported only once:

```
 :: zz-top: Missing: zsh-autoenv
```

Running `zz-top` without arguments will install the missing plug-ins and
update the ones which were already installed.

Last but not least, the environment is only ever updating when loading
plug-ins during Zsh startup. Active sessions *will not* automatically pick
uploaded or newly installed plug-ins until they are ran again (again, feel
free to use `exec zsh` liberally to replace the running instance of the
shell).


### Checking for Loaded Plug-Ins

ZZ⚡Top allows checking whether a certain plug-in has been successfully
loaded. This can be used to skip parts of your Zsh configuration which may
fail otherwise:

```sh
if zz-top --loco zsh-notes ; then
    bindkey '^N' notes-edit-widget
fi
```

### Graceful Degradation

Sometimes it may be desirable to skip loading plug-ins when ZZ⚡Top is not
installed. This can be done by sourcing `everything.zsh` only when it is
present, and providing a dummy `zz-top` function:

```sh
if [[ -r ~/.zsh/zz-top/everything.zsh ]] ; then
    source ~/.zsh/zz-top/everything.zsh
else
    # Always produces a non-zero return code for --loco.
    function zz-top { [[ ${1:-} != --loco ]] ; }
fi

# No-op when the script was not sourced.
zz-top aperezdc/zsh-notes

# Only apply configuration when a certain plug-in is known to be loaded
if zz-top --loco zsh-notes ; then
    bindkey '^N' notes-edit-widget
fi
```


### Local Development

One of the main motivations behind ZZ⚡Top was that reusing the same Zsh
configuration file in multiple machines, while easily allowing for using local
copies of a plug-in when available. Using `--local` will load the version from
the specified local directory if available, and fall-back to installing the
plug-in if not. This is a [snippet from the author's configuration
file](https://github.com/aperezdc/dotfiles/blob/d2aea9ad7d4134c09f3a7be761901bfc95541c7d/dot.zsh--rc.zsh#L34-L36):

```sh
zz-top aperezdc/zsh-notes --local ~/devel/zsh-notes
zz-top aperezdc/virtualz --local ~/devel/virtualz
zz-top aperezdc/rockz --local ~/devel/rockz
```

