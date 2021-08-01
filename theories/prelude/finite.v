(**
 * Copyright (c) 2021 BedRock Systems, Inc.
 *
 * This software is distributed under the terms of the BedRock Open-Source License.
 * See the LICENSE-BedRock file in the repository root for details.
 *)

From stdpp Require Export finite.
From bedrock.prelude Require Export base numbers gmap.

(**
Extensions of [stdpp.finite], especially for variants:

From the [Finite] typeclass, like from Haskell's [Enum], one can generate
conversion to and from [N], both for individual elements and bitsets of them.
*)

Lemma subset_of_enum `{Finite A} xs :
  xs ⊆ enum A.
Proof. intros x _. apply elem_of_enum. Qed.

Definition encode_N `{Countable A} (x : A) : N :=
  Pos.pred_N (encode x).
Definition decode_N `{Countable A} (i : N) : option A :=
  decode (N.succ_pos i).
Global Instance encode_nat_inj `{Countable A} : Inj (=) (=) (encode_N (A:=A)).
Proof. unfold encode_N; intros x y Hxy; apply (inj encode); lia. Qed.
Lemma decode_encode_N `{Countable A} (x : A) : decode_N (encode_N x) = Some x.
Proof. rewrite /decode_N /encode_N N_succ_pos_pred. apply decode_encode. Qed.

(* From (pieces of) [Countable] (and more) to [Finite]. *)
Section enc_finite.
  Context `{EqDecision A}.
  Context (to_nat : A → nat) (of_nat : nat → A) (c : nat).
  Context (of_to_nat : ∀ x, of_nat (to_nat x) = x).
  Context (to_nat_c : ∀ x, to_nat x < c).
  Context (to_of_nat : ∀ i, i < c → to_nat (of_nat i) = i).

  (* Unfolding lemma for enc_finite. *)
  Lemma enc_finite_enum :
    @enum _ _ (enc_finite to_nat of_nat c of_to_nat to_nat_c to_of_nat) = of_nat <$> seq 0 c.
  Proof. done. Qed.
End enc_finite.

(** Lift enc_finite to [N] *)
Section enc_finite_N.
  Context `{Inhabited A}.
  Context `{EqDecision A}.
  Context (to_N : A → N) (of_N : N → option A) (c : N).
  Context (of_to_N : ∀ x, of_N (to_N x) = Some x).

  Context (to_N_c : (∀ x, to_N x < c)%N).
  Context (to_of_N : (∀ i, i < c → to_N (default inhabitant $ of_N i) = i)%N).

  #[program] Definition enc_finite_N : Finite A :=
    enc_finite (N.to_nat ∘ to_N) ((λ x, default inhabitant (of_N x)) ∘ N.of_nat) (N.to_nat c) _ _ _.
  Next Obligation. move=> /= x. by rewrite N2Nat.id of_to_N. Qed.
  Next Obligation. move=> /= x. have := to_N_c x. lia. Qed.
  Next Obligation. move=> /= x Hle. rewrite to_of_N; lia. Qed.
End enc_finite_N.

