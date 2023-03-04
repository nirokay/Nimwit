EXEC_NAME =    Nimwit
COMP_FLAGS =   -d:ssl --threads:on -d:discordCompress
COMP_debug =   $(COMP_FLAGS) -d:debug -d:dimscordDebug
COMP_release = $(COMP_FLAGS) -d:release

# Build executable:
build: Nimwit.nimble
	@echo "Building executable!"
	nimble build $(COMP_release)

debug: Nimwit.nimble
	@echo "Building debug build"
	nimble build $(COMP_debug) 

debugrun: debug
	@echo "Starting debug executable!"
	./$(EXEC_NAME)

# Build executable and run it:
run: build
	@echo "Starting executable!"
	./$(EXEC_NAME)

winrun: build
	@echo "Starting executable!"
	.\$(EXEC_NAME).exe
