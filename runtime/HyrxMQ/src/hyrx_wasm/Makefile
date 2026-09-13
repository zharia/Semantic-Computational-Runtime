# Hyrx WASM — Build system
#
# Targets:
#   make native     — Build native test binary
#   make wasm       — Build WASM module (freestanding, no libc)
#   make test       — Run native tests
#   make serve      — Start local HTTP server for browser demo
#   make clean      — Remove build artifacts

CC := gcc
WASM_CC := clang
CFLAGS := -O2 -Wall -Wextra -Isrc
WASM_CFLAGS := --target=wasm32-wasip1 -O2 -Wall -Isrc -nostdlib \
               -Wl,--no-entry -Wl,--export-all -Wl,--allow-undefined

SRC_DIR := src
BUILD_DIR := build
DIST_DIR := dist

.PHONY: native test serve clean wasm

native: $(BUILD_DIR)/hyrx_test

$(BUILD_DIR)/hyrx_test: $(SRC_DIR)/test_hyrx.c $(SRC_DIR)/engine.h $(SRC_DIR)/queue.h $(SRC_DIR)/exchange.h $(SRC_DIR)/message.h $(SRC_DIR)/buffer.h $(SRC_DIR)/pool.h $(SRC_DIR)/freestanding.h
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) $(SRC_DIR)/test_hyrx.c -o $@

wasm: $(DIST_DIR)/hyrx.wasm

$(DIST_DIR)/hyrx.wasm: $(SRC_DIR)/hyrx_wasm.c $(SRC_DIR)/engine.h $(SRC_DIR)/queue.h $(SRC_DIR)/exchange.h $(SRC_DIR)/message.h $(SRC_DIR)/buffer.h $(SRC_DIR)/pool.h $(SRC_DIR)/freestanding.h
	@mkdir -p $(DIST_DIR)
	$(WASM_CC) $(WASM_CFLAGS) $(SRC_DIR)/hyrx_wasm.c -o $@
	@echo "Built $@ ($(shell du -h $@ | cut -f1))"

test: native
	$(BUILD_DIR)/hyrx_test

serve: wasm
	@echo "Serving at http://localhost:8080"
	@cd $(DIST_DIR) && python3 -m http.server 8080

clean:
	rm -rf $(BUILD_DIR) $(DIST_DIR)
