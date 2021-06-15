{-# OPTIONS -v meta:3 #-}

open import Reflection
import Reflection.Name
import Level as Level
--open import Reflection.Clause
open import Tactic.MonoidSolver

open import Data.Unit
open import Data.Empty
open import Data.Bool
open import Data.Nat
open import Data.Nat.Properties
open import Data.List
open import Agda.Builtin.Sigma
open import Data.Product
open import Function.Base using (case_of_)

open import Relation.Nullary

open import Relation.Binary.PropositionalEquality
  using (_≡_;
 refl)

lemma : ∀ x y z → (x + y) + z ≡ x + (y + z)
lemma x y z = solve +-0-monoid


_ : quoteTerm 1 ≡ lit (nat 1)
_ = refl

_ : quoteTerm zero ≡ con (quote zero) []
_ = refl

_ : quoteTerm (suc zero) ≡ con (quote suc) (vArg (con (quote zero) []) ∷ [])
_ = refl

_ : quoteTerm ℕ ≡ def (quote ℕ) []
_ = refl

_ : Name
_ = quote _≡_

one = 1

_ : quoteTerm one ≡ def (quote one) []
_ = refl

_ : Name
_ = quote one

plus-to-times′ : Term → Term → TC _
plus-to-times′ (def (quote _+_) (a ∷ b ∷ [])) hole = do
  debugPrint "meta" 2 [ strErr "hello world" ]
  unify hole (def (quote _*_) (a ∷ b ∷ []))
plus-to-times′ v hole = unify hole v

macro
  plus-to-times : Term → (Term → TC ⊤)
  plus-to-times (def (quote _+_) (a ∷ b ∷ [])) hole = unify hole (def (quote _*_) (a ∷ b ∷ []))
  plus-to-times v hole = unify hole v

thm : (a b : ℕ) → plus-to-times (a + b) ≡ a * b
thm a b = refl

macro
  isMacro? : Name → Term → TC ⊤
  isMacro? id hole = do
    isMacro id >>= λ where
      false → debugPrint "meta" 2 (nameErr id ∷ [ strErr " is NOT a macro" ])
      true  → debugPrint "meta" 2 (nameErr id ∷ [ strErr " is a macro" ])
    unify hole (quoteTerm tt)

macro
  showTerm′ : Term → Term → TC ⊤
  showTerm′ t hole = do
    debugPrint "meta" 2 [ termErr t ]
    unify hole (quoteTerm tt)

macro
  showType : Name → Term → TC _
  showType t hole = do
               t2 ← getType t
               t3 ← inferType t2
               debugPrint "meta" 2 [ termErr t3 ]
               unify hole (quoteTerm tt)

--data RGB : Set where
--  Red Green Blue : RGB

--“ℓ₀” : Arg Term
--“ℓ₀” = hArg (def (quote Level.zero) [])

--“RGB” : Arg Term
--“RGB” = hArg (def (quote RGB) [])
--
--“Red” : Arg Term
--“Red” = vArg (con (quote Red) [])

--unquoteDecl IsRed =
--  do ty ← quoteTC (RGB → Set)
--     declareDef (vArg IsRed) ty
--     defineFun IsRed [ Reflection.Clause.clause
--                         [ ("x" , vArg (def (quote RGB) [])) ]
--                         [ vArg (Pattern.var 0) ]
--                         (def (quote _≡_) (“ℓ₀” ∷ “RGB” ∷ “Red” ∷ vrv 0 [] ∷ [])) ]

data ListA (A : Set) : Set where
  nil  : ListA A
  cons : A → ListA A → ListA A

data ListB (A : Set) : Set where
  nil'  : ListB A
  cons' : A → ListB A → ListB A

isNilType : Type → TC Bool
isNilType (pi (hArg (agda-sort (Sort.lit 0)))
              (abs _ (def _ (vArg (var 0 []) ∷ [])))) = return true
isNilType _ = return false

isConsType : Type → TC Bool
isConsType (pi (hArg (agda-sort (Sort.lit 0)))
               (abs _ (pi (vArg (var 0 []))
                          (abs _ (pi (vArg (def a (vArg (var 1 []) ∷ [])))
                                     (abs _ (def b (vArg (var 2 []) ∷ [])))
                                 )
                          )
                      )
               )
           ) = return (does (a Reflection.Name.≟ b))
isConsType _ = return false

macro
  isNilMacro : Name → Term → TC _
  isNilMacro n hole = do
                 getType n >>= isNilType >>= λ where
                   false → debugPrint "meta" 2  (nameErr n ∷ strErr " is not Nil!" ∷ [])
                   true  → debugPrint "meta" 2  (nameErr n ∷ strErr " is Nil!" ∷ [])

macro
  isConsMacro : Name → Term → TC _
  isConsMacro n hole = do
                  getType n >>= isConsType >>= λ where
                    false → debugPrint "meta" 2  (nameErr n ∷ strErr " is not Cons!" ∷ [])
                    true  → debugPrint "meta" 2  (nameErr n ∷ strErr " is Cons!" ∷ [])
--A : ⊤
--A = showTerm′ (quoteTerm ({A : Set} → A → ListA A → ListA A))

A₁ : ⊤
A₁ = isNilMacro nil

A₂ : ⊤
A₂ = isNilMacro cons

B₁ : ⊤
B₁ = isConsMacro nil

B₂ : ⊤
B₂ = isConsMacro cons

notcons : {A : Set} → A → ListB A → ListA A
notcons = _

B₃ : ⊤
B₃ = isConsMacro notcons

lengthA : {A : Set} → ListA A → ℕ
lengthA nil = 0
lengthA (cons x xs) = suc (lengthA xs)

data VecA (A : Set) : (n : ℕ) → Set where
  nilV  : VecA A 0
  consV : {n : ℕ} → (a : A) → VecA A n → VecA A (n + 1)

VecC : (A : Set) → (n : ℕ) → Set
VecC A zero = ⊤
VecC A (suc n) = A × VecC A n

isNil : Name → Name → TC Set
isNil c x = do t ← getType c
               case t of λ { (con c (x ∷ [])) → return (isNilArg x) ; _ → return ⊥ }

isCons : Name → Name → TC Set
isCons c x = do t ← getType c
                case t of λ { (con c (x ∷ [])) → return (isNilArg x) ; _ → return ⊥ }

isList' : Name → Definition → TC Set
isList' x (data-type pars (b ∷ s ∷ [])) = do isnil  ← isNil b x
                                             iscons ← isCons s x
                                             return (isnil × iscons)
isList' _ _ = return ⊥

isList : Name → TC Set
isList n = do df ← getDefinition n
              return Name

macro
  listToVec' : Name → Term → TC _
  --listToVec' (def (quote nil) []) hole = unify hole (def (quote nilV) [])
  --listToVec (def (quote cons) (x ∷ xs ∷ [])) hole =
  --                                   unify hole (def (quote consV) (hra ∷ ? ∷ ? ∷ [] ))
  listToVec' n hole = do df ← getDefinition n
                         return tt
