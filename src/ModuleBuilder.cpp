/*
 * Copyright (c) 2020 BedRock Systems, Inc.
 * This software is distributed under the terms of the BedRock Open-Source License.
 * See the LICENSE-BedRock file in the repository root for details.
 */
#include "ModuleBuilder.hpp"
#include "CommentScanner.hpp"
#include "DeclVisitorWithArgs.h"
#include "Filter.hpp"
#include "Formatter.hpp"
#include "FromClang.hpp"
#include "Logging.hpp"
#include "SpecCollector.hpp"
#include "clang/Basic/Builtins.h"
#include "clang/Frontend/CompilerInstance.h"
#include "clang/Sema/Sema.h"
#include <set>

using namespace clang;

static void
unsupported_decl(const Decl *decl) {
    using namespace logging;
    debug() << "[DEBUG] unsupported declaration kind \""
            << decl->getDeclKindName() << "\", dropping.\n";
}

using Flags = ::Module::Flags;

class BuildModule : public ConstDeclVisitorArgs<BuildModule, void, Flags> {
private:
    using Visitor = ConstDeclVisitorArgs<BuildModule, void, Flags>;

    ::Module &module_;
    Filter &filter_;
    const bool templates_;
    SpecCollector &specs_;
    clang::ASTContext *const context_;
    std::set<int64_t> visited_;

private:
    Filter::What go(const NamedDecl *decl, Flags flags,
                    bool definition = true) {
        auto what = filter_.shouldInclude(decl);
        switch (what) {
        case Filter::What::DEFINITION:
            if (definition) {
                module_.add_definition(decl, flags);
                return what;
            } else {
                module_.add_declaration(decl, flags);
                return Filter::What::DECLARATION;
            }
        case Filter::What::DECLARATION:
            module_.add_declaration(decl, flags);
            return Filter::What::DECLARATION;
        default:
            return Filter::What::NOTHING;
        }
    }

public:
    BuildModule(::Module &m, Filter &filter, bool templates,
                clang::ASTContext *context, SpecCollector &specs,
                clang::CompilerInstance *ci)
        : module_(m), filter_(filter), templates_(templates), specs_(specs),
          context_(context) {}

    void Visit(const Decl *d, Flags flags) {
        if (visited_.find(d->getID()) == visited_.end()) {
            visited_.insert(d->getID());
            Visitor::Visit(d, flags);
        }
    }

    void VisitDecl(const Decl *d, Flags) {
        unsupported_decl(d);
    }

    void VisitBuiltinTemplateDecl(const BuiltinTemplateDecl *, Flags) {
        // ignore
    }

    void VisitVarTemplateDecl(const VarTemplateDecl *decl, Flags flags) {
        if (templates_)
            go(decl, flags.set_template());

        for (auto i : decl->specializations()) {
            this->Visit(i, flags.set_specialization());
        }
    }

    void VisitStaticAssertDecl(const StaticAssertDecl *decl, Flags) {
        module_.add_assert(decl);
    }

    void VisitAccessSpecDecl(const AccessSpecDecl *, Flags) {
        // ignore
    }

    void VisitTranslationUnitDecl(const TranslationUnitDecl *decl,
                                  Flags flags) {
        assert(flags.none());

        for (auto i : decl->decls()) {
            this->Visit(i, flags);
        }
    }

    void VisitTypeDecl(const TypeDecl *type, Flags) {
        /*
        TODO: Consolidate code for complaining about and dumping
        unsupported things.
        */
        logging::log() << "Error: Unsupported type declaration: "
                       << type->getQualifiedNameAsString()
                       << "(type = " << type->getDeclKindName() << ")\n";
    }

    void VisitEmptyDecl(const EmptyDecl *decl, Flags) {}

    void VisitTypedefNameDecl(const TypedefNameDecl *type, Flags flags) {
        go(type, flags);
    }

    void VisitTagDecl(const TagDecl *decl, Flags flags) {
        auto defn = decl->getDefinition();
        if (defn == decl) {
            go(decl, flags, true);
        } else if (defn == nullptr && decl->getPreviousDecl() == nullptr) {
            go(decl, flags, false);
        }
    }

    void VisitCXXRecordDecl(const CXXRecordDecl *decl, Flags flags) {
        if (decl->isImplicit()) {
            return;
        }
        if (!flags.in_specialization &&
            isa<ClassTemplateSpecializationDecl>(decl)) {
            return;
        }

        // find any static functions or fields
        for (auto i : decl->decls()) {
            Visit(i, flags);
        }

        VisitTagDecl(decl, flags);
    }

    void VisitCXXMethodDecl(const CXXMethodDecl *decl, Flags flags) {
        if (decl->isDeleted())
            return;

        this->ConstDeclVisitorArgs::VisitCXXMethodDecl(decl, flags);
    }

