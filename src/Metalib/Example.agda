{-# OPTIONS -v meta:5  #-}
open import Prelude
  hiding ([_,_])

module Metalib.Example where

open import Utils.Reflection

open import Generics.Description
open import Generics.Telescope
open import Generics.Example

open import Metalib.Telescope
open import Metalib.Datatype

------------------------------------------------------------------------------
-- 
`T-Nat : Telescope × Type
`T-Nat = getTelescopeT ℕ

_ : evalT (fromTelescope $ fst `T-Nat) ≡ []
_ = refl

_ : (evalT (fromTel [])) ≡ (0 , fst `T-Nat)
_ = refl

------------------------------------------------------------------------------
-- Level-polymorphic telescope

`T-List : Telescope × Type
`T-List = getTelescopeT List

T-List : Tel 0ℓ
T-List = Level ∷ λ ℓ → {!Set ℓ !} 

------------------------------------------------------------------------------
-- 

data Rel (A : Set) : (xs ys : List A) → Set where
  
`T-rel : Telescope × Type
`T-rel = getTelescopeT Rel

_ : evalT (fromTelescope $ fst `T-rel) ≡ [ B ∶ Set ] [ bs ∶ List B ] [ bs ∶ List B ] []
_ = refl

_ : evalT (fromTel $ [ A ∶ Set ] [ xs ∶ List A ] [ ys ∶ List A ] []) ≡ (3 , fst `T-rel)
_ = refl


------------------------------------------------------------------------------
-- 

data Pointwise (A : Set) (B : Set) (R : A → B → Set) : (xs : List A) → (ys : List B) → Set where 

T-pointwise : Telescope
T-pointwise = fst $ getTelescopeT Pointwise 

_ : evalT (fromTelescope T-pointwise)
  ≡ [ A ∶ Set ] [ B ∶ Set ] [ R ∶ (A → B → Set) ] [ as ∶ List A ] [ bs ∶ List B ] []
_ = refl

_ : evalT (fromTel $ [ A ∶ Set ] [ B ∶ Set ] [ R ∶ (A → B → Set) ] [ xs ∶ List A ] [ ys ∶ List B ] []) ≡ (5 , T-pointwise)
_ = refl

-- Okay but unusual examples
sort-is-not-normal : Tel _
sort-is-not-normal = [ b ∶ if true then Bool else ⊥ ] [] 

`sort-is-not-normal : ℕ × Telescope
`sort-is-not-normal = evalT (fromTel sort-is-not-normal)

_ : sort-is-not-normal ≡ [ b ∶ Bool ] []
_ = refl
--
_ : `sort-is-not-normal ≢ evalT (fromTel ([ b ∶ Bool ] []))
_ = λ { () }

ex₁ : Bool → Tel _
ex₁ = λ b → []

`ex₁ : ℕ × Telescope
`ex₁ =  evalT (fromTel $ Bool ∷ ex₁)

-- Not really a telescope: 
bad : Tel _
bad = [ b ∶ Bool ] (case b of λ { true → [ n ∶ ℕ ] [] ; false → [] })

_ : Telescope
_ = {!evalT (toTelescope bad)!} -- when ?

data Len (A : Set ℓ) : List A → List A → Set ℓ where
  z : Len A [] []
  s : ∀ {x y xs ys} → Len A xs ys → Len A (x ∷ xs) (y ∷ ys)

PLenD : Level → PDataD
PLenD ℓ = record
  { level = ℓ
  ; level-pre-fixed-point = refl
  ; Param = Set ℓ ∷ const []
  ; Index = λ where
    (A , tt) → List A ∷ λ _ → List A ∷ const []
  ; applyP = λ where
    (A , tt) →
      ι ([] , [] , tt)
      ∷ Σ[ x ∶ A ]
        Σ[ y ∶ A ]
        Σ[ xs ∶ List A ]
        Σ[ ys ∶ {!!} ] ρ (ι (xs , ys , _)) (ι (x ∷ xs , y ∷ ys , _))
      ∷ []
   }

LenD : DataD
LenD = record
  { #levels = 1
  ; applyL  = λ where
    (ℓ , _) → PLenD ℓ
  }

unquoteDecl data newLen constructor newz news =
  defineByDataD LenD newLen (newz ∷ news ∷ [])

REL : {a b : Level} → Set a → Set b
    → (ℓ : Level) → Set (a ⊔ b ⊔ lsuc ℓ)
REL A B ℓ = A → B → Set ℓ

data Pointwise' {a b ℓ} {A : Set a} {B : Set b} (R : REL A B ℓ) : REL (Maybe A) (Maybe B) (a ⊔ b ⊔ ℓ) where
  just    : ∀ {x y} → R x y → Pointwise' R (just x) (just y)
  nothing : Pointwise' R nothing nothing

pointwiseD : DataD
pointwiseD = record
  { #levels = 3
  ; applyL = λ where
    (a , b , ℓ , tt) → record
      { level = a ⊔ b ⊔ ℓ
      ; level-pre-fixed-point = refl
      ; Param = [ A ∶ Set a ] [ B ∶ Set b ] [ R ∶ REL A B ℓ ] []
      ; Index = λ where
        (A , B , R , _) → [ _ ∶ Maybe A ] [ _ ∶ Maybe B ] []
      ; applyP = λ where
        (A , B , R , _) →
          Σ[ x ∶ A ] Σ[ y ∶ B ] Σ[ _ ∶ R x y ] ι (just x , (just y) , tt)
          ∷ ι (nothing , nothing , tt)
          ∷ []
      }
  }

--unquoteDecl data newPW constructor newJust newNothing =
--  defineByDataD pointwiseD newPW (newJust ∷ newNothing ∷ []) 

--kk : ∀ {A B : Set} {C : A → B → Set} → newPW A B C nothing nothing
--kk = newNothing

--telToD : TC _
--telToD = do t ← getType (quote newPW)
--            (tel , end) ← getTelescope (quote newPW)
--            let idx = PDataD.Index (DataD.applyL pointwiseD (lzero , lzero , lzero , tt)) (ℕ , List ℕ , (λ x s → length s ≡ x) , tt)
--            telescopeToRecD (quote newPW) 3 tel end idx >>= λ x →
--              {!!}

--idx = PDataD.Index (DataD.applyL pointwiseD (lzero , lzero , lzero , tt)) (ℕ , List ℕ , (λ x s → length s ≡ x) , tt)
idx = PDataD.Index (DataD.applyL LenD (lzero , tt)) (ℕ , tt)
test : TC _  --{tel : Tel ℓ} → (Σ RecB λ b → RecD ⟦ tel ⟧ᵗ b)
test = do t ← getType (quote news)
          dprint [ termErr t ]
          describeByConstructor (quote newLen) 1 1 {Index = idx} (quote news)

--unquoteDecl = test >> return tt
