(** Further lemmas on the interpretation function, separated here in order to keep [TypeTheory.Initiality.Interpretation] itself reasonably streamlined *)

Require Import UniMath.MoreFoundations.All.
Require Import UniMath.CategoryTheory.All.

Require Import TypeTheory.Auxiliary.Auxiliary.
Require Import TypeTheory.Auxiliary.Partial.
Require Import TypeTheory.ALV1.TypeCat.
Require Import TypeTheory.Initiality.SplitTypeCat_General.
Require Import TypeTheory.Initiality.SplitTypeCat_Structure.
Require Import TypeTheory.Initiality.SplitTypeCat_Maps.
Require Import TypeTheory.Initiality.Syntax.
Require Import TypeTheory.Initiality.Typing.
Require Import TypeTheory.Initiality.Interpretation.

Section Functoriality_General.
(** Preparatory for section [Functoriality] below: some generalities on functoriality, independent of the logical structure. *)

  Context {C C'} (F : typecat_mor C C').

  (* TODO: consider, probably upstream at least to with [fmap_tm], etc. *)
  Local Definition fmap_ty := typecat_mor_Ty F.

  Definition fmap_type_with_term {Γ:C} (Aa : type_with_term Γ)
    : type_with_term (F Γ).
  Proof.
    exists (typecat_mor_Ty F _ (type_of Aa)).
    exact (fmap_tm F Aa).
  Defined.

  Definition fmap_environment {Γ:C} {n:nat} (E : environment Γ n)
    : environment (F Γ) n.
  Proof.
    intros i. exact (fmap_type_with_term (E i)). 
  Defined.

  Lemma fmap_extend_environment {Γ} {n} (E : environment Γ n) (A : C Γ)
    : fmap_environment (extend_environment E A)
    = reind_environment (typecat_mor_iso F _)
      (extend_environment (fmap_environment E) (fmap_ty _ A)).
  Proof.
  Admitted.

  Lemma fmap_extend_environment' {Γ} {n} (E : environment Γ n) (A : C Γ)
    : extend_environment (fmap_environment E) (fmap_ty _ A)
    = reind_environment (inv_from_iso (typecat_mor_iso F _))
      (fmap_environment (extend_environment E A)).
  Proof.
  Admitted.

  (* TODO: after some use, see which direction of [fmap_extend_environment] is more useful.  Indeed, consider at some point which direction of [typecat_mor_iso] is used more often and so should be taken as primitive. *)
End Functoriality_General.

