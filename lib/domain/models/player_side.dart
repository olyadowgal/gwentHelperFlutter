enum PlayerSide { first, second }

extension PlayerSideOpposite on PlayerSide {
  PlayerSide get opposite =>
      this == PlayerSide.first ? PlayerSide.second : PlayerSide.first;
}
