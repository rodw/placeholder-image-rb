# Security Policy

## Supported Versions

| Version | Supported |
| --- | --- |
| [![Gem Version](https://badge.fury.io/rb/placeholder-image.svg?icon=si%3Arubygems)](https://badge.fury.io/rb/placeholder-image) | Yes |
| Older releases | No |

Currently security fixes are only maintained for the most recent stable release. Please upgrade to the latest version before reporting an issue.

## Reporting a Vulnerability

Please do not open a public GitHub issue for suspected vulnerabilities.

Instead, use GitHub's [private vulnerability reporting for this repository](https://github.com/rodw/placeholder-image-rb/security/advisories/new). (Also reachable via the repository's *Security* tab.)

## Security Posture

Placeholder-Image is designed to be safe to expose on a public endpoint. 

**Bounded work per request.** `image_max_dim_px` and `image_max_total_px` cap the CPU time and memory a single request can consume. Under [the default configuration](#configuration) in the worst case a transient ~16 MB uncompressed buffer is created, consuming under 100 ms of CPU time even on a mid-tier consumer-grade laptop. (These limits may be adjusted downward. Frequently loaded images may be seamlessly cached.)

**Bounded memory overall.**
An optional in-memory cache holds at most `cache_max_entries` compressed images. Under [the default configuration](#configuration) at most ~35 MB is required per middleware instance. (These limits may be adjusted downward; and caching may be fully disabled.)

**Limited input surface.**
Strict pattern matching and bounds checking is applied to all input parameters and HTTP features. No client-supplied text is ever rendered into images.

**No ambient authority.**
Request handling performs no filesystem access, no subprocess execution, and no network calls. Images are generated in pure Ruby with the standard library's zlib. Rack is the only runtime dependency.

**Fail-fast configuration.**
Unrecognized or invalid configuration options colors raise at boot rather than surfacing as per-request errors.

**Hardened container.**
The stand-alone Docker image runs as a non-root user on a slim, version-pinned base with frozen, checksummed gem dependencies.
