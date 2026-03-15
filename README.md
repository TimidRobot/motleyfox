# motleyfox

Create discrete Firefox applications to allow clean and complete online
identity separation with clear app switching.

> [!NOTE]
> This project is in no way associated with Firefox. Mozilla owns the trademark
> for "Firefox":
> - Firefox: [The new, fast browser for Mac, PC and Linux |
>   Firefox][firefox]
> - [List of Mozilla Trademarks][moztm]

[firefox]: https://www.mozilla.org/en-US/firefox/
[moztm]: https://www.mozilla.org/en-US/foundation/trademarks/list/


## Goals

- Complete identity separation
- Enjoy Mozilla Firefox
  - Vertical Tabs
    - [GitHub - mbnuqw/sidebery][sidebery]: _Firefox extension for managing
      tabs and bookmarks in sidebar. · GitHub_
  - Helpful Page Info that provides Title and Address for easy linking to
    references
  - Not controlled by the worlds largest personal data miner
- Avoid using Google Chrome
  - Due the changes in v69 that enabled:
    - Default Chrome Login: [Why I’m done with Chrome – A Few Thoughts on
      Cryptographic Engineering][donechrome]
    - Cooking hoarding: [Christoph Tavan on Twitter: "'Clear all Cookies except
      Google Cookies', thanks Chrome."][cookies]
  - Google's core business plan depends on compromising user privacy
    - [Measuring the Filter Bubble: How Google is influencing what you
      click][bubble]
    - [Privacy concerns regarding Google - Wikipedia][concerns]
- For use on macOS

[sidebery]: https://github.com/mbnuqw/sidebery
[donechrome]:https://blog.cryptographyengineering.com/2018/09/23/why-im-leaving-chrome/
[cookies]:https://twitter.com/ctavan/status/1044282084020441088
[bubble]: https://spreadprivacy.com/google-filter-bubble-study/
[concerns]: https://en.wikipedia.org/wiki/Privacy_concerns_regarding_Google


## What it Does

Run without arguments:
```shell
./motleyfox.sh
```
the script defaults to the equivalent of:
```shell
./motleyfox.sh Home:navy Work:gray
```

For each `NAME` or (`NAME:COLOR`) it is invoked with, it:
1. Creates a copy of the Firefox Application
   - (a separate application allow Command+Tab switching)
2. Updates the application
   1. Creates a launch script that loads the dedicated profile by default
   2. Updates the application icon
      - A different Icon reduces confusion (I also recommend installing
        distinct Themes add-on)
3. Creates a dedicated profile, if one does't already exist


## Requirements

- Execution
  - [GitHub - mklement0/fileicon][fileicon]: _macOS CLI for managing custom
    icons for files and folders · GitHub_
    - (`motleyfox.sh` will still complete successfully even if it can't update
      the application icon)
- Development
  - [ShellCheck – shell script analysis tool][shellcheck]
    - [GitHub - koalaman/shellcheck][shellcheck-gh]: _ShellCheck, a static
      analysis tool for shell scripts · GitHub_

[fileicon]: https://github.com/mklement0/fileicon/tree/master
[shellcheck]: https://www.shellcheck.net/
[shellcheck-gh]: https://github.com/koalaman/shellcheck


## Compatibility

The cloned Firefox application bundles contain a modified `Info.plist`. The
following keys are impacted
- `CFBundleExecutable` modified
- `CFBundleIdentifier` modified
- `CFBundleName` modified
- `SMPrivilegedExecutables` deleted


## License

- motleyfox.sh
  - [LICENSE](LICENSE) (Expat License/[MIT License][mit])
- [Firefox, Decorative Outline Icon - Icons8][icons8]
  - [CC BY-ND 3.0][ccbynd]
  - Icon style: Cute Outline, Dotted

[mit]:http://www.opensource.org/licenses/MIT
[icons8]:https://icons8.com/icon/set/firefox/wired
[ccbynd]:https://creativecommons.org/licenses/by-nd/3.0/
