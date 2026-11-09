# Security Policy

## Supported versions

Only the latest version on the `main` branch is supported.

## Reporting a vulnerability

Please **do not** open a public issue for security problems.

Instead, report it privately through GitHub:
**Security → Report a vulnerability** on this repository.

Please include:
- What the problem is and where it is (file / feature)
- Steps to reproduce it
- What impact you think it has

I'll reply as soon as I can and keep you updated until it's fixed.

## Scope

Seder runs locally on your Mac and makes no network connections.
It moves files only inside `~/Downloads` and `~/Desktop`, never deletes files permanently (only moves them to the Trash), and changes Finder/Dock settings only through the standard `defaults` command.