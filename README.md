# motleyfox

Create discrete Firefox applications to allow clean and complete online
identity separation.

## Goals

- Complete identity separation
- Avoid using Google Chrome due the changes in v69 that enabled:
  - Default Chrome Login: [Why I’m done with Chrome – A Few Thoughts on
    Cryptographic Engineering][1]
  - Cooking hoarding: [Christoph Tavan on Twitter: ""Clear all Cookies except
    Google Cookies", thanks Chrome. /cc @matthew_d_green… "][2]
- Enjoy capabilities offered by Mozilla Firefox for all online identities
  (Home, Work, etc.):
  - Vertical Tabs: [Tree Style Tab – Add-ons for Firefox][3]
  - Helpful Page Info that provides Title and Address for easy linking to
    references
  - Not controlled by the worlds largest personal data miner
- For use on macOS

[1]:https://blog.cryptographyengineering.com/2018/09/23/why-im-leaving-chrome/
[2]:https://twitter.com/ctavan/status/1044282084020441088
[3]:https://addons.mozilla.org/en-US/firefox/addon/tree-style-tab/

## Status

This is a work in progress. It is currently functional, but needs:

- Additional troubleshooting over extension add-on compatibility
- Example/default icons

## What it Does

1. Creates Home and Work copies of the Firefox Application
   - Separate applications allow Command+Tab switching
2. Updates their icons
   - Different Icons reduces confusion (I also recommend installing distinct
     Themes add-ons)
3. Creates dedicated profiles, if they do not already exist
4. Creates launch scripts

## License

- [LICENSE](LICENSE) (Expat License/[MIT License][4])

[4]:(http://www.opensource.org/licenses/MIT)
