# File structure

## Tree view

```txt
.
├── docs
│   ├── Changelog
|   └── Wiki Files and Documentation
├── private
│   ├── Your token and other private/ ...
|   └── ... local data (ignored by git).
├── public
│   ├── Public data such as configs and ...
│   └── ... data for specifig commands.
└── src
    ├── Source files for the discord bot ...
    ├── ... used by the compiler to compile ...
    └── ... into a single executable.
```

## Docs

You can ignore the docs directory, as it houses files like this one, that only help to explain or provide information about the bot and its usage.

## Private

Here all your private data is stored, for example your discord token inside the `token.txt` file. Do not send any of these files to people whom you do not fully trust.

If you have leaked your discord bot token, please reset it immediatly at the [discord developer portal](https://discord.com/developers/applications)!

## Public

This directory houses the files and configs, that do not have sensitive information. Configurations for embed colours and several command resources can be found here.

## Src

This is the source code directory. As the name tells you, this has all `.nim` source files, that the compiler uses to compile to a single executable.
