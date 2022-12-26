EXEC_NAME = "Nimwit"

# Build executable:
build: Nimwit.nimble
	@echo "Building executable!"
	nimble build -d:ssl

# Build executable and run it:
run: build
	@echo "Starting executable!"
	./$(EXEC_NAME)
winrun: build
	@echo "Starting executable!"
	.\$(EXEC_NAME).exe
