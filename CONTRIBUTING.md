# Contributing

Keep the Ruby domain independent from HTTP, browser, image-file, and persistence concerns. Prefer small explicit objects and deterministic tests over framework abstractions or snapshots.

Before opening a pull request, run:

```sh
bundle install
bundle exec rake test
bundle exec bundle-audit check --update
find web/public/js -name '*.js' -print0 | xargs -0 -n1 node --check
```

If Zig is installed, also run:

```sh
cd native/zig
zig build test
```

Do not commit `native/zig/zig-out`, `.zig-cache`, temporary uploads, logs, or local environment files.