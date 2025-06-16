# History Rewrite

To introduce files on the first commit to rewrite.

Place all files in `prepend/<git-path>`, e.g. `touch prepend/a/b/c/text.dat`.
These files need to be on the `main` branch.

Then use

```bash
URL="<git-repo-url>" ./rewrite.sh
```

which will create a `server` repo which is rewritten and
ready for inspection and push.
