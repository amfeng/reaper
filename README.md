reaper
======

Too many outdated issues cluttering up your issue tracker? Reaper is a handy tool that "reaps" them -- that is, if an issue hasn't been updated in over 3 months, it'll post a friendly notice on the issue and tag it as `to-reap`. The next time reaper runs (I like to run it in weekly increments), it'll close any issues that were tagged.

![screen shot 2015-05-21 at 10 15 47 pm](https://cloud.githubusercontent.com/assets/286015/7764483/ff043714-0006-11e5-824d-04a3efcbc51a.png)

To use reaper, you can just install the gem:

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

Happy reaping!

(Bugs, feature requests, or contributions? Feel free to file an issue! PRs also very welcome.)