Section Functoriality.
(** Key property of the interpretation: if [F : C --> D] is a map of split type-cats with logical structure, and some expression [e] is interpretable in [C] in some environment [E] with value [a], then [e] is also interpretable in [D] in environment [F E], with value [F a]. *)

  Context {C} {U : universe_struct C} {Π : pi_struct C}
          {C'} {U' : universe_struct C'} {Π' : pi_struct C'}
          {F : typecat_mor C C'}
          (F_U : preserves_universe_struct U U' F)
          (F_Π : preserves_pi_struct Π Π' F).

  Fixpoint
    fmap_partial_interpretation_ty
      {Γ:C} {n:nat} (E : environment Γ n) (e : ty_expr n)
    : leq_partial
        (fmap_partial (fun A => typecat_mor_Ty F _ A)
           (partial_interpretation_ty U Π E e))
        (partial_interpretation_ty U' Π' (fmap_environment F E) e)
  with
    fmap_partial_interpretation_tm
      {Γ:C} {n:nat} (E : environment Γ n) (T : C Γ) (e : tm_expr n)
    : leq_partial
        (fmap_partial (fun a => fmap_tm F a)
           (partial_interpretation_tm U Π E T e))
        (partial_interpretation_tm U' Π' (fmap_environment F E)
                                   (typecat_mor_Ty F _ T)
                                   e).
  Proof.
  (* Note: entire proof closely parallels that of [reindex_partial_interpretation], essentially since reindexing is a map of CwA’s and the reindexing axioms say precisely that it is structure_preserving. *)
    - (* type expressions *)
      destruct e as [ n | n a | n A B ].
      + (* [U_expr] *)
        cbn. apply leq_partial_of_path.
        eapply pathscomp0. { apply fmap_return_partial. }
        apply maponpaths. apply fmap_universe; assumption.
      + (* [El_expr a] *)
        assert (IH_a := fun T => fmap_partial_interpretation_tm Γ n E T a).
        (* part for [a] argument *)
        cbn. eapply leq_partial_trans.
        { apply leq_partial_of_path, fmap_bind_partial. }
        eapply leq_partial_trans.
        2: { eapply bind_leq_partial_1. 
          eapply leq_partial_trans.
          2: { refine (tm_transportf_partial_interpretation_tm_leq _ _ _).
               apply (fmap_universe F_U). }
             apply fmap_leq_partial, IH_a. }
        eapply leq_partial_trans.
        2: { apply leq_partial_of_path, pathsinv0.
             eapply pathscomp0; apply bind_fmap_partial_1. }
        apply bind_leq_partial_2; intros a_interp; cbn.
        (* final naturality part *)
        apply leq_partial_of_path.
        eapply pathscomp0. { apply fmap_return_partial. }
        apply maponpaths, fmap_elements.
      + (* [Pi_expr A B] *)
        assert (IH_A := fmap_partial_interpretation_ty Γ n E A).
        assert (IH_B := fun Γ E => fmap_partial_interpretation_ty Γ (S n) E B).
        (* part for [A] argument *)
        cbn. eapply leq_partial_trans.
        { apply leq_partial_of_path, fmap_bind_partial. }
        eapply leq_partial_trans.
        2: { eapply bind_leq_partial_1, IH_A. }
        eapply leq_partial_trans.
        2: { apply leq_partial_of_path, pathsinv0, bind_fmap_partial_1. }
        apply bind_leq_partial_2; intros A_interp; cbn.
        (* part for [B] argument *)
        eapply leq_partial_trans.
        { apply leq_partial_of_path, fmap_bind_partial. }
        eapply leq_partial_trans.
        2: { eapply bind_leq_partial_1.
             eapply leq_partial_trans.
             2: { apply leq_partial_of_path.
                  apply maponpaths_2, pathsinv0, fmap_extend_environment'. }
             eapply leq_partial_trans.
             2: { apply reindex_partial_interpretation_ty. }
             apply fmap_leq_partial, IH_B. }
        eapply leq_partial_trans.
        2: { apply leq_partial_of_path, pathsinv0.
             eapply pathscomp0; apply bind_fmap_partial_1. }
        apply bind_leq_partial_2; intros B_interp; cbn.
        (* final naturality part *)
        apply leq_partial_of_path.
        eapply pathscomp0. { apply fmap_return_partial. }
        apply maponpaths.
        admit. (* TODO: should be [preserves_pi_form], once defined. *)
    - (* term expressions *)
      destruct e as [ m i | m A B b | m A B t a ].
      + (* [var_expr i] *)
        cbn. eapply leq_partial_trans.
        { apply leq_partial_of_path, fmap_assume_partial. }
        use assume_partial_leq. { exact (maponpaths _). }
        cbn. intros e_T; destruct e_T.
        apply leq_partial_of_path.
        eapply pathscomp0. { apply fmap_return_partial. }
        apply maponpaths. cbn.
        eapply pathscomp0. { apply maponpaths, tm_transportf_idpath. }
        apply pathsinv0, tm_transportf_idpath.
      + (* [lam_expr A B b] *)
        admit.
        (*
        assert (IH_A := 
          reindex_partial_interpretation_ty Γ Γ' f m E A).
        assert (IH_B := fun Γ Γ' f E =>
          reindex_partial_interpretation_ty Γ Γ' f (S m) E B).
        assert (IH_b := fun Γ Γ' f E T =>
          reindex_partial_interpretation_tm Γ Γ' f (S m) E T b).
        (* Note: the beginning of this, dealing with the [A B] inputs,
           is almost exactly a copy-paste from the [Pi_expr A B] case
           (and similarly for the [app_expr] case below). *)
        (* part for [A] argument *)
        cbn. eapply leq_partial_trans.
        { apply leq_partial_of_path, fmap_bind_partial. }
        eapply leq_partial_trans.
        2: { eapply bind_leq_partial_1, IH_A. }
        eapply leq_partial_trans.
        2: { apply leq_partial_of_path, pathsinv0, bind_fmap_partial_1. }
        apply bind_leq_partial_2; intros A_interp; cbn.
        (* part for [B] argument *)
        eapply leq_partial_trans.
        { apply leq_partial_of_path, fmap_bind_partial. }
        eapply leq_partial_trans.
        2: { eapply bind_leq_partial_1.
             eapply leq_partial_trans.
             2: { apply leq_partial_of_path.
                  apply maponpaths_2, reind_extend_environment. }
             apply (IH_B _ _ (q_typecat A_interp f)). }
        eapply leq_partial_trans.
        2: { apply leq_partial_of_path, pathsinv0, bind_fmap_partial_1. }
        apply bind_leq_partial_2; intros B_interp; cbn.
        (* part for [b] argument *)
        eapply leq_partial_trans.
        { apply leq_partial_of_path, fmap_bind_partial. }
        eapply leq_partial_trans.
        2: { eapply bind_leq_partial_1.
          eapply leq_partial_trans.
          2: { apply leq_partial_of_path.
            eapply (maponpaths (fun E => partial_interpretation_tm _ _ E _ _)),
                   reind_extend_environment. }
          apply (IH_b _ _ (q_typecat A_interp f)). }
        eapply leq_partial_trans.
        2: { apply leq_partial_of_path, pathsinv0, bind_fmap_partial_1. }
        apply bind_leq_partial_2; intros b_interp; cbn.
        (* part for assumption on [T] *)
        eapply leq_partial_trans.
        { eapply leq_partial_of_path, fmap_assume_partial. }
        use assume_partial_leq.
        { cbn; intros e_T.
          eapply pathscomp0. 2: { eapply (maponpaths (fun A => A ⦃f⦄)), e_T. }
          apply pathsinv0, pi_form_struct_natural. }
        cbn. intros e_T; destruct e_T.
        (* final naturality part *)
        apply leq_partial_of_path. cbn.
        eapply pathscomp0. { apply fmap_return_partial. }
        apply maponpaths. rewrite tm_transportf_idpath.
        eapply pathscomp0. { apply pi_intro_struct_natural. }
        apply tm_transportf_irrelevant.
        *)
      + (* [app_expr A B t a] *)
        admit.
        (*
        assert (IH_A := 
          reindex_partial_interpretation_ty Γ Γ' f m E A).
        assert (IH_B := fun Γ Γ' f E =>
          reindex_partial_interpretation_ty Γ Γ' f (S m) E B).
        assert (IH_t := fun T =>
          reindex_partial_interpretation_tm Γ Γ' f m E T t).
        assert (IH_a := fun T =>
          reindex_partial_interpretation_tm Γ Γ' f m E T a).
        (* part for [A] argument *)
        cbn. eapply leq_partial_trans.
        { apply leq_partial_of_path, fmap_bind_partial. }
        eapply leq_partial_trans.
        2: { eapply bind_leq_partial_1, IH_A. }
        eapply leq_partial_trans.
        2: { apply leq_partial_of_path, pathsinv0, bind_fmap_partial_1. }
        apply bind_leq_partial_2; intros A_interp; cbn.
        (* part for [B] argument *)
        eapply leq_partial_trans.
        { apply leq_partial_of_path, fmap_bind_partial. }
        eapply leq_partial_trans.
        2: { eapply bind_leq_partial_1.
             eapply leq_partial_trans.
             2: { apply leq_partial_of_path.
                  apply maponpaths_2, reind_extend_environment. }
             apply (IH_B _ _ (q_typecat A_interp f)). }
        eapply leq_partial_trans.
        2: { apply leq_partial_of_path, pathsinv0, bind_fmap_partial_1. }
        apply bind_leq_partial_2; intros B_interp; cbn.
        (* part for [a] argument *)
        eapply leq_partial_trans.
        { apply leq_partial_of_path, fmap_bind_partial. }
        eapply leq_partial_trans.
        2: { eapply bind_leq_partial_1, IH_a. }
        eapply leq_partial_trans.
        2: { apply leq_partial_of_path, pathsinv0, bind_fmap_partial_1. }
        apply bind_leq_partial_2; intros a_interp; cbn.
        (* part for [t] argument *)
        eapply leq_partial_trans.
        { apply leq_partial_of_path, fmap_bind_partial. }
        eapply leq_partial_trans.
        2: { eapply bind_leq_partial_1.
          eapply leq_partial_trans.
          2: { refine (tm_transportf_partial_interpretation_tm_leq _ _ _). 
               apply pi_form_struct_natural. }
          apply fmap_leq_partial, IH_t. }
        eapply leq_partial_trans.
        2: { apply leq_partial_of_path, pathsinv0.
             eapply pathscomp0; apply bind_fmap_partial_1. }
        apply bind_leq_partial_2; intros t_interp; cbn.
        (* assumption on [T] *)
        eapply leq_partial_trans.
        { eapply leq_partial_of_path, fmap_assume_partial. }
        use assume_partial_leq.
        { cbn; intros e_T.
          eapply pathscomp0. 2: { eapply (maponpaths (fun A => A ⦃f⦄)), e_T. }
          eapply pathscomp0. { apply pathsinv0, reind_comp_typecat. }
          eapply pathscomp0. 2: { apply reind_comp_typecat. }
          (* TODO: unify duplicate access functions [reind_comp_typecat],
             [reind_comp_type_typecat]. *)
          apply maponpaths, reind_tm_q. }
        cbn. intros e_T; destruct e_T.
        (* final naturality part *)
        apply leq_partial_of_path. cbn.
        eapply pathscomp0. { apply fmap_return_partial. }
        apply maponpaths. rewrite tm_transportf_idpath.
        eapply pathscomp0. { apply pi_app_struct_natural. }
        apply tm_transportf_irrelevant.
      *)
  Admitted.

End Functoriality.