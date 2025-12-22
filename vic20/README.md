# Digital Rain Effect for the Commodore VIC-20

This project is a "digital rain" effect demo (created for the movie The Matrix)
targetted for the Commodore VIC-20.

There are two build options

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

## Running on Real Hardware / Universal PRG
You can use the `.prg` file (`vic20_digital_rain.prg`) with an SD2IEC or other
loader.

**This file is a Universal Relocatable Binary.** It supports:
- **Unexpanded VIC-20** (5KB RAM)
- **+3K / +8K / +16K / +24K Expansion**

To run it, you **MUST use Relocatable Loading** (`,8`):
```basic
LOAD "*",8
RUN
```
**DO NOT use `,8,1`**. The program relies on the BASIC loader to place it in
the correct memory location for your specific hardware configuration. A
built-in relocator will then move the machine code to a safe execution area
(`$1300`) automatically.

## Screenshots

![Demo Screenshot](demo.gif)
