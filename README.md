# libplacebo-build

build scripts for [libplacebo](https://github.com/haasn/libplacebo)

## Installation

### Swift Package Manager

```
https://github.com/mpvkit/libplacebo-build.git
```

## How to build

```bash
swift run --package-path scripts
```

or 

```bash
# deployment platform: macos,ios,tvos,maccatalyst
swift run --package-path scripts build platforms=ios,macos
```