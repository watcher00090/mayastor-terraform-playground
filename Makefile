# Run gitlab actions locally.
#
# Run `make` to know if github actions would fail or succeed.
#
# You need:
#   * act binary https://github.com/nektos/act
#   * docker
#   * make

ci:
	act -P ubuntu-latest=node:12.6-buster

