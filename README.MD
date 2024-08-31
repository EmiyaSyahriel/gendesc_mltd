# Gendesc
My tool to pre-process ミリシタバスデーライブ video description for my personal YouTube channel, but should be usable for other kind of videos, Written in V. 

Basically a simple TOML pre-processor with named-key text formatting support.

This project is made as fast as possible. The code quality might be meh.

## Usage
In current directory where `gendesc` is called, there should be a `desc.toml` ( see [sample file](sample/desc.toml) ), just like Makefile and gnu make. The `desc.toml` should contains a `template` key that coresponds to a template file name located in `(gendesc binary directory)/templates/`. 

Just call in the directory:
```
gendesc [section] [options...]
```

Sections specified is generated from the `desc.toml` file keys, including in the template file. with additional section generated after, use `-v` to list all available sections.

### Additional Options
- `-v` Make the program more verbose
- `-c` Copy the result to clipboard ( wayland only )

## Building
I provide no binary ready to download. Please build by yourself.

### Requirements
- V Compiler ( tested on 0.4.7 8ebc288 )
- Any C Compiler ( compatible with all compilers that V supports )
- wl-copy ( only for clipboard usage )

### Steps
```bash
git clone https://github.com/EmiyaSyahriel/gendesc_mltd
cd gendesc_mltd
v .. -o gendesc -prod -cc gcc -skip-unused

# Simple way to install on Linux, requires root
# you may want to make a link in another $PATH paths or modify the $PATH itself instead of this line
sudo ln -s $(pwd)/gendesc /usr/bin/gendesc
```

## Licenses
CC BY 4.0 [(see LICENSE)](LICENSE)
