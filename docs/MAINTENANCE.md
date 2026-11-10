# Maintenance and support

KONAET is an experimental repository automation package. The public Action is
reusable with the maintainer's own GitHub App and `expected-slug`; the MATLAB
activation helper is specifically configured for the `7dsolv` installation.

Supported infrastructure: GitHub.com, Ubuntu 24.04, Bash and GitHub CLI. The
MATLAB validation release is R2026b. Other hosts/runners require their own
validation. For private repositories, map `MLM_LICENSE_TOKEN` to the MATLAB
jobs. MATLAB licensing is separate from this repository's MIT license.

Only the newest minor release receives fixes. Pin an immutable commit or
release and review dependency updates. Run the contract suite and the real
App check separately; fixtures never certify an installed App.

Changes to code and workflows require the owner's review. Required checks
apply before merge; a generated status update has no code owner but still
must pass the checks. No maintainer response-time SLA is currently offered.

Use Issues for reproducible non-sensitive bugs. For vulnerabilities use the
private reporting channel in SECURITY.md. Include version, expected/actual
behavior and a minimal fixture. Never include tokens, private keys or logs
containing credentials. Disable a compromised installation and rotate its
key before resuming publication.

The process helper uses short-lived owner-only temporary files for redirected
stdin/stdout to avoid pipe deadlocks. It removes them on success and failure;
the host account and temporary storage must be trusted. It does not promise
secure erasure of storage after a crash or power loss.
