# Dev Vault Setup

This is **ONLY** meant for developing/testing Vault integration, and all
secrets will only be stored on memory.

## Download and Install Vault

`brew install vault` will only install the `vault` pre-built binary,
which doesn't include the Vault Web UI.

Alternatively, go to https://www.vaultproject.io/downloads/ and download the latest release for your platform and place it in `/usr/local/bin`

## Start "Dev" Server Mode

```
vault server -dev
```
You will find the 'Unseal Key` and 'Root Token' from the console output, and you
can also browse the web UI via http://127.0.0.1:8200/ui

## References
* https://www.vaultproject.io/docs/concepts/dev-server/
