# Project setup
PROJ      = top
BUILD     = ./build
DEVICE    = 8k
FOOTPRINT = ct256

# Files
FILES = $(PROJ).v

.PHONY: all clean burn

all:
	# if build folder doesn't exist, create it
	mkdir -p $(BUILD)
	# synthesize using Yosys
	#yosys -p "synth_ice40 -top top -blif $(BUILD)/$(PROJ).blif" $(FILES)
	yosys -p 'synth_ice40 -top top -json $(BUILD)/$(PROJ).json' $(FILES)
	# Place and route using arachne
	#arachne-pnr -d $(DEVICE) -P $(FOOTPRINT) -o $(BUILD)/$(PROJ).asc -p pinmap.pcf $(BUILD)/$(PROJ).blif
	nextpnr-ice40 --hx$(DEVICE) --package $(FOOTPRINT) --json $(BUILD)/$(PROJ).json --pcf hx8kboard.pcf --asc $(BUILD)/$(PROJ).asc
	# Convert to bitstream using IcePack
	icepack $(BUILD)/$(PROJ).asc $(BUILD)/$(PROJ).bin

burn:
	iceprog $(BUILD)/$(PROJ).bin
gui:
	nextpnr-ice40 --json $(BUILD)/$(PROJ).json --hx$(DEVICE) --package $(FOOTPRINT) --pcf hx8kboard.pcf --asc $(BUILD)/$(PROJ).asc --gui --gui-no-aa

copy:
	scp $(BUILD)/$(PROJ).bin pi@169.168.5.79:~/ice40.bin
clean:
	rm -rf build