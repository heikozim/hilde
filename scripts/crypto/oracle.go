// The oracle for the tests of Standard.Libcrypto: Go's standard
// library -- an implementation that shares nothing with OpenSSL -- on the
// inputs of the seal test, printed in the lines that test prints.
//
//	go run scripts/crypto/oracle.go
//
// ChaCha20-Poly1305 is not here: Go keeps it out of its public library.
// scripts/crypto/chacha.py has it.
package main

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/ecdh"
	"crypto/ed25519"
	"encoding/hex"
	"fmt"
)

// The bytes start, start+1, ... -- n of them.
func sequence(start, n int) []byte {
	b := make([]byte, n)
	for i := range b {
		b[i] = byte(start + i)
	}
	return b
}

// 100 bytes that are not a sequence.
func long() []byte {
	b := make([]byte, 100)
	for i := range b {
		b[i] = byte((i*13 + 5) % 256)
	}
	return b
}

func main() {
	key := sequence(0, 32)
	other := sequence(32, 32)
	nonce := sequence(0, 12)
	aad := []byte("header")
	block, err := aes.NewCipher(key)
	if err != nil {
		panic(err)
	}
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		panic(err)
	}
	inputs := []struct {
		name string
		data []byte
	}{{"empty", nil}, {"short", []byte("attack at dawn")}, {"long", long()}}
	for _, in := range inputs {
		fmt.Printf("aes-256-gcm %s %s\n", in.name, hex.EncodeToString(gcm.Seal(nil, nonce, in.data, aad)))
	}
	a, err := ecdh.X25519().NewPrivateKey(key)
	if err != nil {
		panic(err)
	}
	b, err := ecdh.X25519().NewPrivateKey(other)
	if err != nil {
		panic(err)
	}
	ab, err := a.ECDH(b.PublicKey())
	if err != nil {
		panic(err)
	}
	fmt.Printf("x25519 public-a %s\n", hex.EncodeToString(a.PublicKey().Bytes()))
	fmt.Printf("x25519 public-b %s\n", hex.EncodeToString(b.PublicKey().Bytes()))
	fmt.Printf("x25519 shared %s\n", hex.EncodeToString(ab))
	signer := ed25519.NewKeyFromSeed(key)
	public := signer.Public().(ed25519.PublicKey)
	fmt.Printf("ed25519 public %s\n", hex.EncodeToString(public))
	fmt.Printf("ed25519 signature %s\n", hex.EncodeToString(ed25519.Sign(signer, []byte("attack at dawn"))))
}
