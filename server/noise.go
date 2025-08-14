package main
// TODO: Implement Noise IK (app-layer E2EE).
// 1) Generate/load device keys (Ed25519).
// 2) On DataChannel open, run IK handshake and derive session keys.
// 3) Wrap messages in {nonce,ciphertext,tag}. DEV_ALLOW_PLAINTEXT gates plaintext in dev only.
