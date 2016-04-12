{-# OPTIONS_GHC -fdefer-typed-holes #-}

module TicTacToe where

import           Data.List   (maximumBy, sortBy)
import           Data.Map    (Map, empty, insert, lookup, toList)
import           Data.Maybe  (isJust)
import           Data.Monoid (First (..), getFirst, (<>))
import           Data.Ord    (comparing)
import           Neet
import           Prelude     hiding (lookup)

type ScoringFunction = Genome -> Genome -> (Double, Double) --TODO move to main module?

data Player = X | O deriving (Enum, Eq, Show)

type BoardPos = Int
type Board    = Map BoardPos Player

move :: Player -> BoardPos -> Board -> Maybe Board
move p xy b | isJust (lookup xy b) = Nothing
            | otherwise            = Just (insert xy p b)

getWinner :: Board -> Maybe Player
getWinner b = getFirst (r0 <> r1 <> r2 <> c0 <> c1 <> c2 <> d0 <> d1)
  where
    r0 = check 0 1 2
    r1 = check 3 4 5
    r2 = check 6 7 8
    c0 = check 0 3 6
    c1 = check 1 4 7
    c2 = check 2 5 8
    d0 = check 0 4 8
    d1 = check 2 4 6
    check xy1 xy2 xy3 | lookup xy1 b == lookup xy2 b
                     && lookup xy1 b == lookup xy3 b = First (lookup xy1 b)
                      | otherwise                    = First Nothing

play :: (Board -> BoardPos) -> (Board -> BoardPos) -> (Double, Double)
play = play' X empty
  where
    play' turn board p1 p2 = case winner of Nothing -> scores
                                            Just X -> (1,-1)
                                            Just O -> (-1,1)
      where
        winner = getWinner board
        moveResult = case turn of X -> move X (p1 board) board
                                  O -> move O (p2 board) board
        scores = case moveResult of Nothing -> failed turn
                                    Just b -> play' (succ turn) b p1 p2
        failed X = (-2,0)
        failed O = (0,-2)

scoreTicTacToe :: ScoringFunction
scoreTicTacToe g1 g2 = play (abstractGenome g1 X) (abstractGenome g2 O)

abstractGenome :: Genome -> (Player -> Board -> BoardPos)
abstractGenome g p board = maximumBy (comparing (outputs !!)) [0..8]
  where
    net     = mkPhenotype g
    inputs  = map (\x -> if snd x == p then 1 else -1) . sortBy (comparing fst) $ toList board
    outputs = getOutput (snapshot net inputs)

