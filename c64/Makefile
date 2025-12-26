# --- Project Configuration ---
PROJECT  = c64_digital_rain
BUILD_DIR = build
SRC      = $(wildcard *.s)
OBJ      = $(patsubst %.s, $(BUILD_DIR)/%.o, $(SRC))
BIN      = $(BUILD_DIR)/$(PROJECT).bin
CRT      = $(BUILD_DIR)/$(PROJECT).crt
MAP      = $(BUILD_DIR)/$(PROJECT).map
LABELS   = $(BUILD_DIR)/$(PROJECT).lbl

# --- Paths ---
INC_DIR  = ./
CFG_FILE = c64-asm.cfg

# --- Tools ---
CA65     = ca65
CL65     = cl65
EMULATOR = x64sc

# --- Assembler Flags ---
ASFLAGS = -g -t c64 -I ./

# --- Linker Flags ---
# CL65 Flags:
# -t none:      No system header (Raw binary)
# -Wa -I...:    Pass include path to assembler
# -m:           Generate map file
CLFLAGS  = -g -t c64 -C $(CFG_FILE) -Wa -I,$(INC_DIR) -m $(MAP) -Ln $(LABELS)

# PRG Flags
CFG_PRG  = c64-asm.cfg
PRG      = $(BUILD_DIR)/$(PROJECT).prg
MAP_PRG  = $(BUILD_DIR)/$(PROJECT)_prg.map
LBL_PRG  = $(BUILD_DIR)/$(PROJECT)_prg.lbl
CLFLAGS_PRG = -g -t c64 -C $(CFG_PRG) -Wa -D,PRG_BUILD -Wa -I,$(INC_DIR) -m $(MAP_PRG) -Ln $(LBL_PRG)

# Emulator Flags:
EMUFLAGS_PRG =

# --- Targets ---

.PHONY: all clean run

all: $(PRG)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/%_prg.o: %.s | $(BUILD_DIR)
	$(CA65) $(ASFLAGS) -D PRG_BUILD -o $@ $<

OBJ_PRG = $(patsubst %.s, $(BUILD_DIR)/%_prg.o, $(SRC))

$(PRG): $(OBJ_PRG)
	$(CL65) $(CLFLAGS_PRG) -o $@ $(OBJ_PRG)

run: $(PRG)
	$(EMULATOR) $(EMUFLAGS_PRG) $(PRG)

clean:
	rm -rf $(BUILD_DIR)