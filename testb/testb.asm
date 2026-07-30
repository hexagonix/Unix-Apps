;; Temporary diagnostic app, not part of the distribution.
;; Minimal child process: prints a message and exits immediately.
;; Used together with testa to isolate the process allocator's malloc/free
;; cycle from the complexity of the real login/logind/sh chain.

use32

include "HAPP.s"

appHeader headerHAPP HAPP.Architectures.i386, 1, 00, applicationStart, 01h

;;************************************************************************************

include "hexagon.s"
include "log.s"

;;************************************************************************************

applicationStart:

    systemLog testb.running, 0, Log.Priorities.p4

    hx.syscall hx.exit

;;************************************************************************************

testb:

.running: db "testb: running", 0
