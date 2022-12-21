EXEC_NAME = "NimBot"

# Build executable:
build: NimBot.nimble
	@echo "Building executable!"
	nimble build -d:ssl

# Build executable and run it:
run: build
	@echo "Starting executable!"
	./
winrun: build
	@echo "Starting executable!"
	.\$(EXEC_NAME).exe
