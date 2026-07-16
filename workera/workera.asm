;; Temporary diagnostic app - not part of the distribution.
;; Loops forever, logging a tick and sleeping briefly - used together with
;; workerb and launcher to prove the round-robin scheduler actually
;; interleaves independent spawned processes.

use32

include "HAPP.s"

appHeader headerHAPP HAPP.Architectures.i386, 1, 00, applicationStart, 01h

;;************************************************************************************

include "hexagon.s"
include "log.s"

;;************************************************************************************

applicationStart:

.loop:

    systemLog workera.tick, 0, Log.Priorities.p4

    mov ecx, 3000000

.spin:

    dec ecx

    jnz .spin

    jmp .loop

;;************************************************************************************

workera:

.tick: db "workerA: tick", 0
