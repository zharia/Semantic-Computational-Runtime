//===- scr-opt.cpp - SCR dialect opt tool -*- C++ -*-===//
//
// mlir-opt with SCR dialect registered.
//
//===-----------------------------------------------------===//

#include "mlir/IR/MLIRContext.h"
#include "mlir/InitAllDialects.h"
#include "mlir/InitAllPasses.h"
#include "mlir/Pass/PassRegistry.h"
#include "mlir/Pass/Pass.h"
#include "mlir/Tools/mlir-opt/MlirOptMain.h"

#include "SCR/SCRDialect.h"

// Forward-declare SCR verification pass (defined in SCRVerification.cpp)
namespace scr {
struct SCRVerifyPass;
std::unique_ptr<mlir::Pass> createSCRVerifyPass();
} // namespace scr

int main(int argc, char **argv) {
  mlir::DialectRegistry registry;
  mlir::registerAllDialects(registry);
  mlir::registerAllPasses();

  registry.insert<scr::SCRDialect>();

  // Explicitly register SCR passes (not part of registerAllPasses)
  mlir::registerPass([] { return scr::createSCRVerifyPass(); });

  return mlir::asMainReturnCode(
      mlir::MlirOptMain(argc, argv, "SCR dialect optimizer\n", registry));
}
