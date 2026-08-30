# VRChat-ALT

VRChat Any-Local-Test (suck name tbh)

Launch a local `.vrcw` world directly in VRChat.

You might want debug/play any map without EAC, this is basically a 'Launch (No EAC)'
You can't play with your friends, and network still required, all thanks to VRChat Inc they love to know your privacy so hard.

## Windows

- Drop a `.vrcw` file or its folder onto `DirectLocalTest.bat`.
- One-client desktop mode: drop it onto `LocalTest_fast.bat`.
- Double-clicking a launcher asks for a world path. Press Enter without a path to use the newest `.vrcw` below the current directory.

The launcher asks whether to use VR mode. Enter `y` for VR; `n` or an empty answer uses Desktop mode.

The launcher reads Steam's registry entry and `libraryfolders.vdf`, so VRChat can be installed in any Steam library. If detection fails, it asks for `VRChat.exe`. `VRCHAT_PATH` may also point to the executable or its folder.

## Linux

Make the script executable once, then pass or drag a world path into the terminal:

```bash
chmod +x DirectLocalTest.sh
./DirectLocalTest.sh /path/to/world.vrcw
```

With no path argument, the script asks for one. Press Enter without a path to search the current directory.

The launcher uses the same VR question as Windows. An empty answer uses Desktop mode; `--fast` always uses Desktop mode.

Options:

```text
--fast    launch one Desktop client without asking for the client count
```

The script checks the common native and Flatpak Steam locations, Steam library folders, `Proton - Experimental`, installed Proton versions, and `compatibilitytools.d`. If needed, set `VRCHAT_PATH`, `PROTON_PATH`, or `STEAM_COMPAT_DATA_PATH` explicitly.

# How it works
same as what the VRCSDK does, generate 10 length random number and as roomId.

```
string randomDigits = Tools.GetRandomDigits(10);
string text4 = "--url=create?roomId=" + randomDigits + "&hidden=true&name=BuildAndRun&url=file:///" + text;
```

then locate the file with prefix `file:///` + path to `.vrcw`
