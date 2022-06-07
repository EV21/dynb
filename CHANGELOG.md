# Changelog


## 0.3.3 (2022-06-07)

### Fix

* Wrong parameter name for DuckDNS. [Eduard Veit]

### Documentation

* 📝 add comments to docker-compose.yml example. [Eduard Veit]


## 0.3.2 (2022-05-26)

### Features

* ✨ add tzdata to Dockerfile for timezone config. [Eduard Veit]

  You can now set your timezone with the environment variable
  `TZ="Europe/Berlin"`


## 0.3.1 (2022-05-26)

### Fix

* 🐛 curl/libcurl doesn't support dns-server option. [Eduard Veit]

  the latest alpine we are using for the docker image
  does also drops the support for that option like debian/ubuntu/etc


## 0.3.0 (2022-05-26)

### Features

* ✨ validate ip address respons from ip check web service. [Eduard Veit]

* ✨ check internet connection for selected ip versions. [Eduard Veit]

* 🎨 colorful info, debug and error messages. [Eduard Veit]

### Fix

* Abort on all dig errors. [Eduard Veit]

### Documentation

* 📝 add labels to Dockerfile. [Eduard Veit]


## 0.2.0 (2021-09-24)

### Features

* ✨ enable parameter extensions for `docker run --interactive` [Eduard Veit]

### Changed

* Handle dns server selection. [Eduard Veit]

### Documentation

* 📝 update CHANGELOG.md. [Eduard Veit]

* 📝 document docker parameters. [Eduard Veit]

* 📝 change default dns server setting. [Eduard Veit]

* 📝 update CHANGELOG. [Eduard Veit]

* 📝 update README.md. [Eduard Veit]


## 0.1.2 (2021-04-23)

### Documentation

* 📝 document environment variables. [Eduard Veit]


## 0.1.1 (2021-04-23)

### Fix

* 🐛 fix loop and error handling in case of connection issues. [Eduard Veit]


## 0.1.0 (2021-04-22)

### Features

* ✨ add Dockerfile. [Eduard Veit]

* ✨ add loop mode. [Eduard Veit]

* ✨ add support for Duck DNS as DynDNS2 provider. [Eduard Veit]

* ✨ add support for deSEC as DynDNS2 provider. [Eduard Veit]

* ✨ add completion. [Eduard Veit]

  ✨ add man page

* 🔃 replace getopt with argbash. [Eduard Veit]

* ✨ add interpretaton of status codes and act accordingly. [Eduard Veit]

* ✨ make network interface configurable. [Eduard Veit]

* ✨ add DynDNS2 support for dynv6.com. [Eduard Veit]

### Added

* 📝 README.md. [Eduard Veit]

* ✨ dynb.sh. [Eduard Veit]

### Changed

* 🔃 rename environment variables. [Eduard Veit]

### Fix

* 🐛 fix error handling. [Eduard Veit]

* 🐛 fix sourcing of config file. [Eduard Veit]

  ♻️ do some shellcheck fixes

### Documentation

* 📝 document example of an docker-compose.yml file. [Eduard Veit]

* 📝 document `loop mode` and mention `dig` as requirement. [Eduard Veit]

* 📝 update example of .env in README.md. [Eduard Veit]

* 📝 CHANGELOG.md. [Eduard Veit]

* 📝 add example.env. [Eduard Veit]


