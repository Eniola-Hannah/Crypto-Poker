import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Blob "mo:base/Blob";
import Random "mo:base/Random";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Buffer "mo:base/Buffer";
import Order "mo:base/Order";

actor PokerGame {
  type Card = {
    suit: Text;
    rank: Nat;
  };

  type Player = {
    id: Nat;
    hand: [Card];
    chips: Nat;
  };

  type Action = {
    #fold;
    #call;
    #raise: Nat;
  };

  var deck : [Card] = [];
  var players : [Player] = [];
  var currentBet : Nat = 0;
  var pot : Nat = 0;

  func initializeDeck() : [Card] {
    let suits = ["Hearts", "Diamonds", "Clubs", "Spades"];
    let buffer = Buffer.Buffer<Card>(52);
    for (suit in suits.vals()) {
      for (rank in Iter.range(2, 14)) {
        buffer.add({suit = suit; rank = rank});
      }
    };
    Buffer.toArray(buffer)
  };

  func shuffleDeck(d: [Card]) : async [Card] {
    let buffer = Buffer.fromArray<Card>(d);
    for (i in Iter.range(0, buffer.size() - 1)) {
        let randomBlob = await Random.blob();
        let randomBytes = Blob.toArray(randomBlob);
        if (randomBytes.size() > 0) {
            let randomByte = Nat8.toNat(randomBytes[0]);
            let j = randomByte % buffer.size();
            let temp = buffer.get(i);
            buffer.put(i, buffer.get(j));
            buffer.put(j, temp);
        };
    };
    Buffer.toArray(buffer)
  };

  public func initializeGame() : async Text {
    deck := initializeDeck();
    deck := await shuffleDeck(deck);
    players := [
      { id = 1; hand = []; chips = 1000 },
      { id = 2; hand = []; chips = 1000 },
      { id = 3; hand = []; chips = 1000 },
      { id = 4; hand = []; chips = 1000 }
    ];

    "Game initialized. All players are ready. \nYour Player ID is 4"
  };


  public func dealCards() : async Text {
    if (players.size() == 4 and deck.size() >= 8) {
      let buffer = Buffer.fromArray<Player>(players);
      for (i in Iter.range(0, buffer.size() - 1)) {
        let player = buffer.get(i);
        let newHand = [deck[i*2], deck[i*2+1]];
        buffer.put(i, {id = player.id; hand = newHand; chips = player.chips});
      };
      players := Buffer.toArray(buffer);
      deck := Array.tabulate(deck.size() - 8, func (i : Nat) : Card { deck[i + 8] });
      "Cards dealt!"
    } else {
      "Not enough players or cards to deal!"
    }
  };

  public func evaluateHand(playerId: Nat) : async Text {
    switch (Array.find(players, func(p: Player) : Bool { p.id == playerId })) {
      case (null) { "Player not found" };
      case (?p) {
        let handRanks = Array.map(p.hand, func(card: Card) : Nat { card.rank });
        let maxRank = Array.foldLeft(handRanks, 0, Nat.max);
        let handDescription = switch (maxRank) {
          case (14) { "Ace-high" };
          case (13) { "King-high" };
          case (12) { "Queen-high" };
          case (11) { "Jack-high" };
          case (_) { Nat.toText(maxRank) # "-high" };
        };
        "Player " # Nat.toText(playerId) # " has " # handDescription;
      };
    }
  };

 func indexOfOpt<T>(array: [T], element: T, equal: (T, T) -> Bool) : ?Nat {
    for (i in Iter.range(0, array.size() - 1)) {
      if (equal(array[i], element)) {
        return ?i;
      };
    };
    null
  };

  public func playerAction(playerId: Nat, action: Action) : async Text {
    if (playerId != 4) {
      return "It's not your turn!";
    };

    let buffer = Buffer.fromArray<Player>(players);
    let playerOpt = Array.find<Player>(players, func(p: Player) : Bool { p.id == playerId });

    switch (playerOpt) {
      case (null) { return "Player not found" };
      case (?player) {
        let indexOpt = indexOfOpt<Player>(players, player, func(a: Player, b: Player) : Bool { a.id == b.id });
        
        switch (indexOpt) {
          case (null) { return "Player index not found" }; // This should never happen if the player was found
          case (?index) {
            switch (action) {
              case (#fold) {
                buffer.filterEntries(func(_, p: Player) : Bool { p.id != playerId });
                players := Buffer.toArray(buffer);
                return "Player " # Nat.toText(playerId) # " folds";
              };
              case (#call) {
                let callAmount = currentBet - (pot / players.size());
                let player = buffer.get(index);
                if (player.chips < callAmount) {
                  return "Not enough chips to call";
                };
                buffer.put(index, {
                  id = player.id;
                  hand = player.hand;
                  chips = player.chips - callAmount;
                });
                pot += callAmount;
                players := Buffer.toArray(buffer);
                return "Player " # Nat.toText(playerId) # " calls";
              };
              case (#raise(amount)) {
                let player = buffer.get(index);
                if (player.chips < amount) {
                  return "Not enough chips to raise";
                };
                buffer.put(index, {
                  id = player.id;
                  hand = player.hand;
                  chips = player.chips - amount;
                });
                pot += amount;
                currentBet := amount;
                players := Buffer.toArray(buffer);
                return "Player " # Nat.toText(playerId) # " raises to " # Nat.toText(amount);
              };
            };
          };
        };
      };
    };
  };

  var communityCards : [Card] = [];
  var currentRound : Nat = 0; // 0: pre-flop, 1: flop, 2: turn, 3: river

  public func dealCommunityCards() : async Text {
    switch(currentRound) {
      case 0 { // Flop
        communityCards := Array.tabulate(3, func(i: Nat) : Card { deck[i] });
        deck := Array.tabulate(deck.size() - 3, func(i: Nat) : Card { deck[i + 3] });
        currentRound += 1;
        "Flop dealt"
      };
      case 1 { // Turn
        communityCards := Array.append(communityCards, [deck[0]]);
        deck := Array.tabulate(deck.size() - 1, func(i: Nat) : Card { deck[i + 1] });
        currentRound += 1;
        "Turn dealt"
      };
      case 2 { // River
        communityCards := Array.append(communityCards, [deck[0]]);
        deck := Array.tabulate(deck.size() - 1, func(i: Nat) : Card { deck[i + 1] });
        currentRound += 1;
        "River dealt"
      };
      case _ { "All community cards have been dealt" };
    }
  };

  func handRank(hand: [Card]) : Nat {
    // This is a very simplified hand ranking.
    let ranks = Array.map(hand, func(card: Card) : Nat { card.rank });
    let maxRank = Array.foldLeft(ranks, 0, Nat.max);
    maxRank
  };

  public func determineWinner() : async Text {
    if (currentRound < 3) {
      return "The game is not over yet";
    };

    var winningPlayer : ?Player = null;
    var winningScore : Nat = 0;

    for (player in players.vals()) {
      let fullHand = Array.append(player.hand, communityCards);
      let score = handRank(fullHand);
      if (score > winningScore) {
        winningScore := score;
        winningPlayer := ?player;
      };
    };

    switch (winningPlayer) {
      case (null) { "No winner determined" };
      case (?winner) { 
        "Player " # Nat.toText(winner.id) # " wins with a score of " # Nat.toText(winningScore) 
      };
    }
  };

  public func getGameState() : async Text {
    var state = "Current round: " # Nat.toText(currentRound) # "\n";
    state #= "Community cards: " # debug_show(communityCards) # "\n";
    state #= "Players:\n";
    for (player in players.vals()) {
      state #= "  Player " # Nat.toText(player.id) # ": " # debug_show(player.hand) # ", Chips: " # Nat.toText(player.chips) # "\n";
    };
    state #= "Pot: " # Nat.toText(pot) # "\n";
    state
  };
};