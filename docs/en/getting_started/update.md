# Keeping your fork updated

## Preliminary steps

### Running your test suite

Before upgrading to a newer version of Consul Democracy, make sure you've [configured your fork](configuration.md) to run the tests, and that all the tests in your test suite pass. If you omit this step, it'll be much harder to upgrade since it'll be very tricky to know whether some features are broken after the upgrade.

Please take as much time as necessary for this; every hour you spend making sure your test suite is in good shape will save countless hours of fixing bugs that made it to production.

### Configuring your git remotes

If you created your fork following the instructions in the [Create your fork](create.md) section and cloned it locally, run:

```bash
git remote -v
```

You should get something like:

> origin  git@github.com:your_user_name/consuldemocracy.git (fetch)\
> origin  git@github.com:your_user_name/consuldemocracy.git (push)

Now, add Consul Democracy's github as upstream remote with:

```bash
git remote add upstream git@github.com:consuldemocracy/consuldemocracy.git
```

Check it's been correctly configured by once again running:

```bash
git remote -v
```

This time you should get something like:

> origin  git@github.com:your_user_name/consuldemocracy.git (fetch)\
> origin  git@github.com:your_user_name/consuldemocracy.git (push)\
> upstream  git@github.com:consuldemocracy/consuldemocracy.git (fetch)\
> upstream  git@github.com:consuldemocracy/consuldemocracy.git (push)

## Pulling changes from Consul Democracy

When upgrading Consul Democracy, **it is extremely important that you upgrade one version at a time**. Some versions require running certain tasks that modify existing content in the database in order to make it compatible with future versions. Upgrading two versions at the same time could result in irreversible data loss.

When we say "one version at a time", we're excluding patch versions. For example, if you're currently using version 1.2.0 and you'd like to upgrade to version 2.2.2, first upgrade to version 1.3.1, then to 1.4.1, then to 1.5.0, then to 2.0.1, then to 2.1.1 and then to version 2.2.2. That is, always upgrade to the latest patch version of a certain major/minor version.

When upgrading to a newer version, make sure you read the [release notes](https://github.com/consuldemocracy/consuldemocracy/releases) of that version **before** upgrading.

To upgrade, start by creating a branch named `release` from your `master` branch to apply Consul Democracy changes:

```bash
git checkout master
git pull
git checkout -b release
git fetch upstream tag <version_tag_you_are_upgrading_to>
```

Now you're ready to merge the changes in the new version.

## Merging changes

Run:

```bash
git merge  <version_tag_you_are_upgrading_to>
```

After running this command, there are two possible outcomes:

A. You get a screen on your git configured editor showing the commit message `Merge tag '<version_tag_you_are_upgrading_to>' into release`. That means git was able to grab latest changes from Consul Democracy's master branch, and it can merge them without code change conflicts. Finish the commit.

B. You get some git errors along with a `Automatic merge failed; fix conflicts and then commit the result` message. That means there are conflicts between your custom code changes and the changes in the new version of Consul Democracy. That's the main reason we strongly recommend [using custom folders and files for your custom changes](../customization/introduction.md); the more you use custom folders and files, the less conflicts you will get. Resolve the merge conflicts carefully and commit them, making sure you document how you solved the conflicts (for example, in the commit message).

## Making sure everything works

Now we recommend you to push your `release` branch to GitHub (or GitLab, if that's what you usually use) and create a Pull Request so you can check whether your test suite reports any issues.

It's possible that the test suite does indeed report some issues because your custom code might not correctly work with the newer version of Consul Democracy. It is **essential** that you fix all these issues before continuing.

Finally, you might want to manually check your custom code. For example, if you've [customized components](../customization/components.md) or [views](../customization/views.md), check whether the original ERB files have changed and whether you should update your custom files in order to include those changes.

## Finishing the process

After making sure everything works as expected, you can either merge the pull request on GitHub/GitLab or finish the process manually:

```bash
git checkout master
git merge release
git branch -d release
git push
```

Finally, read the release notes once again to make sure everything is under control, deploy to production, execute `bin/rake consul:execute_release_tasks RAILS_ENV=production` on the production server, and check everything is working properly.

Congratulations! You've upgraded to a more recent version of Consul Democracy. Your version of Consul Democracy is now less likely to have security vulnerabilities or become an impossible-to-maintain abandonware. Not only that, but this experience will make it easier for you to upgrade to a new version in the future.

We'd love to hear from your experience! You can use the [discussions about releases](https://github.com/consuldemocracy/consuldemocracy/discussions/categories/releases) for that (note that there are no discussions for versions prior to 2.2.0; if you've upgraded to an earlier version, please open a new discussion). This way, we'll manage to make it easier for you and everyone else to upgrade Consul Democracy next time.
