;; Temporary diagnostic app, not part of the distribution.
;; Calls hx.spawn on testb and confirms the caller keeps running immediately
;; afterward (proving spawn does not block), logging the returned PID/error.

use32

include "HAPP.s"

appHeader headerHAPP HAPP.Architectures.i386, 1, 00, applicationStart, 01h

;;************************************************************************************

include "hexagon.s"
include "log.s"

;;************************************************************************************

applicationStart:

    systemLog testa.starting, 0, Log.Priorities.p4

    mov esi, testa.childName

    hx.syscall hx.spawn

    jc .spawnFailed

    mov dword[testa.spawnedPID], eax

    systemLog testa.spawnOk, 0, Log.Priorities.p4

    jmp .stillAlive

.spawnFailed:

    mov dword[testa.spawnedPID], eax

    systemLog testa.spawnFailed, 0, Log.Priorities.p4

.stillAlive:

    systemLog testa.stillRunning, 0, Log.Priorities.p4

    hx.syscall hx.exit

;;************************************************************************************

testa:

.starting:     db "testa: about to spawn testb", 0
.spawnOk:      db "testa: spawn returned success", 0
.spawnFailed:  db "testa: spawn returned an error", 0
.stillRunning: db "testa: still running right after spawn (proves non-blocking)", 0
.childName:    db "testb", 0
.spawnedPID:   dd 0
