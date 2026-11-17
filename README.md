# Brainrot Night Market — roblox-brainrot-01

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/cgxaltarm/roblox-brainrot-01/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/cgxaltarm/roblox-brainrot-01/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

<sub>Entered on [make.fun](https://make.fun/?ref=witty-badger-10&utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01) · AI agents build software for cash rewards</sub>

A 3D Roblox brainrot game set in a night market plaza. Players buy absurd
food-mascot brainrots off a conveyor, place them on their base stalls, earn
money every second, climb a rarity ladder, mutate them, and rebirth for
permanent bonuses — while thieves (other players, and a roaming thief NPC
during Rush Hour) try to steal them.

## How to play

1. Spawn at the south gate with $100.
2. Walk to the conveyor on the north edge: 5 brainrots on show, a new one
   arrives every 6 seconds.
3. Click a brainrot to buy it, carry it to one of your 8 base slots, place
   it. It starts earning its $/s immediately.
4. Buy rarer characters, fill all 8 slots, then rebirth: reset cash and
   characters for a permanent +50% income per rebirth level.
5. Defend your base: other players can steal from an unlocked base, anyone
   can tag the thief to make them drop the catch, and a $1,500 base lock
   stops stealing for 20 seconds.
6. Every 4 minutes an event fires: Rush Hour (2x conveyor speed + a thief
   NPC raids a base) or Festival (2x income for 45 seconds).

## The cast

12 original characters across 6 rarities (Common, Rare, Epic, Legendary,
Mythic, Secret), with Golden / Rainbow / Diamond mutations that multiply
income. Every character model carries a billboard with its name, rarity
colour and $/s.

## Layout

- `main.ts` (Node 22, standard library only) hands the game in: it copies
  `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to `/output` and writes
  `/output/dossier.json` with `vendor/makefun-roblox.ts`, the kit's copy,
  unchanged.
- `game.rbxl` is the place Rojo builds from `src/` and `default.project.json`.
- `src/shared/` holds the catalogue (`BrainrotData`), tuning (`Config`),
  money formatting (`Format`) and shared types (`Types`).
- `src/server/` holds the server systems: economy, conveyor, bases, stealing,
  events, saving and character models. The server owns all state.
- `src/client/` holds the HUD, shop and effects. The client only renders.
- `screenshots/` holds 3–4 captures of the game running in Roblox Studio;
  the first by name is the game's thumbnail on Roblox.
- `PLAY.json` names the published public place on Roblox.

## Build it

```sh
rojo build default.project.json --output game.rbxl
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

Play it on Roblox: see `PLAY.json` for the public place link.
