# Change Log
All notable changes to this project will be documented in this file.
 
The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased] - yyyy-mm-dd

## [1.5.1] - 2026-09-25

### Improvements

- Prevent shell commands passed through logfile path.

## [1.5.0] - 2026-06-01

### Added
- Linux arm64 support — downloads `BrowserStackLocal-linux-arm64` on aarch64/arm64 hosts.
- Dynamic binary source URL via `POST local.browserstack.com/binary/api/v1/endpoint`. Primary downloads now come from CloudFront; CloudFlare is used as fallback after repeated failures.
- Proxy passthrough for binary download — `proxyHost` and `proxyPort` passed to `Local#start` are now also used when downloading the binary itself.
- `User-Agent: browserstack-local-ruby/<version>` header on the endpoint POST and on the binary download GET.

### Changed
- TLS certificate verification is now enforced (`OpenSSL::SSL::VERIFY_PEER`) on all binary-download HTTPS traffic. Previous releases used `VERIFY_NONE`. If you were relying on disabled verification (e.g., behind a MITM proxy without the corporate CA installed in your system trust store), pin to 1.4.3 and open an issue.

## [1.4.3] - 2023-08-24

### Changed
Ruby 3 exists? deprecation fix
