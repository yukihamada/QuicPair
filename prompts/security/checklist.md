# Security Checklist (must be all YES)

- [ ] Noise IK is executed after DataChannel open; no plaintext without DEV flag
- [ ] Keys reside in iOS Secure Enclave/Keychain and macOS Keychain
- [ ] Strict Local Mode blocks outbound sockets/DNS
- [ ] Logs contain no payloads (only meta)
- [ ] TURN traffic is E2E (app-layer) encrypted
