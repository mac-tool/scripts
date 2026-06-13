# scripts

A small collection of useful shell scripts for macOS and developer workflows.

## Scripts

### `github-download.sh`

Download an entire GitHub repository or a specific folder from a repository.

Example:

```bash
chmod +x github-download.sh

./github-download.sh \
  --user <github-user> \
  --repo <repo-name> \
  --branch main
```

Download a specific folder:

```bash
./github-download.sh \
  --user <github-user> \
  --repo <repo-name> \
  --branch main \
  --folder path/to/folder
```

### `png2icon.sh`

Convert a square PNG image into an `.icns` icon file or apply it as a custom icon to a macOS app or folder.

Example:

```bash
chmod +x png2icon.sh

./png2icon.sh ./my-logo.png ./AppIcon.icns
```

Apply an icon to an app or folder:

```bash
./png2icon.sh ./my-logo.png "/path/to/My App.app"
```

> Note: The PNG image should be square. A 1024x1024 PNG is recommended for best results.

## Requirements

These scripts are intended for macOS and may require common command-line tools such as:

* `bash`
* `git`
* `sips`
* `iconutil`
* `osascript`

Some tools are included with macOS, while others may need to be installed separately.

## Installation

Clone the repository:

```bash
git clone https://github.com/mac-tool/scripts.git
cd scripts
```

Make the scripts executable:

```bash
chmod +x *.sh
```

## Usage

Run any script directly from the repository folder:

```bash
./script-name.sh
```

For example:

```bash
./github-download.sh --help
./png2icon.sh --help
```

## Contributing

Contributions are welcome. Feel free to open an issue or submit a pull request with improvements, fixes, or new scripts.

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.
