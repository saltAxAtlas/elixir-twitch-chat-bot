# Twitch Chat Bot [Elixir]
A general purpose Twitch chat bot written in Elixir.

## TODO:
-   [X] Command List
-   [X] Help Command
-   [X] Change Bot Color
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
-   [ ] PubSub
    -   [ ] Channel Point Redemptions
        -   [ ] Auto Count `I'm New` Redemptions
        -   [ ] VS Code Theme Changer
        -   [ ] Handle `Skip Song` Redemption (Spotify API)
    -   [ ] Handle Sub 
    -   [ ] Handle Bits
    -   [ ] Handle Follower
-   [ ] Spotify API 
    -   [ ] Get Current Song -> Update Playing Song (Streamlabs API)
    -   [ ] Play Song from Approved Playlist

## Installation
-   run `mix deps.get`
-   replace information in `example_config.exs` -> rename to `config.exs`
-   run `iex -S mix`
