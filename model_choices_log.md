# Log of modelling choices
This file acts as a log-file to collect our discussions and ideas about modelling the game Beverbende using Swift and ACT-R.


## Initial ideas after playing the game for the first time

### Challenges
To successfully play the game one not only needs to maintain some representation of one's own cards but also form some assumptions about the cards of the opponents. The latter is especially important for forming the decision to end the game, since the player should be confident that the own point count is lower than the number of points of each opponent. Thus, declarative memory plays an important role in this game, and can possibly affect modelling in different ways. Some initial ideas we had to utilize the delcarative module in ACT-R involve:

- Form chunks of one's own deck
- Rehearse/Sub-vocalize the current representation of one's own deck
- Maintain track of game outcomes to decide at what point count one should end the game

### Playing the game
The game is turn based, and therefore clearly defines when the model needs to engage in an action. However, we still need to keep track of the different game states and control how a model should react in different game stages. We will likely rely on the goal buffer available in ACT-R to approximate, in combination with the production rules available, a finite state machine. When a regular card is drawn, the model needs to decide whether to swap one of its cards with this new card. This should always be done if the model knows about a card that is higher than this new card. However, there will almost always be situations in a game when the model does not know about all cards available to it, so it would still have to learn what kind of cards are low enough to justify swapping them with an unknown card. Alternatively, this could be based on a cut-off: e.g. cards lower than 4 are always worth engaging in such a switch. The latter one might be harder to motivate though, so learning a strategy might be more appropriate.

Dealing with action cards appropriately depends on the card. The peak card should be used to look at the card for which the model currently has the least amount of information. If the model has cards that it never was able to look at, then one of those cards should be selected. However, if the model has some idea about all cards, we need to find a way to determine which card the model is currently the most unsure about. One idea we had was to use retrieval latency as a measure to determine the card where the model is most uncertain about and to then pick this card to look at it.

The pick again card is related to how we deal with the regular cards, e.g. figuring out a way to decide whether the current card is low enough to be chosen for a swap or not.

The switch card is more difficult. We considered using a heuristic: picking a card that was recently swapped by an opponent. This is based on the assumption that an opponent would be likely to engage in a swap only if the new card would offer an improvement (based on the opponents' assumptions about the card which is swapped). Thus, if the model knows that it still has a high card, then picking this card is very likely to offer an improvement to the model as well.

### Ending the Game
The decision to end an ongoing game could be based on a cut-off again. E.g. if the model is confident that it currently has less than X points, then it will decide to end the game. Otherwise, this deicision could be learned by playing a lot of games and forming memories of the number of points either the model or its opponents had when winning a round. We have considered to use game simulations to let models play against each other to learn such a rule.