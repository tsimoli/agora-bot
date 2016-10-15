# AgoraBot

Displays players paragon elo rating on discord channel. Uses paragon.gg rating.

## Usage

!elo <player_name>

## Installation
- mix deps.get
- add your bot token to confix.exs
- build release with distellery.
  - mix release.init
  - mix release
- run bot
  - rel/agora_bot/bin/agora_bot console/start
- add bot to your channel https://discordapp.com/oauth2/authorize?client_id=<client_id>&scope=bot&permissions=0
- try it out!
  - !elo <player_name>

## Running with docker
- build release
- install edib
  - mix archive.install https://git.io/edib-0.9.0.ez
- mix edib --name agora-bot
- docker run -d agora-bot:latest
