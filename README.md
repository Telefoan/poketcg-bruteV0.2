# Pokémon Trading Card Game, Brute Ver0.1

This is a modified disassembly of Pokémon Trading Card Game for the Game Boy Color.

For an overview of the changes that were made to the original game, see [**CHANGELOG.md**](CHANGELOG.md)

To assemble, first download RGBDS (https://github.com/gbdev/rgbds/releases) and extract it to /usr/local/bin.
Run `make` in your shell. This will output a file named "poketcg_v2.gbc".

For more detailed instructions about how to set up the repository, see [**INSTALL.md**](INSTALL.md).

watermelon princess here, this project is to see if i can transfer the code changes in Electro's poketcg-extended that allow
for up to 511 cards into Shaoden's poketcg_V2, which has a very optimized code set. wish me luck!

# poketcg-extended readme:

Modified disassembly of [Pokémon TCG](https://github.com/pret/poketcg) that supports double the cards as the vanilla game, meant to be used as a base for hacks. The modified engine supports up to 510 cards, as opposed to 254 from the base game. For everything else this repo stays as faithful as possible to the vanilla game.

These changes are built upon the [tinytcg branch](https://github.com/ElectroDeoxys/poketcg/tree/tinytcg). Please read that repo's `README.md` for more details.

## Technical details

The engine has gone through an overhaul based on the features in the sequel, which also supports card IDs up to `0x1ff`. This is not a true 16-bit engine since many of the systems in-game rely on card IDs fitting inside a 9-bit integer. This corresponds to how the game stores which cards are in the collection and how it compresses saved decks in SRAM.

<br/>

## See also:
- [Discord server for PokeTCG Hacking]
- [Discord server for pret]
- [Hacking Tutorials]
- [Unaltered Disassembly]

[Discord server for PokeTCG Hacking]: https://discord.gg/K2kfTx2xRf
[Discord server for pret]: https://discord.gg/d5dubZ3
[Hacking Tutorials]: https://github.com/pret/poketcg/wiki/Tutorials
[Unaltered Disassembly]: https://github.com/pret/poketcg
