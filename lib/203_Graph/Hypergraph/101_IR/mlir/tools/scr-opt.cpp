//===- scr-opt.cpp - SCR dialect opt tool -*- C++ -*-===//
//
// mlir-opt with SCR dialect registered.
//
//===-----------------------------------------------------===//

#include "mlir/IR/MLIRContext.h"
#include "mlir/InitAllDialects.h"
#include "mlir/InitAllPasses.h"
#include "mlir/Tools/mlir-opt/MlirOptMain.h"

#include "SCR/SCRDialect.h"

int main(int argc, char **argv) {
  mlir::DialectRegistry registry;
  mlir::registerAllDialects(registry);
  mlir::registerAllPasses();

  registry.insert<scr::SCRDialect>();

  return mlir::asMainReturnCode(
      mlir::MlirOptMain(argc, argv, "SCR dialect optimizer\n", registry));
}
