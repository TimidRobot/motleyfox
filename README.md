# motleyfox

Create discrete Firefox applications to allow clean and complete online
identity separation.

This project is in no way associated with Firefox. Mozilla owns
the trademark for "Firefox":
- Firefox: [The new, fast browser for Mac, PC and Linux |
  Firefox][firefox]
- [List of Mozilla Trademarks][moztm]

[firefox]: https://www.mozilla.org/en-US/firefox/
[moztm]: https://www.mozilla.org/en-US/foundation/trademarks/list/


## Goals

- Complete identity separation
- Avoid using Google Chromei
  - Due the changes in v69 that enabled:
    - Default Chrome Login: [Why I’m done with Chrome – A Few Thoughts on
      Cryptographic Engineering][donechrome]
    - Cooking hoarding: [Christoph Tavan on Twitter: "'Clear all Cookies except
      Google Cookies', thanks Chrome."][cookies]
  - Google's core business plan depends on compromising user privacy
    - [Measuring the Filter Bubble: How Google is influencing what you
      click][bubble]
    - [Privacy concerns regarding Google - Wikipedia][concerns]
- Enjoy capabilities offered by Mozilla Firefox for all online identities
  (Home, Work, etc.):
  - Vertical Tabs: [Tree Style Tab – Add-ons for Firefox][treestyle]
  - Helpful Page Info that provides Title and Address for easy linking to
    references
  - Not controlled by the worlds largest personal data miner
- For use on macOS

[donechrome]:https://blog.cryptographyengineering.com/2018/09/23/why-im-leaving-chrome/
[cookies]:https://twitter.com/ctavan/status/1044282084020441088
[bubble]: https://spreadprivacy.com/google-filter-bubble-study/
[concerns]: https://en.wikipedia.org/wiki/Privacy_concerns_regarding_Google
[treestyle]:https://addons.mozilla.org/en-US/firefox/addon/tree-style-tab/


## What it Does

Run without arguments:
```shell
./motleyfox
```
the script defaults to the equivalent of:
```shell
./motleyfox Home:navy Work:gray
```

For each `NAME` or (`NAME:COLOR`) it is invoked with, it:
1. Creates dedicated profiles, if it does not already exist
1. Creates copies of the Firefox Application
   - Separate applications allow Command+Tab switching
2. Updates the application
   1. Creates a launch script that loads the dedicated profile by default
   2. Updates their icons
      - Different Icons reduces confusion (I also recommend installing distinct
        Themes add-ons)


## Compatibility

The cloned Firefox application bundles contain a modified `Info.plist`. The
following keys are modifed:
- `CFBundleExecutable`
- `CFBundleGetInfoString`
- `CFBundleIdentifier`
- `CFBundleName`

Some plugins are known to rely on these values to function:
- 1Password extension (desktop app required)
  - Workaround: use the [1Password X – Password Manager extension][1pwx]

[1pwx]: https://addons.mozilla.org/en-US/firefox/addon/1password-x-password-manager/


## License

- motleyfox
  - [LICENSE](LICENSE) (Expat License/[MIT License][mit])
- [Firefox, Decorative Outline Icon - Icons8][icons8]
  - [CC BY-ND 3.0][ccbynd]
  - Icon style: Cute Outline, Dotted

[mit]:http://www.opensource.org/licenses/MIT
[icons8]:https://icons8.com/icon/set/firefox/wired
[ccbynd]:https://creativecommons.org/licenses/by-nd/3.0/
