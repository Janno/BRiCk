#include "CoqPrinter.hpp"
#include "ClangPrinter.hpp"
#include "DeclVisitorWithArgs.h"
#include <Formatter.hpp>

using namespace clang;

class PrintLocalDecl : public ConstDeclVisitorArgs<PrintLocalDecl, void, CoqPrinter&, ClangPrinter&> {
private:
  PrintLocalDecl() {}

public:
  static PrintLocalDecl printer;

  void VisitVarDecl(const VarDecl *decl, CoqPrinter& print, ClangPrinter& cprint)
  {
    print.output() << fmt::lparen << "\"" << decl->getNameAsString() << "\","
                   << fmt::nbsp;
    cprint.printQualType(decl->getType(), print);
    print.output() << "," << fmt::nbsp;
    if (decl->hasInit()) {
      print.ctor("Some", false);
      cprint.printExpr(decl->getInit(), print);
      print.output() << fmt::rparen;
    } else {
      print.output() << "None";
    }
    print.output() << fmt::rparen;
  }

  void VisitDecl(const Decl *decl, CoqPrinter& print, ClangPrinter& cprint)
  {
    print.error() << "unexpected local declaration";
  }
};

PrintLocalDecl PrintLocalDecl::printer;

void ClangPrinter::printLocalDecl(const clang::Decl* decl, CoqPrinter& print) {
  PrintLocalDecl::printer.Visit(decl, print, *this);
}