# Pronto runner for ansible-lint
Pronto runner for [ansible-lint](https://github.com/ansible/ansible-lint), a Python Style Guide Enforcer. [What is Pronto?](https://github.com/mmozuras/pronto)


## Contribution Guidelines
### Installation
`git clone` this repo and `cd pronto-ansible_lint`


Ruby
```sh
brew install cmake # or your OS equivalent
brew install rbenv # or your OS equivalent
rbenv install 2.4.5 # or newer
rbenv global 2.4.5 # or make it project specific
gem install bundle
gem install pronto
bundle install
```

Python
```sh

virtualenv venv # tested on Python 2.7 and 3.6
source venv/bin/activate
pip install -r requirements.txt
```

Make your changes
```sh
git checkout -b <new_feature>
# make your changes
bundle exec rspec
gem build pronto-ansible_lint.gemspec
gem install pronto-ansible_lint-<current_version>.gem # get current version from previous command
uncomment the lines in dummy_playbook/dummy.py
pronto run --unstaged
```

It should show
```sh
dummy_playbook/example.yml:9: [E301] [HIGH] Commands should not change things if nothing needs doing
dummy_playbook/example.yml:10: [E206] [LOW] Variables should have spaces before and after: {{ var_name }}
dummy_playbook/example.yml:12: [E301] [HIGH] Commands should not change things if nothing needs doing

```

## Changelog

0.1.0 Initial public version. Based heavily on https://github.com/scoremedia/pronto-flake8
