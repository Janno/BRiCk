(*
 * Copyright (c) 2023 BedRock Systems, Inc.
 * This software is distributed under the terms of the BedRock Open-Source License.
 * See the LICENSE-BedRock file in the repository root for details.
 *)

Require Import ssreflect.
From stdpp Require Import base decidable finite countable.

From bedrock.prelude Require Import prelude finite.

(**
This file exports and tests BedRock derive extensions.
BedRock users should import this file rather than directly importing individual extensions.
Alternatively, they should make sure to Unset Uniform Inductive Parameters
as is done below.
*)

From bedrock.prelude.elpi.derive Require Export
  eq_dec
  inhabited
  finite
  countable
  finite_type
  bitset.

From elpi.apps Require Export derive.
#[global] Unset Uniform Inductive Parameters.

Elpi Accumulate derive lp:{{
  derivation (const C) Prefix D :-
    coq.env.const C (some (global (indt T))) Ty_,
    derivation (indt T) Prefix D.
}}.
Elpi Typecheck derive.

Module Type BasicTests.
  Variant T1 := A1 | B1 | C1.
  #[only(eq_dec)] derive T1.
  #[only(inhabited)] derive T1.
  #[only(countable)] derive T1.
  #[only(finite)] derive T1.

  (*TODO: Potential derive bug; the following produces:
    Anomaly: Uncaught exception Failure("split dirpath")*)
  (*#[only(finite)] derive
   Variant T2 := A2 | B2 | C2.*)

  #[only(eq_dec,inhabited)] derive
  Variant T2 := A2 | B2 | C2.
  #[only(countable)] derive T2.
  #[only(finite)] derive T2.
End BasicTests.

(*Test interop of manual and generated definitions*)
Module Type InteropTests.
  Variant T1 := A1 | B1 | C1.
  (*Test: Manual EqDecision + generated Finite:*)
  #[local] Instance T1_eq_dec : EqDecision T1.
  Proof. solve_decision. Defined.
  #[only(finite)] derive T1.
  (*Search T1. (*Should give one instance T1_eq_dec (plus a finite instance)*)*)

  Variant T2 := A2 | B2 | C2.
  (*Test: Generated EqDecision + manual Finite + generated Finite:
    Should yield only one Finite instance*)
  #[only(eq_dec)] derive T2.
  #[local] Instance manual_T2_finite : Finite T2.
  Proof. solve_finite [A2;B2;C2]. Qed.
  #[only(finite)] derive T2.
  (*Search T2. (*Should give one instance manual_T2_finite*)*)
End InteropTests.

(*** Test derivation using Countable. *)
#[local] Ltac assert_True :=
  match goal with
  | |- True => idtac
  | |- _ => fail
  end.

