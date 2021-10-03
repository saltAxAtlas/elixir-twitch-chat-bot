# Twitch Chat Bot [Elixir]
A general purpose Twitch chat bot written in Elixir.

## TODO:
-   [X] Words on Stream Command
    - [ ] Account for Hidden Letters
    - [ ] Account for Fake Letters
-   [X] Random GIF
    - [X] Trending Page
    - [X] Search
-   [ ] Counters
    - [ ] Add Counter
    - [ ] Remove Counter
    - [ ] Display Counter Value
-   [ ] Dice Roll / Coin Flip
-   [ ] Auto Count `I'm New` Redemptions
-   [ ] Handle New Sub 
-   [ ] Handle Cheer
-   [ ] Handle New Follower
-   [ ] Handle `Skip Song` Redemption (PUBSUB + Spotify API)
-   [X] Command List
-   [X] Help Command
-   [X] Change Bot Color
-   [ ] Spotify API (Get Current Song) -> Streamlabs API (Update Playing Song)
-   [ ] Spotify API (Play Song from Approved Playlist)

## Installation
-   Run `mix deps.get`
-   Replace information in `example_config.exs` -> Rename to `config.exs`
-   Run `iex -S mix`