(** Useful to prove NoDup when lifting [Finite] over constructor [f]. *)
Lemma NoDup_app_fmap_l {A B} `{Finite A} (f : A -> B) xs :
  Inj eq eq f →
  NoDup xs →
  (∀ x : B, x ∈ f <$> enum A → x ∉ xs) →
  NoDup ((f <$> enum A) ++ xs).
Proof.
  intros. rewrite NoDup_app. by split_and!; first apply /NoDup_fmap_2 /NoDup_enum.
Qed.

(** Module-based infrastructure to generate Finite-based utilities. *)
Module Type eqdec_type.
  Parameter t : Type.
  #[global] Declare Instance t_inh : Inhabited t.
  #[global] Declare Instance t_eqdec : EqDecision t.
End eqdec_type.

Module Type finite_type.
  Include eqdec_type.
  #[global] Declare Instance t_finite : Finite t.
End finite_type.

(**
To define [finite_type] for enums, the following will work:

<<
#[global,program] Instance t_finite : Finite t :=
{ enum := [GET; SET] }.
Next Obligation. solve_finite_nodup. Qed.
Next Obligation. solve_finite_total. Qed.
>>
*)
Ltac solve_finite_nodup := repeat (constructor; first set_solver); constructor.
Ltac solve_finite_total := intros []; set_solver.

Module Type finite_type_mixin (Import F : finite_type).
  (*
  Not marked as an instance because it is derivable.
  It is here just in case some mixin wants it. *)
  Definition t_countable : Countable t := _.

  (* Obtain encoding from [t_finite] *)
  Definition to_N : t -> N := encode_N.
  Definition of_N : N -> option t := decode_N.
  Lemma of_to_N x : of_N (to_N x) = Some x.
  Proof. apply decode_encode_N. Qed.
End finite_type_mixin.

Module Type finite_type_intf := finite_type <+ finite_type_mixin.

(* Interface for the bitmask functions. *)
Module Type bitmask_type (Import F : eqdec_type).
  (**
  Convert [t] to the corresponding bit number.
  [bitmask_type_simple_mixin] sets this to [finite_type.to_N], which is
  not always appropriate when interfacing with outside protocols.
  *)
  Parameter to_bit : t -> N.
End bitmask_type.

Module Type bitmask_type_simple_mixin (Import F : finite_type) (Import FM : finite_type_mixin F).
  (* Here, [to_N] is a valid bit encoding *)
  Definition to_bit := to_N.
  Definition of_bit := of_N.
End bitmask_type_simple_mixin.

Module Type finite_bitmask_type_mixin (Import F : finite_type) (Import B : bitmask_type F).
  Definition to_bitmask (r : t) : N := 2 ^ to_bit r.

  Lemma to_bitmask_setbit x : to_bitmask x = N.setbit 0 (to_bit x).
  Proof. by rewrite N.setbit_spec'. Qed.

  (* Parse a bitmask into a list of flags. *)
  Definition to_list_aux (r : N) (xs : list t) : list t :=
    x ← xs;
    if N.testbit r (to_bit x) then [x] else [].

  Definition to_list (r : N) : list t := to_list_aux r $ enum t.

  Lemma to_list_0 : to_list 0 = [].
  Proof. rewrite /to_list. by elim: enum. Qed.
End finite_bitmask_type_mixin.

(* All the above mixins in the right order, for when [bitmask_type_simple_mixin]
is appropriate. *)
Module Type simple_finite_bitmask_type_mixin (Import F : finite_type).
  Include finite_type_mixin F.
  Include bitmask_type_simple_mixin F.
  Include finite_bitmask_type_mixin F.
End simple_finite_bitmask_type_mixin.

Module Type finite_bitmask_type_intf := finite_type <+ bitmask_type <+ finite_bitmask_type_mixin.

(* A type for _sets_ of flags, as opposed to the type of flags described above. *)
Module finite_bits (BT : finite_bitmask_type_intf).
  Definition t := gset BT.t.
  #[global] Instance top_t : Top t := list_to_set (C := t) (enum BT.t).

  (*
  [to_bits] and [of_bits] implement a bitset encoding of [t] into N, given
  the encoding [to_bit : BT.t -> N].

  Conjecture: [to_bits] and [from_bits] should be partial inverses if [to_bit]
  and [from_bit] are.
  *)
  Definition of_bits (mask : N) : t := list_to_set $ BT.to_list mask.

  Lemma of_bits_0 : of_bits 0 = ∅.
  Proof. by rewrite /of_bits BT.to_list_0. Qed.

  Definition to_bits (rs : t) : N :=
    foldr (flip N.setbit) 0%N (BT.to_bit <$> elements rs).

  Definition to_bits_alt (rs : t) : N :=
    foldr N.lor 0%N (BT.to_bitmask <$> elements rs).

  Lemma to_bits_is_alt rs :
    to_bits rs = to_bits_alt rs.
  Proof.
    rewrite /to_bits /to_bits_alt /BT.to_bitmask !foldr_fmap.
    apply: foldr_ext => // b a.
    by rewrite /flip N.setbit_spec' comm_L.
  Qed.

  Lemma to_bits_alt_empty :
    to_bits_alt ∅ = 0%N.
  Proof. by rewrite /to_bits_alt elements_empty. Qed.

  Lemma to_bits_alt_singleton x :
    to_bits_alt {[x]} = BT.to_bitmask x.
  Proof. by rewrite /to_bits_alt elements_singleton /= N.lor_0_r. Qed.

  Lemma to_bits_alt_union_singleton x xs :
    x ∉ xs ->
    to_bits_alt ({[x]} ∪ xs) = N.lor (to_bits_alt {[ x ]}) (to_bits_alt xs).
  Proof.
    rewrite to_bits_alt_singleton /to_bits_alt.
    trans (foldr N.lor 0%N (BT.to_bitmask <$> x :: elements xs)) => //.
    apply foldr_permutation_proper'; [apply _ ..|].
    f_equiv. exact: elements_union_singleton.
  Qed.

  Definition masked (mask : N) (x : t) : t :=
    x ∩ of_bits mask.
  Definition masked_opt (mask : N) (x : t) : option t :=
    let res := masked mask x in
    guard (res = ∅); Some res.
End finite_bits.


(* Not necessarily restricted to [Finite] *)
Lemma nat_fin_iter_lt (c : nat) (P : nat -> Prop) :
  Forall P (seq 0 c) ->
  forall i, i < c -> P i.
Proof. move=>/Forall_seq /= F. eauto with lia. Qed.

Lemma nat_fin_iter_le (c : nat) (P : nat -> Prop) :
  Forall P (seq 0 (S c)) ->
  forall i, i <= c -> P i.
Proof. move=> F i Hle. eapply nat_fin_iter_lt; [done | lia]. Qed.

Lemma N_fin_iter_lt (c : N) (P : N -> Prop) :
  Forall P (seqN 0 c) ->
  forall i, (i < c)%N -> P i.
Proof.
  move=> F i Hle. rewrite -(N2Nat.id i).
  apply (nat_fin_iter_lt (N.to_nat c) (P ∘ N.of_nat)); [| lia] => {i Hle}.
  rewrite -Forall_fmap. apply F.
Qed.

Lemma N_fin_iter_le (c : N) (P : N -> Prop) :
  Forall P (seqN 0 (N.succ c)) ->
  forall i, (i <= c)%N -> P i.
Proof. move=> F i Hle. eapply N_fin_iter_lt; [done | lia]. Qed.
