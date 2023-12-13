# Adding Software To Homebrew

Is your favourite software missing from Homebrew? Then you're the perfect person to resolve this problem.

If you want to add software that is either closed source or a GUI-only program, you will want to follow the guide for [Casks](#casks). Otherwise follow the guide for [Formulae](#formulae) (see also: [Homebrew Terminology](Formula-Cookbook.md#homebrew-terminology)).

Before you start, please check the open pull requests for [Homebrew/homebrew-core](https://github.com/Homebrew/homebrew-core/pulls) or [Homebrew/homebrew-cask](https://github.com/Homebrew/homebrew-cask/pulls) to make sure no one else beat you to the punch.

Next, you will want to go through the [Acceptable Formulae](Acceptable-Formulae.md) or [Acceptable Casks](Acceptable-Casks.md) documentation to determine if the software is an appropriate addition to Homebrew. If you are creating a formula for an alternative version of software already in Homebrew (e.g. a major/minor version that differs significantly from the existing version), be sure to read the [Versions](Versions.md) documentation to understand versioned formulae requirements.

If everything checks out, you're ready to get started on a new formula / cask!

**Note:** For updating the version of an existing formula or cask, refer to the [Updating Software in Homebrew](Updating-Software-in-Homebrew.md) guidelines, as well as 'submitting a new version of a [formula](How-To-Open-a-Homebrew-Pull-Request.md#submit-a-new-version-of-an-existing-formula) / [cask](How-To-Open-a-Homebrew-Pull-Request.md#submit-a-new-version-of-an-existing-cask)' in 'How To Open A Homebrew Pull Request'.

## Formulae

**Note:** Before taking the time to craft a new formula:

* make sure it can be accepted by checking [Acceptable Formulae](Acceptable-Formulae.md).
* check that the formula was not [already refused](https://github.com/Homebrew/homebrew-core/search?q=is%3Aclosed&type=Issues).
* if you are just updating the version of an existing formula, see the streamlined method in ['submit a new version of an existing formula'](How-To-Open-a-Homebrew-Pull-Request.md#submit-a-new-version-of-an-existing-formula).

### Writing the formula

Making a new formula is easy, and the [Formula Cookbook](Formula-Cookbook.md) is an essential resource to guide you through the process. The Cookbook provides detailed instructions, best practices, and solutions to common problems you may encounter when creating a formula. Familiarizing yourself with its contents before you start is advisable.

1. Begin by researching existing formulae in Homebrew that are similar to the software you plan to add. This will help you grasp how specific languages, build methods, and other typical conventions are handled in formulae. Start by setting `HOMEBREW_NO_INSTALL_FROM_API=1` in your shell environment. Then, run `brew tap homebrew/core` to clone the `homebrew/core` tap to the directory indicated by `brew --repository homebrew/core`.

1. If you're starting from scratch, you can use the [`brew create` command](Manpage.md#create-options-url) to produce a basic version of your formula. This command accepts a number of options and you may be able to save yourself some work by using an appropriate template option like `--python` / `--go`.

1. You will now have to develop the boilerplate code from `brew create` into a complete formula. Your main references will be the [Formula Cookbook](Formula-Cookbook.md), similar existing formulae, and the official documentation of the software you're packaging. Be sure to also take note of the Homebrew documentation for writing [Python](Python-for-Formula-Authors.md) and [Node](Node-for-Formula-Authors.md) formulae, if applicable.

1. Make sure you write a good test as part of your formula. Refer to the [Add a test to the formula](Formula-Cookbook.md#add-a-test-to-the-formula) section of the Formula Cookbook for help with this.

If you're stuck, ask for help on GitHub or the [Homebrew discussion forum](https://github.com/orgs/Homebrew/discussions). The maintainers are very happy to help but we also like to see that you've put effort into trying to find a solution first.

### Testing and auditing the formula

1. Test your formula installation using `brew install --formula --build-from-source $(brew --repository homebrew/core)/Formula/<prefix>/<formula>.rb`, where `<prefix>` is the first letter of your formula's name and `<formula>` is the name of your formula. Correct any errors that occur and repeat the installation until it completes without errors.

1. Additionally, verify the proper uninstallation of the formula by using the command `brew uninstall --formula <formula>`, ensuring it removes the software without issues.

1. Run `brew audit --formula --new <formula>` with your formula. If any errors occur, correct your formula and run the audit again. The audit should finish without any errors by the end of this step.

1. Run `brew style --formula --fix <formula>` to automatically check and correct your formula's conformity to Homebrew's style guidelines.

1. Run your formula's test using `brew test <formula>`. The test should finish without any errors.

Keep in mind that these checks will happen automatically when you submit your pull request. Completing them beforehand not only saves time but also makes the whole process smoother for everyone.

If your application and Homebrew do not work well together, feel free to [file an issue](https://github.com/Homebrew/homebrew-core/issues/new/choose) after checking out open issues.

### Submitting the formula

You're now ready to contribute your formula to the [homebrew-core](https://github.com/Homebrew/homebrew-core) repository. If this is your first time making a submission, consult the [How to Open a Homebrew Pull Request](How-To-Open-a-Homebrew-Pull-Request.md#formulae-related-pull-request) guide for detailed instructions. Your pull request will be reviewed by the maintainers, who may suggest improvements or changes before your formula can be added to Homebrew.

If you've made it this far, congratulations on successfully submitting a Homebrew formula! Your dedication and hard work are highly valued. Take satisfaction in knowing that your contribution provides a valuable addition that will benefit many Homebrew users.

## Casks

**Note:** Before taking the time to craft a new cask:

* make sure it can be accepted by checking [Acceptable Casks](Acceptable-Casks.md).
* check that the cask was not [already refused](https://github.com/Homebrew/homebrew-cask/search?q=is%3Aclosed&type=Issues).
* if you are just updating the version of an existing cask, see the streamlined method in ['submit a new version of an existing cask'](How-To-Open-a-Homebrew-Pull-Request.md#submit-a-new-version-of-an-existing-cask).

### Writing the cask

Making a new cask is easy, and the [Cask Cookbook](Cask-Cookbook.md) is an essential resource to guide you through the process. The Cookbook provides detailed instructions, best practices, and solutions to common problems you may encounter when creating a cask. Familiarizing yourself with its contents before you start is advisable.

1. Begin by researching existing casks in Homebrew that are similar to the software you plan to add. This will help you understand the typical structure and conventions used in casks. Start by tapping `homebrew/cask`: run `brew tap homebrew/cask` to clone the `homebrew/cask` tap to the path returned by `brew --repository homebrew/cask`.

1. If you're starting from scratch, you can use the [`brew create --cask <download-url>` command](Manpage.md#create-options-url) to produce a basic version of your cask.

  After executing the `create` command, `EDITOR` will open with a cask template at `$(brew --repository homebrew/cask)/Casks/<prefix>/<cask>.rb` (where `<prefix>` is the first letter of your cask's name and `<cask>` is the name of your cask). The template will appear as follows:

  ```ruby
  cask "my-new-cask" do
    version ""
    sha256 ""
  
    url "download-url"
    name ""
    desc ""
    homepage ""
  
    app ""
  end
  ```

1. You will now have to develop the boilerplate code from `brew create --cask` into a complete cask. Your main references will be the [Cask Cookbook](Cask-Cookbook.md), similar existing casks, and the official documentation of the software you're packaging.

   For further specifics and additional insights, refer to ['Additional Cask Details and Examples'](#additional-cask-details-and-examples).

1. It's important to include a good test in your cask. Since the Cask Cookbook doesn't provide specific guidance on this, you can refer to the [Add a test to the formula](Formula-Cookbook.md#add-a-test-to-the-formula) section in the Formula Cookbook for assistance.

### Testing and auditing the Cask

1. Test your cask installation using `brew install --cask $(brew --repository homebrew/cask)/Casks/<prefix>/<cask>.rb`, where `<prefix>` is the first letter of your cask's name and `<cask>` is the name of your cask. Correct any errors that occur and repeat the installation until it completes without errors.

1. Additionally, verify the proper uninstallation of the cask by using the command `brew uninstall --cask <cask>`, ensuring it removes the software without issues.

1. Run `brew audit --cask --new <cask>` with your cask. If any errors occur, correct your cask and run the audit again. The audit should finish without any errors by the end of this step.

1. Run `brew style --cask --fix <cask>` to automatically check and correct your cask's conformity to Homebrew's style guidelines.

1. Run your cask's test using `brew test <cask>`. The test should finish without any errors.

Keep in mind that these checks will happen automatically when you submit your pull request. Completing them beforehand not only saves time but also makes the whole process smoother for everyone.

If your application and Homebrew Cask do not work well together, feel free to [file an issue](https://github.com/Homebrew/homebrew-cask#reporting-bugs) after checking out open issues.

### Submitting the Cask

You're now ready to contribute your cask to the [homebrew-cask](https://github.com/Homebrew/homebrew-cask) repository. If this is your first time making a submission, consult the [How to Open a Homebrew Pull Request](How-To-Open-a-Homebrew-Pull-Request.md#cask-related-pull-request) guide for detailed instructions. Your pull request will be reviewed by the maintainers, who may suggest improvements or changes before your cask can be added to Homebrew.

If you've made it this far, congratulations on successfully submitting a Homebrew cask! Your dedication and hard work are highly valued. Take satisfaction in knowing that your contribution provides a valuable addition that will benefit many Homebrew users.

#### Commit Messages for Homebrew Cask

In the [homebrew-cask](https://github.com/Homebrew/homebrew-cask) repository, commit messages have a specific format that helps in quickly understanding and managing changes across numerous applications. When crafting a commit message, ensure it includes:

* The application name,
* The version number, if applicable,
* The specific purpose or nature of the changes.

This format is tailored to the unique needs of the [homebrew-cask](https://github.com/Homebrew/homebrew-cask) repository and might differ from standard practices in other projects, including [homebrew-core](https://github.com/Homebrew/homebrew-core). By adhering to this style, you contribute to the project's clarity and efficiency.

Examples of clear and effective Homebrew Cask commit summaries:

* `Add Transmission.app v1.0`
* `Upgrade Transmission.app to v2.82`
* `Fix checksum in Transmission.app cask`
* `Add CodeBox Latest`

Examples to avoid due to their ambiguity or lack of specific details:

* `Upgrade to v2.82`
* `Checksum was bad`

Remember, the first line of your commit message serves as the title of a GitHub pull request and is crucial for a quick and effective review process. For a more comprehensive understanding of crafting effective commit messages, see [A Note About Git Commit Messages](https://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html).

### Additional Cask Details and Examples

#### Examples

Here’s a cask for `shuttle` as an example. Note the `verified` parameter below the `url`, which is needed when [the url and homepage hostnames differ](Cask-Cookbook.md#when-url-and-homepage-domains-differ-add-verified).

```ruby
cask "shuttle" do
  version "1.2.9"
  sha256 "0b80bf62922291da391098f979683e69cc7b65c4bdb986a431e3f1d9175fba20"

  url "https://github.com/fitztrev/shuttle/releases/download/v#{version}/Shuttle.zip",
      verified: "github.com/fitztrev/shuttle/"
  name "Shuttle"
  desc "Simple shortcut menu"
  homepage "https://fitztrev.github.io/shuttle/"

  app "Shuttle.app"

  zap trash: "~/.shuttle.json"
end
```

And here is one for `noisy`. Note that it has an unversioned download (the download `url` does not contain the version number, unlike the example above). It also suppresses the checksum with `sha256 :no_check`, which is necessary because since the download `url` does not contain the version number, its checksum will change when a new version is made available.

```ruby
cask "noisy" do
  version "1.3"
  sha256 :no_check

  url "https://github.com/downloads/jonshea/Noisy/Noisy.zip"
  name "Noisy"
  desc "White noise generator"
  homepage "https://github.com/jonshea/Noisy"

  app "Noisy.app"

  zap trash: "~/Library/Preferences/com.rathertremendous.noisy.plist"
end
```

Here is a last example for `airdisplay`, which uses a `pkg` installer to install the application instead of a stand-alone application bundle (`.app`). Note the [`uninstall pkgutil` stanza](Cask-Cookbook.md#uninstall-pkgutil), which is needed to uninstall all files that were installed using the installer.

You will also see how to adapt `version` to the download `url`. Use [our custom `version` methods](Cask-Cookbook.md#version-methods) to do so, resorting to the standard [Ruby String methods](https://ruby-doc.org/core/String.html) when they don’t suffice.

```ruby
cask "airdisplay" do
  version "3.4.2"
  sha256 "272d14f33b3a4a16e5e0e1ebb2d519db4e0e3da17f95f77c91455b354bee7ee7"

  url "https://www.avatron.com/updates/software/airdisplay/ad#{version.no_dots}.zip"
  name "Air Display"
  desc "Utility for using a tablet as a second monitor"
  homepage "https://avatron.com/applications/air-display/"

  livecheck do
    url "https://www.avatron.com/updates/software/airdisplay/appcast.xml"
    strategy :sparkle, &:short_version
  end

  depends_on macos: ">= :mojave"

  pkg "Air Display Installer.pkg"

  uninstall pkgutil: [
    "com.avatron.pkg.AirDisplay",
    "com.avatron.pkg.AirDisplayHost2",
  ]
end
```

#### Cask stanzas

Fill in the following stanzas for your cask:

| name               | value       |
| ------------------ | ----------- |
| `version`          | application version |
| `sha256`           | SHA-256 checksum of the file downloaded from `url`, calculated by the command `shasum -a 256 <file>`. Can be suppressed by using the special value `:no_check`. (see [`sha256` Stanza Details](Cask-Cookbook.md#stanza-sha256)) |
| `url`              | URL to the `.dmg`/`.zip`/`.tgz`/`.tbz2` file that contains the application.<br />A [`verified` parameter](Cask-Cookbook.md#when-url-and-homepage-domains-differ-add-verified) must be added if the hostnames in the `url` and `homepage` stanzas differ. [Block syntax](Cask-Cookbook.md#using-a-block-to-defer-code-execution) is available for URLs that change on every visit. |
| `name`             | the full and proper name defined by the vendor, and any useful alternate names (see [`name` Stanza Details](Cask-Cookbook.md#stanza-name)) |
| `desc`             | one-line description of the software (see [`desc` Stanza Details](Cask-Cookbook.md#stanza-desc)) |
| `homepage`         | application homepage; used for the `brew home` command |
| `app`              | relative path to an `.app` bundle that should be moved into the `/Applications` folder on installation (see [`app` Stanza Details](Cask-Cookbook.md#stanza-app)) |

Other commonly used stanzas are:

| name               | value       |
| ------------------ | ----------- |
| `livecheck`        | Ruby block describing how to find updates for this cask (see [`livecheck` Stanza Details](Cask-Cookbook.md#stanza-livecheck)) |
| `pkg`              | relative path to a `.pkg` file containing the distribution (see [`pkg` Stanza Details](Cask-Cookbook.md#stanza-pkg)) |
| `caveats`          | string or Ruby block providing the user with cask-specific information at install time (see [`caveats` Stanza Details](Cask-Cookbook.md#stanza-caveats)) |
| `uninstall`        | procedures to uninstall a cask; optional unless the `pkg` stanza is used (see [`uninstall` Stanza Details](Cask-Cookbook.md#stanza-uninstall)) |
| `zap`              | additional procedures for a more complete uninstall, including configuration files and shared resources (see [`zap` Stanza Details](Cask-Cookbook.md#stanza-zap)) |

Additional [`artifact` stanzas](Cask-Cookbook.md#at-least-one-artifact-stanza-is-also-required) may be needed for special use cases. Even more special-use stanzas are listed at [Optional Stanzas](Cask-Cookbook.md#optional-stanzas).

#### Generating a token for the cask

The cask **token** is the mnemonic string people will use to interact with the cask via `brew install`, etc. The name of the cask **file** is simply the token with the extension `.rb` appended.

The easiest way to generate a token for a cask is to run `generate_cask_token`:

```bash
$(brew --repository homebrew/cask)/developer/bin/generate_cask_token "/full/path/to/new/software.app"
```

If the software you wish to create a cask for is not installed, or does not have an associated App bundle, just give the full proper name of the software instead of a pathname:

```bash
$(brew --repository homebrew/cask)/developer/bin/generate_cask_token "Google Chrome"
```

If the `generate_cask_token` script does not work for you, see [Cask Token Details](#cask-token-details).

#### Cask token details

If a token conflicts with an already-existing cask, authors should manually make the new token unique by prepending the vendor name. Example: [unison.rb](https://github.com/Homebrew/homebrew-cask/blob/HEAD/Casks/u/unison.rb) and [panic-unison.rb](https://github.com/Homebrew/homebrew-cask/blob/HEAD/Casks/p/panic-unison.rb).

If possible, avoid creating tokens that differ only by the placement of hyphens.

To generate a token manually, or to learn about exceptions for unusual cases, see the [Token Reference](Cask-Cookbook.md#token-reference).

#### Archives with subfolders

When a downloaded archive expands to a subfolder, the subfolder name must be included in the `app` value.

Example:

1. Simple Floating Clock is downloaded to the file `sfc.zip`.
1. `sfc.zip` unzips to a folder called `Simple Floating Clock`.
1. The folder `Simple Floating Clock` contains the application `SimpleFloatingClock.app`.
1. So, the `app` stanza should include the subfolder as a relative path:

   ```ruby
   app "Simple Floating Clock/SimpleFloatingClock.app"
   ```
