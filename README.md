# Ps Commons

> Common or reusable code used by PrintSpeak to help isolate our abstractions.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ps-commons'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install ps-commons
```

## Stories

### Main Story

As a developer, I want to isolate and test a common library of code, used by PrintSpeak, so that we can build better abstractions.

See all [stories](./STORIES.md)


## Usage

See all [usage examples](./USAGE.md)



## Development

Checkout the repo

```bash
git clone https://github.com/printspeak/ps-commons
```

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. 

You can also run `bin/console` for an interactive prompt that will allow you to experiment.

```bash
bin/console

Aaa::Bbb::Program.execute()
# => ""
```

`ps-commons` is setup with Guard, run `guard`, this will watch development file changes and run tests automatically, if successful, it will then run rubocop for style quality.

To release a new version, update the version number in `version.rb`, build the gem and push the `.gem` file to [rubygems.org](https://rubygems.org).

```bash
rake publish
rake clean
```

## Conventional commit helpers

This project uses conventional commits to help with versioning and changelogs. 

```bash
kfeat "add new feature"
kfix "fix bug"
kchore "update readme"
kdocs "update readme"
ktest "add tests"
krefactor "refactor code"
```


## Git helpers used by this project

Add the follow helpers to your `alias` file

```bash
function kcommit()
{
  echo 'git add .'
  git add .
  echo "git commit -m "$1""
  git commit -m "$1"
  echo 'git pull'
  git pull
  echo 'git push'
  git push
  sleep 3
  run_id="$(gh run list --limit 1 | grep -Eo "[0-9]{9,11}")"
  gh run watch $run_id --exit-status && echo "run completed and successful" && git pull && git tag | sort -V | tail -1
}
function kchore     () { kcommit "chore: $1" }
function kdocs      () { kcommit "docs: $1" }
function kfix       () { kcommit "fix: $1" }
function kfeat      () { kcommit "feat: $1" }
function ktest      () { kcommit "test: $1" }
function krefactor  () { kcommit "refactor: $1" }
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Ps Commons project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/klueless-io/ps-commons/blob/master/CODE_OF_CONDUCT.md).

## Copyright

Copyright (c) David Cruwys. See [MIT License](LICENSE.txt) for further details.
