# Bumbur

A small cli application combining Bumblebee and Burrito.

## How to use

Run `mix deps.get` to get the dependencies.
Run `mix run --no-halt -- start` to start the server, this will download the models from huggingface the first time you run it.
Run `mix run -- ask "meow"` to ask the server if an owl or a cat is more likely to say "meow".

## Build a standalone executable

Run `MIX_ENV=prod mix release` to build a standalone executable using [burrito](https://hexdocs.pm/burrito/readme.html).

Current targets (configured in `mix.exs`):
  - macos: [os: :darwin, cpu: :aarch64]
  - linux: [os: :linux, cpu: :x86_64] (there is a linker issue, so this executable might not work for you)
