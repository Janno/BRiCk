(*
 * Copyright (c) 2019-2022 BedRock Systems, Inc.
 * This software is distributed under the terms of the BedRock Open-Source License.
 * See the LICENSE-BedRock file in the repository root for details.
 *)
Require Import Stdlib.ZArith.ZArith.

Require bedrock.lang.cpp.syntax.
Require Import bedrock.lang.cpp.syntax.type_notations.
Require Import bedrock.lang.cpp.syntax.expr_notations.
Require Import bedrock.lang.cpp.syntax.stmt_notations.

#[local] Open Scope Z_scope.
#[local] Open Scope bs_scope.

(* TODOS (JH):
   - Look into disabling (selective) scopes
   - Determine what the minimum [Printing Width] needed for reasonable goal display is
 *)

Module Export CodeNotations.
  Export TypeNotationsInterface.
  Export TypeNotations.
  Export ExprNotationsInterface.
  Export ExprNotations.
  Export StmtNotationsInterface.
  Export StmtNotations.
End CodeNotations.
