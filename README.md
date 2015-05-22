reaper
======

```
$ gem install github-reaper
```

Create and grab your Github access token from: https://github.com/settings/tokens. You'll need to export it as an environment variable before you call reaper. Then, use `reaper` by giving it a repository name.

```
$ export GITHUB_ACCESS_TOKEN=<ACCESS_TOKEN>
$ reaper -r amfeng/reaper
```

This will prompt you for confirmation every time it warns or closes an issue. If you'd rather have it run without requiring confirmation, include the `-s` flag.


```
$ reaper -r amfeng/reaper -s
```
