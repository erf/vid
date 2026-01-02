# COMMANDS

## Test

```
dart test
```

## Build

```
dart compile exe bin/vid.dart -o build/vid
```

See [build.sh](build.sh)


## Profile

```
dart run --pause-isolates-on-start --observe bin/vid.dart sample-data/eval.c
```