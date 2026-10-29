# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# SPDX-FileCopyrightText: 2026 Heiko Zimmermann
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

STDLIB := \
		../../standard/src/Buffer.hih,../../standard/src/Buffer.hiq \
		../../standard/src/String.hih,../../standard/src/String.hiq \
		../../standard/src/StringBuilder.hih,../../standard/src/StringBuilder.hiq \
		../../standard/src/Text.hih,../../standard/src/Text.hiq \
		../../standard/src/Utf8.hih,../../standard/src/Utf8.hiq \
		../../standard/src/Order.hih,../../standard/src/Order.hiq \
		../../standard/src/Sort.hih,../../standard/src/Sort.hiq \
		../../standard/src/Ip.hih,../../standard/src/Ip.hiq \
		../../standard/src/Bindings/Resolve.hih,../../standard/src/Bindings/Resolve.hiq \
		../../standard/src/Resolve.hih,../../standard/src/Resolve.hiq \
		../../standard/src/Bindings/Time.hih,../../standard/src/Bindings/Time.hiq \
		../../standard/src/Time.hih,../../standard/src/Time.hiq \
		../../standard/src/Http.hih,../../standard/src/Http.hiq \
		../../standard/src/Bindings/File.hih,../../standard/src/Bindings/File.hiq \
		../../standard/src/File.hih,../../standard/src/File.hiq \
		../../bindings/generated/Tls.hih,../../bindings/generated/Tls.hiq \
		../../standard/src/Bindings/Tls.hih,../../standard/src/Bindings/Tls.hiq \
		../../standard/src/Tls.hih,../../standard/src/Tls.hiq \
		../../standard/src/HttpClient.hih,../../standard/src/HttpClient.hiq \
		../../standard/src/Base64.hih,../../standard/src/Base64.hiq \
		../../bindings/generated/Libcrypto.hih,../../bindings/generated/Libcrypto.hiq \
		../../standard/src/Bindings/Libcrypto.hih,../../standard/src/Bindings/Libcrypto.hiq \
		../../standard/src/Libcrypto.hih,../../standard/src/Libcrypto.hiq \
		../../standard/src/Bindings/Serial.hih,../../standard/src/Bindings/Serial.hiq \
		../../standard/src/Json.hih,../../standard/src/Json.hiq \
		../../standard/src/Bindings/X509.hih,../../standard/src/Bindings/X509.hiq \
		../../standard/src/Bindings/MlDsa.hih,../../standard/src/Bindings/MlDsa.hiq \
		../../standard/src/MlDsa.hih,../../standard/src/MlDsa.hiq \
		../../standard/src/X509.hih,../../standard/src/X509.hiq \
		../../standard/src/Acme.hih,../../standard/src/Acme.hiq \

PROG := LearnPki

ENTRY := Example.$(PROG):main

SRC := \
	$(PROG).hih,$(PROG).hiq

.DEFAULT: all
all:
	../../hilde compile $(STDLIB) $(SRC) --entrypoint=$(ENTRY) --output=main

# The same programmes as C, for the warning count and the memory runs.
.PHONY: c
c:
	../../hilde compile $(STDLIB) $(SRC) --entrypoint=$(ENTRY) --target-type=c --output=main.c

.PHONY: clean
clean:
	rm -f main main.c
