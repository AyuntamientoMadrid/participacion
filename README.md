<!--
  Title: CONSUL DEMOCRACY
  Description: Citizen Participation and Open Government Application
  Keywords: democracy, citizen participation, eparticipation, debates, proposals, voting, consultations, crowdlaw, participatory budgeting.
-->

![CONSUL DEMOCRACY logo](https://raw.githubusercontent.com/consuldemocracy/consuldemocracy/master/public/consul_logo.png)

# CONSUL DEMOCRACY

Citizen Participation and Open Government Application

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](http://www.gnu.org/licenses/agpl-3.0)
[![Accessibility conformance](https://img.shields.io/badge/accessibility-WAI:AA-green.svg)](https://www.w3.org/WAI/eval/Overview)

![Build status](https://github.com/consuldemocracy/consuldemocracy/workflows/tests/badge.svg)
[![Code Climate](https://codeclimate.com/github/consuldemocracy/consuldemocracy/badges/gpa.svg)](https://codeclimate.com/github/consuldemocracy/consuldemocracy)
[![Coverage Status](https://coveralls.io/repos/github/consuldemocracy/consuldemocracy/badge.svg)](https://coveralls.io/github/consuldemocracy/consuldemocracy?branch=master)
[![Crowdin](https://d322cqt584bo4o.cloudfront.net/consul/localized.svg)](https://translate.consuldemocracy.org/)
[![Knapsack Pro Parallel CI builds for RSpec tests](https://img.shields.io/badge/Knapsack%20Pro-Parallel%20/%20RSpec%20tests-%230074ff)](https://knapsackpro.com/dashboard/organizations/176/projects/202/test_suites/318/builds?utm_campaign=organization-id-176&utm_content=test-suite-id-318&utm_medium=readme&utm_source=knapsack-pro-badge&utm_term=project-id-202)

[![Help wanted](https://img.shields.io/badge/help-wanted-brightgreen.svg?style=flat-square)](https://github.com/consuldemocracy/consuldemocracy/issues?q=is%3Aopen+label%3A"help+wanted")

This is the opensource code repository of the eParticipation website CONSUL DEMOCRACY, originally developed for the Madrid City government eParticipation website, and currently maintained by the open source software community in collaboration with the CONSUL DEMOCRACY Foundation.

## Documentation

Check the [ongoing documentation](https://docs.consuldemocracy.org/index) to learn more about how to start your own CONSUL DEMOCRACY fork, install it, customize it and learn to use it as an administrator/maintainer.

## CONSUL DEMOCRACY Foundation and project website

You can access the main website of the project at [http://consuldemocracy.org](http://consuldemocracy.org) where you can find information about the use of the platform, the CONSUL DEMOCRACY Foundation, the global community of users and local partners, news, and ways to get more support or get in touch.

## Configuration for development and test environments

**NOTE**: For more detailed instructions, check the [local installation docs](docs/en/installation/local_installation.md).

Prerequisites: install git, Ruby 3.2.7, CMake, pkg-config, Node.js 20.18.3, ImageMagick and PostgreSQL (>=9.5).

**Note**: The `bin/setup` command below might fail if you've configured a username and password for PostgreSQL. If that's the case, edit the lines containing `username:` and `password:` (adding your credentials) in the `config/database.yml` file and run `bin/setup` again.

```bash
git clone https://github.com/consuldemocracy/consuldemocracy.git
cd consuldemocracy
bin/setup
bin/rake db:dev_seed
```

Run the app locally:

```bash
bin/rails s
```

You can run the tests with:

```bash
bin/rspec
```

Note: running the whole test suite on your machine might take more than an hour, so it's strongly recommended that you setup a Continuous Integration system in order to run them using parallel jobs every time you open or modify a pull request (if you use GitHub Actions or GitLab CI, this is already configured in `.github/workflows/tests.yml` and `.gitlab-ci.yml`) and only run tests related to your current task while developing on your machine. When you configure the application for the first time, it's recommended that you run at least one test in `spec/models/` and one test in `spec/system/` to check your machine is properly configured to run the tests.

You can use the default admin user from the seeds file:

 **user:** admin@consul.dev
 **pass:** 12345678

But for some actions like voting, you will need a verified user, the seeds file also includes one:

 **user:** verified@consul.dev
 **pass:** 12345678

## Configuration for production environments

See [installer](https://github.com/consuldemocracy/installer)

## Current state

Development started on [2015 July 15th](https://github.com/consuldemocracy/consuldemocracy/commit/8db36308379accd44b5de4f680a54c41a0cc6fc6). Code was deployed to production on 2015 september 7th to [decide.madrid.es](https://decide.madrid.es). Since then new features are added often. You can take a look at the current features at the [project's website](http://consuldemocracy.org/) and future features at the [Roadmap](https://github.com/orgs/consuldemocracy/projects/1) and [open issues list](https://github.com/consuldemocracy/consuldemocracy/issues).

## License

Code published under AFFERO GPL v3 (see [LICENSE-AGPLv3.txt](LICENSE-AGPLv3.txt))

## Contributions

See [CONTRIBUTING.md](CONTRIBUTING.md)
