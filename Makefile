EXEC_NAME = "Nimwit"
COMP_FLAGS = "-d:ssl --threads:on"

# Build executable:
build: Nimwit.nimble
	@echo "Building executable!"
	nimble build $(COMP_FLAGS)

# Build executable and run it:
run: build
	@echo "Starting executable!"
	./$(EXEC_NAME)
winrun: build
	@echo "Starting executable!"
	.\$(EXEC_NAME).exe
