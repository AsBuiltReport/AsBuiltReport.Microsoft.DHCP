# :arrows_clockwise: Microsoft DHCP As Built Report Changelog

## [0.2.1] - 2025-09-26

### Added

- Improve detection of empty fields in tables
- Improve detection of true/false elements in tables
- Update GitHub release workflow to add post to Bluesky social platform
- Add code to properly display space information

### Changed

- Improve detection of Dhcp Server availability (Test-WSMan)
- Update the Eomm/why-don-t-you-tweet action to v2.0.0
- Update the zentered/bluesky-post-action to v0.3.0
- Update the actions/checkout action to v5
- Deny connection to backup server by Ip Address
- Increase AsBuiltReport.Core modules to v1.4.3
- Updated version number in multiple scripts to 0.2.1.
- Improved formatting and readability in various sections of the code.

## [0.2.0] - 2023-06-24

### Added

- Added support for standalone DHCP servers (Non DC)

### Changed

- Added ServerDiscovery option to enable standalone DHCP server reporting.

## [0.1.1] - 2023-05-23

### Added

- Added Global and Per Scope Policy information.
- Added Global and Per Scope Filter information
- Added Scope Reservation information
- Added Scope Exclusion information
- Added Client Class
  - Vendor
  - User
- Added Scope Option Definition information

### Fixed

- fix [#5](https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.DHCP/issues/5)
- fix [#6](https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.DHCP/issues/6)
- fix [#7](https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.DHCP/issues/7)
- fix [#8](https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.DHCP/issues/8)
- fix [#9](https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.DHCP/issues/9)
- fix [#11](https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.DHCP/issues/11)

## [0.1.0] - 2023-05-19

### Added

- Added Active Directory DHCP summary information.
  - Added DHCP Database information.
  - Added DHCP Dynamic DNS information.
- Added per Domain DHCP IPv4 Scope information.
  - Added DHCP Scope Failover configuration information.
  - Added DHCP Scope Statistics information.
  - Added DHCP Scope Interface Binding information.
  - Added DHCP Scope Delegation configuration information.
- Added per Domain DHCP IPv6 Scope information.
  - Added DHCP Scope Failover configuration information.
  - Added DHCP Scope Statistics information.
  - Added DHCP Scope Interface Binding information.
  - Added DHCP health check.
- Added DHCP IPv4 per Scope Option information.
- Added DHCP IPv6 per Scope Option information.
  - Added DHCP Scope Statistics information.
  - Added DHCP Scope DNS Setting information.

### Changed

- Improved bug and feature request templates
