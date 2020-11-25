# Terraform for Mayastor

This repo contains an experimental implementation of Terraform scripts for installing Mayastor to Kubernetes running on different cloud providers. Content will be eventually merged into Mayastor main repository.

Content is *highly unstable*. Please, don't use in production.

Status:
- Hetzner Cloud is working
- AWS in working
- Azure postponed at the moment
- GCP postponed at the moment

# GitHub CI

You can run checks locally with `make` or `act -P ubuntu-latest=node:12.6-buster` using [`act`](https://github.com/nektos/act).
