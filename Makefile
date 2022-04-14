BUILD_DIR=build
SRC_DIR=src

.PHONY: clean

all: test

pp: $(SRC_DIR)/opcodes.S examples/test.S
	nasm -E -felf64 -p$(SRC_DIR)/opcodes.S examples/test.S

# currently for testing
$(BUILD_DIR)/test: $(SRC_DIR)/opcodes.S examples/test.S
	mkdir -p $(BUILD_DIR)
	nasm -felf64 -p$(SRC_DIR)/opcodes.S -o$(BUILD_DIR)/test.o examples/test.S
	gcc -o$(BUILD_DIR)/test $(BUILD_DIR)/test.o

test: $(BUILD_DIR)/test

run: $(BUILD_DIR)/test
	$(BUILD_DIR)/test

clean:
	rm -rf $(BUILD_DIR)
