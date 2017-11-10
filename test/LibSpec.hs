module LibSpec where

import Test.Hspec

import Lib

spec = do
  it "toTermI" $ do
    toTermI (lam "x" $ app (lam "x" $ sym "x") (lam "x" $ lam "y" $ app (sym "y") (lam "y" $ sym "x"))) `shouldBe` LamI (AppI (LamI (SymI 0)) (LamI (LamI (AppI (SymI 0) (LamI (SymI 2))))))

  it "betaI" $ do
    betaI (LamI $ AppI (AppI (LamI $ LamI $ SymI 1) (SymI 0)) (LamI $ SymI 0)) `shouldBe` (Just $ LamI $ AppI (LamI $ SymI 1) (LamI $ SymI 0))

  it "solve" $ do
    solve (TermP (lam "x" $ app (lam "x" $ sym "x") (lam "x" $ lam "y" $ sym "y"))) `shouldBe` Left (LamI (LamI (LamI (SymI 0))))
