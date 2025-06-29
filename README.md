<p align="center">
  <img src="./docs/assets/logo.svg" alt="project logo" width="250">
</p>

<h1 align="center">
  history-rewrite
</h1>
<p align="center">
</p>

[![Current Release](https://img.shields.io/github/release/sdsc-ordes/history-rewrite.svg?label=release)](https://github.com/sdsc-ordes/history-rewrite/releases/latest)
[![Pipeline Status](https://img.shields.io/github/actions/workflow/status/sdsc-ordes/history-rewrite/normal.yaml?label=ci)](https://github.com/sdsc-ordes/history-rewrite/actions/workflows/normal.yaml)
[![License label](https://img.shields.io/badge/License-MIT-blue.svg?)](https://mit-license.org/)

**Authors:**

- [Gabriel Nützi](mailto:gabriel.nuetzi@sdsc.ethz.ch)

## Installation

```shell
just develop
```

## Usage

To introduce files on the first commit to rewrite.

1. Place all files in `prepend/<git-path>`, e.g. `touch prepend/a/b/c/text.dat`.

   - These files will be fetched from the `main` branch and then prepended to
     the first commit with `git filter-repo`.

   - If `.gitattributes` file is also placed

Then use

```bash
just run
```

which will create a `server`

## Development

Read first the [Contribution Guidelines](/CONTRIBUTING.md).

For technical documentation on setup and development, see the
[Development Guide](docs/development-guide.md)

## Acknowledgement

Acknowledge all contributors and external collaborators here.

## Copyright

Copyright © 2025-2028 Swiss Data Science Center (SDSC),
[www.datascience.ch](http://www.datascience.ch/). All rights reserved. The SDSC
is jointly established and legally represented by the École Polytechnique
Fédérale de Lausanne (EPFL) and the Eidgenössische Technische Hochschule Zürich
(ETH Zürich). This copyright encompasses all materials, software, documentation,
and other content created and developed by the SDSC.