Module Type DerivingTest.
  (*This example uses the default unfolding rule.
    It's motivated by functor use cases.*)
  Variant _t := A | B | C.
  Definition t := _t.
  #[only(eq_dec,countable)] derive t.
  Goal forall x y : t, if bool_decide (x = y) then True else True.
  Proof. by move => x y; case (bool_decide_reflect (x = y)). Qed.
  Goal forall x y : t, encode x = encode y -> x = y.
  Proof. by move => x y X; apply encode_inj in X. Qed.
  Goal match Pos.compare (encode A) (encode B) with
       | Eq => True
       | Lt => True
       | Gt => True
       end.
  Proof.
    Succeed by vm_compute.
    (* Even [simpl] normalizes this goal - that's nice! *)
    by simpl; assert_True.
  Qed.
End DerivingTest.

(*** Test derivation using Finite. *)
Module Type Deriving2Test.
  Variant _t := A | B | C (_ : bool) | D (_ : option bool) (_ : bool).
  Definition t := _t.
  #[global] Instance: EqDecision t.
  Proof. solve_decision. Defined.
  #[only(inhabited,eq_dec,finite)] derive t.

  (*
  Print Assumptions t_inhabited.
  Print t_inhabited.
  Print Assumptions t_finite.
  Print t_finite.
  Print t_finite_subproof_nodup.
  Print t_finite_subproof_elem_of.
  *)

  (* Test the tactic in isolation. *)
  Definition t_finite2 : Finite t.
  Proof. solve_finite ([A; B] ++ (C <$> enum _) ++ (D <$> enum _ <*> enum _)). Defined.
  (*
  Print Assumptions t_finite2.
  Print t_finite2_subproof.
  *)
  Variant _t2 := E | F | G.
  Definition t2 := _t2.
  #[only(inhabited,eq_dec)] derive t2.
  #[only(finite)] derive t2.
  (* #[global] Instance: EqDecision t.
  Proof. solve_decision. Defined. *)
  Section test.
    Context (x : nat).
    Variant t3 := H.
    #[only(inhabited,eq_dec,finite)] derive t3.
  End test.

  Goal forall x y : t, if bool_decide (x = y) then True else True.
  Proof. by move => x y; case (bool_decide_reflect (x = y)). Qed.
  Goal forall x y : t, encode x = encode y -> x = y.
  Proof. by move => x y X; apply encode_inj in X. Qed.

  (* Eval vm_compute in enum t. *)

  Goal match Pos.compare (encode A) (encode B) with
       | Eq => True
       | Lt => True
       | Gt => True
       end.
  Proof.
    Succeed by vm_compute.
    (* [simpl] normalizes this goal too! *)
    by simpl; assert_True.
  Qed.
End Deriving2Test.

Module Type SimpleFiniteTest.
  (*#[only(finite_type)] derive
    Variant feature := A | B | C | D.*) (*TODO: potential derive bug? Anomaly/split_dirpath*)
  Variant feature := A | B | C | D.
  #[only(finite_type)] derive feature.
  Goal feature.of_N (feature.to_N A) = Some A.
  Proof. reflexivity. Qed.
  Goal feature.of_N (feature.to_N B) = Some B.
  Proof. by rewrite feature.of_to_N. Qed.
End SimpleFiniteTest.

Module Type FiniteTest.
  Variant feature := A | B | C | D.
  #[local] Instance: ToN feature (fun (x : feature) =>
    match x with
    | A => 0
    | B => 1
    | C => 3
    | D => 5
    end)%N := {}.
  #[only(finite_type)] derive feature.
  #[export] Instance feature_to_N_inj : Inj eq eq feature.to_N.
  Proof. case; case => //. Qed.
  Goal feature.of_N (feature.to_N C) = Some C.
  Proof. reflexivity. Qed.
  Goal feature.of_N (feature.to_N D) = Some D.
  Proof. by rewrite feature.of_to_N. Qed.
  Goal feature.of_N 3 = Some C.
  Proof. reflexivity. Qed.
End FiniteTest.

Module Type SimpleBitsetTest.
  Variant feature := A | B | C | D.
  #[only(bitset)] derive feature.
  Goal feature_set.to_bits {[ A ]} = 1%N.
  Proof. reflexivity. Qed.
  Goal feature_set.to_bits {[ C ]} = 4%N.
  Proof. reflexivity. Qed.
  Goal feature_set.to_bits {[ A; C ]} = 5%N.
  Proof. reflexivity. Qed.
End SimpleBitsetTest.

Module Type BitsetTest.
  Variant feature := A | B | C | D.
  #[local] Instance: ToBit feature (fun (x : feature) =>
    match x with
    | A => 0
    | B => 1
    | C => 3
    | D => 5
    end)%N := {}.
  #[only(bitset)] derive feature.
  Goal feature_set.to_bits {[ A ]} = 1%N.
  Proof. reflexivity. Qed.
  Goal feature_set.to_bits {[ C ]} = 8%N.
  Proof. reflexivity. Qed.
  Goal feature_set.to_bits {[ A; C ]} = 9%N.
  Proof. reflexivity. Qed.
End BitsetTest.
