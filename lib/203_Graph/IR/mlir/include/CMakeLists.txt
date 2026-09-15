# TableGen: SCR.td → generated .h.inc and .cpp.inc
set(TABLEGEN_INPUT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/..)

set(LLVM_TARGET_DEFINITIONS ${TABLEGEN_INPUT_DIR}/SCR.td)
mlir_tablegen(SCR.h.inc -gen-dialect-decls)
mlir_tablegen(SCR.cpp.inc -gen-dialect-defs)
mlir_tablegen(SCRTypes.h.inc -gen-typedef-decls)
mlir_tablegen(SCRTypes.cpp.inc -gen-typedef-defs)
mlir_tablegen(SCROps.h.inc -gen-op-decls)
mlir_tablegen(SCROps.cpp.inc -gen-op-defs)

add_public_tablegen_target(SCRTableGen)
