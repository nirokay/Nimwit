EXEC_NAME = "Nimwit"
COMP_FLAGS = "-d:ssl --threads:on -d:release"

# Build executable:
build: Nimwit.nimble
	@echo "Building executable!"
	nimble build $(COMP_FLAGS)

debug: Nimwit.nimble
	@echo "Building debug build"
	nimble build $(COMP_FLAGS) -d:dimscordDebug

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
