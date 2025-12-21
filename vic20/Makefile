# --- Project Configuration ---
PROJECT  = vic20_matrix
BUILD_DIR = build
SRC      = $(wildcard *.s)
OBJ      = $(patsubst %.s, $(BUILD_DIR)/%.o, $(SRC))
BIN      = $(BUILD_DIR)/$(PROJECT).bin
CRT      = $(BUILD_DIR)/$(PROJECT).crt
MAP      = $(BUILD_DIR)/$(PROJECT).map
LABELS   = $(BUILD_DIR)/$(PROJECT).lbl

# --- Paths ---
INC_DIR  = ./
CFG_FILE = ./vic20-cart.cfg

# --- Tools ---
CA65     = ca65
CL65     = cl65
CARTCONV = cartconv
EMULATOR = xvic

# --- Addresses ---
# $A000 is Block 5 (Standard 8K Cartridge Area)
START_ADDR = 0xA000

# --- Assembler Flags ---
ASFLAGS = -g -t vic20 -I ./

# --- Linker Flags ---
# CL65 Flags:
# -t none:      No system header (Raw binary)
# --start-addr: Set the origin to $A000
# -Wa -I...:    Pass include path to assembler
# -m:           Generate map file
CLFLAGS  = -g -t vic20 -C $(CFG_FILE) --start-addr $(START_ADDR) -Wa -I,$(INC_DIR) -m $(MAP) -Ln $(LABELS)

# Cartconv Flags:
# -t vic20: Target machine
# -l:       Load address (Required for raw .bin input)
CCFLAGS  = -t vic20 -l $(START_ADDR)

# Emulator Flags:
# -cartA: Attach file as 8K Block 5 Cartridge
# -memory none: Ensure unexpanded baseline
EMUFLAGS = -memory none -cartcrt

# --- Targets ---

.PHONY: all clean run

all: $(CRT)

# Create build directory
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Compile all assembly sources
$(BUILD_DIR)/%.o: %.s | $(BUILD_DIR)
	$(CA65) $(ASFLAGS) -o $@ $<

# 1. Assemble & Link to Raw Binary (.bin)
$(BIN): $(OBJ)
	$(CL65) $(CLFLAGS) -o $@ $(OBJ)

# 2. Convert Binary to VICE Cartridge (.crt)
$(CRT): $(BIN)
	$(CARTCONV) $(CCFLAGS) -i $< -o $@

# 3. Run
run: $(CRT)
	$(EMULATOR) $(EMUFLAGS) $(CRT)

clean:
	rm -rf $(BUILD_DIR)
