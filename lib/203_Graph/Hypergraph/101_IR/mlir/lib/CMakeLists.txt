# SCR Dialect library (no ODS types — manual opaque type registration)
add_mlir_library(SCRdialect
  SCR/SCRDialect.cpp
  SCR/SCROps.cpp

  EXCLUDE_FROM_LIBMLIR

  DEPENDS
  SCRTableGen

  LINK_LIBS PUBLIC
  MLIRIR
  MLIRInferTypeOpInterface
  MLIRSideEffectInterfaces
  MLIRPass
  MLIRDialect
)

target_include_directories(SCRdialect PUBLIC
  ${CMAKE_CURRENT_BINARY_DIR}/../include
)
