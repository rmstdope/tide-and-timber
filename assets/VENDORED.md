# Vendored assets

| Asset | Version | Source | SHA-256 | Licence |
|---|---|---|---|---|
| Press Start 2P | google/fonts@92345ac | https://github.com/google/fonts/raw/92345ac0dbb28d27dbd32f3a782e84c55eaac214/ofl/pressstart2p/PressStart2P-Regular.ttf | 034c77f1f05ec89421e4a63f0e3a4ca1ecf852cc6d2bf611f126f275728e017d | OFL-1.1 (assets/fonts/OFL.txt) |
| Pixel Crawler - Free Pack | 2.11 | assets/vendor/pixel_crawler/Pixel Crawler - Free Pack 2.11.zip, downloaded from Anokolisa (https://www.patreon.com/Anokolisa) | b7b228ca232da9958f191b01db87764dddb67610116151e06e8dd8ade6de94b8 | Anokolisa's terms: commercial use and alteration allowed, credit not required, not to be sold as assets (assets/vendor/pixel_crawler/LICENSE) |
| Retro Inventory | undated | assets/vendor/elv_games/Retro Inventory.zip, bought from ElvGames (https://twitter.com/ElvGames) | 3b3460c4665cb2d03e956e7fcb475ff30aaffd257b74e22ffeba801689c6a3be | ElvGames' terms: commercial use and alteration allowed, **credit to ElvGames required**, not to be sold as assets (assets/vendor/elv_games/LICENSE) |
| Farming 101 | undated | assets/vendor/pixel_echoes/Farming 101.zip, downloaded from Pixel Echoes (https://pixelechoes.itch.io/) | ed7b321ec358fa841b5735d7bd0e598f58b2b9ae8b28e1f99bb3fc04d724cb31 | Pixel Echoes' terms: commercial use and alteration allowed, credit not required, not to be redistributed or resold as assets (assets/vendor/pixel_echoes/LICENSE) |

The Pixel Crawler PNGs are unpacked from that zip, paths unchanged below its top folder, into assets/pixel_crawler/. The .aseprite sources and Terms.txt stay only in the zip.

The Retro Inventory PNGs are unpacked from the zip's `Original/` folder only, paths unchanged below it, into assets/retro_inventory/; the `Scaled 2x/` and `Scaled 3x/` copies stay only in the zip, since the game integer-scales from its 640x360 base. The Farming 101 PNGs are unpacked, paths unchanged below the zip's top folder, into assets/farming_101/. Each pack's licence text is copied out of its zip into assets/vendor/.
