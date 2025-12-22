# Digital Rain Effect for the Commodore VIC-20

This project is a "digital rain" effect demo (created for the movie The Matrix)
targetted for the Commodore VIC-20.

## Requirements for Building

* cc65 installed (includes ca65 assembler).
* Make (for building via the `Makefile`
* Optional: VICE emualtor (xvic) for testing.

## Building

1. Clone the repository
```
git clone https://github.com/dcgibbons/digital-rain.git
cd digital-rain/vic-20
```
2. Build the project using the supplied `Makefile`:
```
make
```

This will compile the assembly sources with ca65 and link them into a runnable
cartridge binary.

3. If you wish to build the `.prg` format version, then use:
```
make prg
```

## Running in VICE

1. Run the binary with the VICE VIC-20 emualtor (assumes `xvic` is in your
   `PATH`):
```
make run
```

Alternatively, you can run the `.prg` version with:
```
make run_prg
```

## Running on Real Hardware

You can use the `.prg` file directly with a SD2IEC drive emulator and load it
on real hardware. This particular implementation requires an unexpanded
VIC-20 memory configuration, so configure your hardware for the default 5KB
of RAM.

## Screenshots

![Demo Screenshot](demo.gif)

