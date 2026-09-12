get_property(dialect_libs GLOBAL PROPERTY MLIR_DIALECT_LIBS)
get_property(conversion_libs GLOBAL PROPERTY MLIR_CONVERSION_LIBS)

add_llvm_executable(scr-opt
  scr-opt.cpp
)

target_link_libraries(scr-opt
  PRIVATE
  SCRdialect
  ${dialect_libs}
  ${conversion_libs}
  MLIRMlirOptMain
  MLIRPass
  MLIRIR
)
