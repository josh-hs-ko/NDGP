{-# OPTIONS --safe #-}

module Generics.Safe.RecursionScheme where

open import Prelude
open import Generics.Safe.Telescope
open import Generics.Safe.Description
open import Generics.Safe.Algebra
open import Generics.Safe.Recursion

private variable
  rb  : RecB
  cb  : ConB
  cbs : ConBs

FoldOpTᶜ : {I : Set ℓⁱ} (D : ConD I cb) → (I → Set ℓ) → Set (max-π cb ⊔ max-σ cb ⊔ ℓ)
FoldOpTᶜ (ι i  ) X = X i
FoldOpTᶜ (σ A D) X = (a : A) → FoldOpTᶜ (D a) X
FoldOpTᶜ (ρ D E) X = ⟦ D ⟧ʳ X → FoldOpTᶜ E X

FoldOpTelᶜˢ : {I : Set ℓⁱ} (D : ConDs I cbs) → (I → Set ℓ)
            → Tel (maxMap max-π cbs ⊔ maxMap max-σ cbs ⊔ hasCon? ℓ cbs)
FoldOpTelᶜˢ []       X = []
FoldOpTelᶜˢ (D ∷ Ds) X = FoldOpTᶜ D X ∷ constω (FoldOpTelᶜˢ Ds X)

fold-opᶜ : {I : Set ℓⁱ} (D : ConD I cb) {X : Carrierᶜ D ℓ} → FoldOpTᶜ D X → Algᶜ D X
fold-opᶜ (ι i  ) f refl       = f
fold-opᶜ (σ A D) f (a  , xs ) = fold-opᶜ (D a) (f a ) xs
fold-opᶜ (ρ D E) f (xs , xs') = fold-opᶜ  E    (f xs) xs'

fold-opᶜˢ : {I : Set ℓⁱ} (D : ConDs I cbs) {X : Carrierᶜˢ D ℓ}
          → ⟦ FoldOpTelᶜˢ D X ⟧ᵗ → Algᶜˢ D X
fold-opᶜˢ []       _        ()
fold-opᶜˢ (D ∷ Ds) (f , fs) (inl xs) = fold-opᶜ  D  f  xs
fold-opᶜˢ (D ∷ Ds) (f , fs) (inr xs) = fold-opᶜˢ Ds fs xs

fold-operator : ∀ {D N} → DataC D N → FoldP
fold-operator {D} C = record
  { Conv    = C
  ; #levels = suc (DataD.#levels D)
  ; levels  = snd
  ; Param   = λ (ℓ , ℓs) → let Dᵖ = DataD.applyL D ℓs in
      PDataD.Param Dᵖ
      ++ λ ps → (Curriedᵗ true (PDataD.Index Dᵖ ps) (λ _ → Set ℓ) ∷ constω [])
      ++ λ (X , _) → FoldOpTelᶜˢ (PDataD.applyP Dᵖ ps) (uncurryᵗ X)
  ; param   = fst
  ; Carrier = λ _ (_ , (X , _) , _) → uncurryᵗ X
  ; algebra = λ (ps , _ , args) →
                fold-opᶜˢ (PDataD.applyP (DataD.applyL D _) ps) args }

Homᶜ : {I : Set ℓⁱ} (D : ConD I cb) {X : I → Set ℓˣ} {Y : I → Set ℓʸ}
     → FoldOpTᶜ D X → FoldOpTᶜ D Y → (∀ {i} → X i → Y i)
     → ∀ {i} → ⟦ D ⟧ᶜ X i → Set (max-π cb ⊔ ℓʸ)
Homᶜ (ι i  ) x y h _ = h x ≡ y
Homᶜ (σ A D) f g h (a , xs) = Homᶜ (D a) (f a) (g a) h xs
Homᶜ (ρ D E) {X} {Y} f g h (xs , xs') =
  (ys : ⟦ D ⟧ʳ Y) → ExtEqʳ D ys (fmapʳ D h xs) → Homᶜ E (f xs) (g ys) h xs'

Homᶜˢ : {I : Set ℓⁱ} (D : ConDs I cbs) {X : I → Set ℓˣ} {Y : I → Set ℓʸ}
      → ⟦ FoldOpTelᶜˢ D X ⟧ᵗ → ⟦ FoldOpTelᶜˢ D Y ⟧ᵗ → (∀ {i} → X i → Y i)
      → Tel (maxMap max-π cbs ⊔ maxMap max-σ cbs ⊔ maxMap (hasRec? ℓˣ) cbs ⊔
              hasCon? ℓⁱ cbs ⊔ hasCon? ℓʸ cbs)
Homᶜˢ [] fs gs h = []
Homᶜˢ (D ∷ Ds) {X} (f , fs) (g , gs) h =
  (∀ {i} (xs : ⟦ D ⟧ᶜ X i) → Homᶜ D f g h xs) ∷ constω (Homᶜˢ Ds fs gs h)

fold-fusionʳ :
    {I : Set ℓⁱ} (D : RecD I rb) {N : I → Set ℓ} {X : I → Set ℓˣ} {Y : I → Set ℓʸ}
    (fold-fs : ∀ {i} → N i → X i) (fold-gs : ∀ {i} → N i → Y i)
  → (h : ∀ {i} → X i → Y i) (ns : ⟦ D ⟧ʳ N) → Allʳ D (λ _ n → h (fold-fs n) ≡ fold-gs n) ns
  → ExtEqʳ D (fmapʳ D fold-gs ns) (fmapʳ D h (fmapʳ D fold-fs ns))
fold-fusionʳ (ι i  ) fold-fs fold-gs h n  eq  = sym eq
fold-fusionʳ (π A D) fold-fs fold-gs h ns all =
  λ a → fold-fusionʳ (D a) fold-fs fold-gs h (ns a) (all a)

fold-fusionᶜ :
    {I : Set ℓⁱ} (D : ConD I cb) {N : I → Set ℓ} {X : I → Set ℓˣ} {Y : I → Set ℓʸ}
    (f : FoldOpTᶜ D X) (g : FoldOpTᶜ D Y)
    (fold-fs : ∀ {i} → N i → X i) (fold-gs : ∀ {i} → N i → Y i)
  → (h : ∀ {i} → X i → Y i) → (∀ {i} (xs : ⟦ D ⟧ᶜ X i) → Homᶜ D f g h xs)
  → ∀ {i} (ns : ⟦ D ⟧ᶜ N i) → Allᶜ D (λ _ n → h (fold-fs n) ≡ fold-gs n) ns ℓ'
  → h (fold-opᶜ D f (fmapᶜ D fold-fs ns)) ≡ fold-opᶜ D g (fmapᶜ D fold-gs ns)
fold-fusionᶜ (ι i  ) x y fold-fs fold-gs h hom refl all = hom refl
fold-fusionᶜ (σ A D) f g fold-fs fold-gs h hom (a , ns) all =
  fold-fusionᶜ (D a) (f a) (g a) fold-fs fold-gs h (curry hom a) ns all
fold-fusionᶜ (ρ D E) f g fold-fs fold-gs h hom (ns , ns') (all , all') =
  fold-fusionᶜ E (f (fmapʳ D fold-fs ns)) (g (fmapʳ D fold-gs ns)) fold-fs fold-gs h
    (λ xs → hom (fmapʳ D fold-fs ns , xs) (fmapʳ D fold-gs ns)
                (fold-fusionʳ D fold-fs fold-gs h ns all)) ns' all'

fold-fusionᶜˢ :
    {I : Set ℓⁱ} (D : ConDs I cbs) {N : I → Set ℓ} {X : I → Set ℓˣ} {Y : I → Set ℓʸ}
    (fs : ⟦ FoldOpTelᶜˢ D X ⟧ᵗ) (gs : ⟦ FoldOpTelᶜˢ D Y ⟧ᵗ)
    (fold-fs : ∀ {i} → N i → X i) (fold-gs : ∀ {i} → N i → Y i)
  → (h : ∀ {i} → X i → Y i) → ⟦ Homᶜˢ D fs gs h ⟧ᵗ
  → ∀ {i} (ns : ⟦ D ⟧ᶜˢ N i) → Allᶜˢ D (λ _ n → h (fold-fs n) ≡ fold-gs n) ns ℓ'
  → h (fold-opᶜˢ D fs (fmapᶜˢ D fold-fs ns)) ≡ fold-opᶜˢ D gs (fmapᶜˢ D fold-gs ns)
fold-fusionᶜˢ (D ∷ Ds) (f , _ ) (g , _ ) fold-fs fold-gs h (hom , _) (inl ns) all =
  fold-fusionᶜ  D  f  g  fold-fs fold-gs h hom ns all
fold-fusionᶜˢ (D ∷ Ds) (_ , fs) (_ , gs) fold-fs fold-gs h (_ , hom) (inr ns) all =
  fold-fusionᶜˢ Ds fs gs fold-fs fold-gs h hom ns all

fold-fusion-theorem :
  ∀ {D N} (C : DataC D N) → let p = fold-operator C in
  {fold : FoldGT p} (foldC : FoldC p fold) → IndP
fold-fusion-theorem {D} C {fold} foldC = record
  { Conv    = C
  ; #levels = suc (suc (DataD.#levels D))
  ; levels  = snd ∘ snd
  ; Param   = λ (ℓˣ , ℓʸ , ℓs) → let Dᵖ = DataD.applyL D ℓs in
      PDataD.Param Dᵖ
      ++ λ ps → let IT = PDataD.Index Dᵖ ps; Dᶜˢ = PDataD.applyP Dᵖ ps in
           (Curriedᵗ true  IT (λ _ → Set ℓˣ) ∷ λ X →
           (Curriedᵗ true  IT (λ _ → Set ℓʸ) ∷ λ Y →
           (Curriedᵗ false IT (λ is → uncurryᵗ X is → uncurryᵗ Y is) ∷ constω [])))
      ++ λ (X , Y , h , _) → FoldOpTelᶜˢ Dᶜˢ (uncurryᵗ X)
      ++ λ fs → FoldOpTelᶜˢ Dᶜˢ (uncurryᵗ Y)
      ++ λ gs → Homᶜˢ Dᶜˢ fs gs (λ {is} → uncurryᵗ h is) ++ constω []
  ; param   = fst
  ; Carrier = λ _ (ps , (X , Y , h , _) , fs , gs , _) is n →
                uncurryᵗ h is (fold (ps , (X , _) , fs) n) ≡ fold (ps , (Y , _) , gs) n
  ; algebra = λ (ps , (X , Y , h , _) , fs , gs , hom , _) {is} ns all →
      let Dᶜˢ = PDataD.applyP (DataD.applyL D _) ps in
      begin
        uncurryᵗ h is (fold (ps , (X , _) , fs) (DataC.toN C ns))
          ≡⟨ cong (uncurryᵗ h is) (FoldC.equation foldC ns) ⟩
        uncurryᵗ h is (fold-opᶜˢ Dᶜˢ fs (fmapᶜˢ Dᶜˢ (fold (ps , (X , _) , fs)) ns))
          ≡⟨ fold-fusionᶜˢ Dᶜˢ fs gs (fold (ps , (X , _) , fs)) (fold (ps , (Y , _) , gs))
               (λ {is} → uncurryᵗ h is) hom ns all ⟩
        fold-opᶜˢ Dᶜˢ gs (fmapᶜˢ Dᶜˢ (fold (ps , (Y , _) , gs)) ns)
          ≡⟨ sym (FoldC.equation foldC ns) ⟩
        fold (ps , (Y , _) , gs) (DataC.toN C ns)
      ∎ } where open ≡-Reasoning
