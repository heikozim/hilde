Standard.Tls: a TLS connection to scripts/tls/server.py, which makes its certificate at run time, a line sent and its echo read (001); a certificate the client does not trust, the handshake refused (002); a connection never closed does not compile (003).

004: receive asked for maximum_index bytes gets what the server sent: one receive asks for at most 16 MiB.

005: the server presents a certificate on RSA of 8192 bits, more than the largest key Standard.X509 makes; the client verifies it in the handshake and talks over it, and Standard.X509 reads it.

006: Standard.Tls.connect in a task on one worker, to a listener whose queue is full so that the connect gets no answer: the connect runs off the worker, main runs again within one second, and the task ends with a failed connection once main closes the listener.

007: the server takes the connection and then stays silent: the handshake gets no byte, and Standard.Tls.connect ends in a Left within its ten-second limit while main runs on the same worker.  On a tree without the handshake limit the connect ends only when the server closes, which the test's clock catches.