    void VisitFunctionDecl(const FunctionDecl *decl, Flags flags) {
        if (!templates_ && decl->isDependentContext()) {
            return;
        }

        using namespace comment;
        auto defn = decl->getDefinition();
        if (defn == decl) {
            if (auto c = context_->getRawCommentForDeclNoCache(decl)) {
                this->specs_.add_specification(decl, c, *context_);
            }

            if (go(decl, flags, true) >= Filter::What::DEFINITION) {
                // search for static local variables
                for (auto i : decl->decls()) {
                    if (auto d = dyn_cast<VarDecl>(i)) {
                        if (d->isStaticLocal()) {
                            go(d, flags);
                        }
                    }
                }
            }
        } else if (defn == nullptr && decl->getPreviousDecl() == nullptr) {
            go(decl, flags, false);
        }
    }

    void VisitEnumConstantDecl(const EnumConstantDecl *decl, Flags flags) {
        go(decl, flags);
    }

    void VisitVarDecl(const VarDecl *decl, Flags flags) {
        if (!templates_ && !decl->isTemplated()) {
            return;
        }

        go(decl, flags);
    }

    void VisitFieldDecl(const FieldDecl *, Flags) {
        // ignore
    }

    void VisitUsingDecl(const UsingDecl *, Flags) {
        // ignore
    }

    void VisitUsingDirectiveDecl(const UsingDirectiveDecl *, Flags) {
        // ignore
    }

    void VisitIndirectFieldDecl(const IndirectFieldDecl *, Flags) {
        // ignore
    }

    void VisitNamespaceDecl(const NamespaceDecl *decl, Flags flags) {
        assert(flags.none());

        for (auto d : decl->decls()) {
            this->Visit(d, flags);
        }
    }

    void VisitEnumDecl(const EnumDecl *decl, Flags flags) {
        if (not decl->isCanonicalDecl())
            return;

        go(decl, flags);
        for (auto i : decl->enumerators()) {
            go(i, flags);
        }
    }

    void VisitLinkageSpecDecl(const LinkageSpecDecl *decl, Flags flags) {
        assert(flags.none());

        for (auto i : decl->decls()) {
            this->Visit(i, flags);
        }
    }

    void VisitCXXConstructorDecl(const CXXConstructorDecl *decl, Flags flags) {
        if (decl->isDeleted())
            return;

        this->ConstDeclVisitorArgs::VisitCXXConstructorDecl(decl, flags);
    }

    void VisitCXXDestructorDecl(const CXXDestructorDecl *decl, Flags flags) {
        if (decl->isDeleted())
            return;

        this->ConstDeclVisitorArgs::VisitCXXDestructorDecl(decl, flags);
    }

    void VisitFunctionTemplateDecl(const FunctionTemplateDecl *decl,
                                   Flags flags) {
        if (templates_)
            go(decl, flags.set_template());

        for (auto i : decl->specializations()) {
            this->Visit(i, flags.set_specialization());
        }
    }

    void VisitClassTemplateDecl(const ClassTemplateDecl *decl, Flags flags) {
        if (templates_)
            this->Visit(decl->getTemplatedDecl(), flags.set_template());

        for (auto i : decl->specializations()) {
            this->Visit(i, flags.set_specialization());
        }
    }

    void VisitFriendDecl(const FriendDecl *decl, Flags flags) {
        if (decl->getFriendDecl()) {
            this->Visit(decl->getFriendDecl(), flags);
        }
    }

    void VisitTypeAliasTemplateDecl(const TypeAliasTemplateDecl *, Flags) {
        // ignore
    }

    void VisitUsingShadowDecl(const UsingShadowDecl *, Flags) {
        // ignore
    }
};

void
build_module(clang::TranslationUnitDecl *tu, ::Module &mod, Filter &filter,
             SpecCollector &specs, clang::CompilerInstance *ci, bool elaborate,
             bool templates) {
    auto &ctxt = tu->getASTContext();
    BuildModule(mod, filter, templates, &ctxt, specs, ci)
        .VisitTranslationUnitDecl(tu, {});
}

void ::Module::add_assert(const clang::StaticAssertDecl *d) {
    asserts_.push_back(d);
}

using DeclList = ::Module::DeclList;

static void
add_decl(DeclList &decls, DeclList &tdecls, const clang::NamedDecl *d,
         Flags flags) {
    if (flags.in_template) {
        tdecls.push_back(d);
    } else {
        decls.push_back(d);
        if (flags.in_specialization) {
            tdecls.push_back(d);
        }
    }
}

void ::Module::add_definition(const clang::NamedDecl *d, Flags flags) {
    add_decl(definitions_, template_definitions_, d, flags);
}

void ::Module::add_declaration(const clang::NamedDecl *d, Flags flags) {
    add_decl(declarations_, template_declarations_, d, flags);
}
