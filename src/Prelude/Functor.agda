module Prelude.Functor where

open import Data.List as L
  using (List)

open import Agda.Primitive
open import Agda.Builtin.Reflection

private
  variable
    a b : Level

record Functor (F : Set a → Set b) : Set (lsuc a ⊔ b) where 
  infixl 4 _<$>_ _<$_
  field
    map : {A B : Set a}
      → (A → B) → F A → F B

  _<$>_ : ∀ {A B} → (A → B) → F A → F B
  _<$>_ = map
  {-# INLINE _<$>_ #-}

  _<$_ : ∀ {A B} → A → F B → F A
  x <$ m = map (λ _ → x) m
  {-# INLINE _<$_ #-}
open Functor {{...}} public 

{-# DISPLAY Functor.map   _ = map  #-}
{-# DISPLAY Functor._<$>_ _ = _<$>_ #-}
{-# DISPLAY Functor._<$_  _ = _<$_  #-}

instance
  ListFunctor : Functor {a} List
  map ⦃ ListFunctor ⦄ = L.map

  TCFunctor : Functor {a} TC
  map ⦃ TCFunctor ⦄ f xs = bindTC xs λ x → returnTC (f x)

  ArgFunctor : Functor {a} Arg
  map ⦃ ArgFunctor ⦄ f (arg i x) = arg i (f x)

  ArgsFunctor : Functor {a} λ A → List (Arg A)
  map ⦃ ArgsFunctor ⦄ f xs = L.map (map f) xs

  AbsFunctor : Functor {a} Abs
  map ⦃ AbsFunctor ⦄ f (abs s x) = abs s (f x)
