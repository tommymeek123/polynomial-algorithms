module DenseMonom ( Monomial
                  , totalDegree
                  , multiDegree
                  ) where

import GHC.TypeLits (Symbol, Nat, KnownNat)
import Data.Proxy (Proxy(..))
import Data.Reflection (reflect)
import qualified Data.Vector.Fixed as V
import qualified Data.Vector.Fixed.Unboxed as UV
import qualified RingParams as RP
import PolyParsers (Readable(..), monListFromString, monListToString)

type Mon = Monomial

newtype Monomial :: Nat -> RP.MonOrder -> * where
    MakeMon :: { degVec :: UV.Vec n Int } -> Monomial n o

deriving instance V.Arity n => Eq (Mon n o)

instance V.Arity n => Ord (Mon n RP.Lex) where
    compare a b = compare (degVec a) (degVec b)

instance V.Arity n => Ord (Mon n RP.Glex) where
    compare a b = let aVb = compare (totalDegree a) (totalDegree b)
                  in  if aVb == EQ
                      then compare (degVec a) (degVec b)
                      else aVb

instance V.Arity n => Ord (Mon n RP.GRevLex) where
    compare a b = let aVb = compare (totalDegree a) (totalDegree b)
                      a' = V.reverse $ degVec a
                      b' = V.reverse $ degVec b
                  in  if aVb == EQ
                      then compare b' a'
                      else aVb

instance V.Arity n => Show (Mon n o) where
    show m = monListToString (V.toList $ degVec m)

instance V.Arity n => Semigroup (Mon n o) where
    a <> b = MakeMon { degVec = V.zipWith (+) (degVec a) (degVec b) }

instance (KnownNat n, V.Arity n) => Monoid (Mon n o) where
    mempty = MakeMon $ V.fromList' $ take nn (repeat 0)
        where nn = (fromInteger . reflect) (Proxy :: Proxy n)

instance (KnownNat n, V.Arity n) => Readable (Mon n o) where
    fromString :: forall n o. (KnownNat n, V.Arity n) => String -> Mon n o
    fromString s = MakeMon { degVec = V.fromList' $ monListFromString nn s }
        where nn = (fromInteger . reflect) (Proxy :: Proxy n)

totalDegree :: V.Arity n => Mon n o -> Int
totalDegree = V.sum . degVec

multiDegree :: V.Arity n => Maybe (Mon n o) -> Maybe [Int]
multiDegree Nothing = Nothing
multiDegree (Just m) = (Just . V.toList . degVec) m
