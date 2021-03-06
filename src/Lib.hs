module Lib where

newtype Symbol = Symbol { unSymbol :: String } deriving (Eq,Show,Read)

-- (1)
data TermS = SymS Symbol        -- x
           | LamS Symbol TermS  -- \x -> t
           | AppS TermS TermS   -- t1 t2
           deriving (Eq,Show,Read)

-- (2)
data TermI = SymI Int
           | LamI TermI
           | AppI TermI TermI
           deriving (Eq,Show,Read)

sym x = SymS (Symbol x)
lam x t = LamS (Symbol x) t
app t1 t2 = AppS t1 t2

-- (2)
-- перевод выражения в TermI
toTermI :: TermS -> TermI
toTermI term = toTermI' term []
toTermI' (SymS sym) args  = SymI (staticDistance sym args 0)
toTermI' (LamS sym term) args = LamI (toTermI' term ([sym] ++ args))
toTermI' (AppS t1 t2) args = AppI (toTermI' t1 args) (toTermI' t2 args)

staticDistance :: Symbol -> [Symbol] -> Int -> Int
staticDistance sym [] distance = distance
staticDistance sym (curr:rest) distance = (if sym == curr then distance else staticDistance sym rest (distance + 1))

-- (2)
-- шаг редукции
betaI :: TermI -> Maybe TermI
betaI (SymI sym) = Nothing
betaI (LamI t) = case (betaI t) of
  Nothing -> Nothing
  Just innerT -> Just $ LamI innerT
betaI (AppI (LamI t1) t2) = Just $ doApp t1 t2
betaI (AppI (AppI t1 t2) t3) = case (betaI $ AppI t1 t2) of
  Just innerT -> Just $ AppI innerT t3
  Nothing -> Nothing
betaI (AppI t1 t2) = case betaI t2 of
  Just innerT -> Just (AppI t1 innerT)
  Nothing -> Nothing

doApp :: TermI -> TermI -> TermI
doApp t1 t2 = doApp' t1 t2 0
doApp' (LamI t1) t2 distance = LamI $ doApp' t1 t2 (distance + 1)
doApp' (AppI term1 term2) term3 distance = AppI (doApp' term1 term3 distance) (doApp' term2 term3 distance)
doApp' (SymI s) t distance
  | distance == s = (recalcDistances t 0 distance)
  | s > distance = SymI (s - 1)
  | otherwise = SymI s

recalcDistances :: TermI -> Int -> Int -> TermI
recalcDistances (SymI s) newDistance distance
  | newDistance <= s = SymI $ s + distance
  | otherwise = SymI s
recalcDistances (AppI term1 term2) newDistance distance = AppI (recalcDistances term1 newDistance distance) (recalcDistances term2 newDistance distance)
recalcDistances (LamI term) newDistance distance = LamI $ recalcDistances term (newDistance + 1) distance

-- выполнять редукцию до конца (но не больше 10000 шагов из-за возможности зависания)
full :: (TermS -> a) -> (a -> Maybe a) -> TermS -> a
full a b term = lastUnf 10000 b (a term)
  where lastUnf :: Int -> (a -> Maybe a) -> a -> a
        lastUnf 0 _ x = x
        lastUnf n f x = case f x of
          Nothing -> x
          Just y -> lastUnf (n-1) f y

data TermP = TermP TermS
           | Boolean Bool
           -- (4)
           | Natural Int
           | Plus TermP TermP
           | Mult TermP TermP
           -- (4*) +10%
           | Minus TermP TermP
           | Divide TermP TermP
           -- (5*) +50%
           | Y TermP
           -- (7)
           | Cons TermP TermP
           | Nil
           | IsNil TermP
           | Head TermP
           | Tail TermP
           deriving (Eq,Show,Read)

toTermS :: TermP -> TermS

successor 0 f x = sym x
successor n f x = app (sym f) $ successor (n - 1) f x

plus = lam "n" $ lam "m" $ lam "f" $ lam "x" $ app (app (sym "n") (sym "f")) $ app (app (sym "m") (sym "f")) $ sym "x"
multiply = lam "n" $ lam "m" $ lam "f" $ lam "x" $ app (app (sym "n") (app (sym "m") (sym "f"))) $ sym "x"

ycomb = lam "f" $ app y y where
  y = lam "x" $ app (sym "f") $ app (sym "x") (sym "x")

false = lam "f" $ lam "x" $ sym "x"
true = lam "f" $ lam "x" $ sym "f"

churchNumber num = lam "f" $ lam "x" $ successor num "f" "x"

toTermS (Natural num) = churchNumber num
toTermS (Plus n1 n2) = app (app plus $ toTermS n1) $ toTermS n2
toTermS (Mult n1 n2) = app (app multiply $ toTermS n1) $ toTermS n2
toTermS (Y t) = app ycomb $ toTermS t
toTermS (Boolean True) = true
toTermS (Boolean False) = false

toTermS (TermP term) = term

solve :: TermP -> Either TermI TermS

solve = Left . full toTermI betaI . toTermS
