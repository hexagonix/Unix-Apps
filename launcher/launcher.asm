;; Temporary diagnostic app - not part of the distribution.
;; Spawns workera and workerb (non-blocking) and then loops printing its own
;; tick too, so the log shows three independent contexts (this process plus
;; the two spawned workers) interleaved by the round-robin scheduler.

use32

include "HAPP.s"

appHeader headerHAPP HAPP.Architectures.i386, 1, 00, applicationStart, 01h

;;************************************************************************************

include "hexagon.s"
include "log.s"

;;************************************************************************************

applicationStart:

    systemLog launcher.starting, 0, Log.Priorities.p4

    mov esi, launcher.workerAName

    hx.syscall hx.spawn

    jc .spawnAFailed

    mov esi, launcher.workerBName

    hx.syscall hx.spawn

    jc .spawnBFailed

    systemLog launcher.bothSpawned, 0, Log.Priorities.p4

    jmp .loop

.spawnAFailed:

    systemLog launcher.spawnAFailed, 0, Log.Priorities.p4

    jmp .loop

.spawnBFailed:

    systemLog launcher.spawnBFailed, 0, Log.Priorities.p4

.loop:

    systemLog launcher.tick, 0, Log.Priorities.p4

    mov ecx, 3000000

.spin:

    dec ecx

    jnz .spin

    jmp .loop

;;************************************************************************************

launcher:

.starting:       db "launcher: starting, about to spawn workera and workerb", 0
.bothSpawned:    db "launcher: both workers spawned", 0
.spawnAFailed:   db "launcher: spawn of workera failed", 0
.spawnBFailed:   db "launcher: spawn of workerb failed", 0
.tick:           db "launcher: tick", 0
.workerAName:    db "workera", 0
.workerBName:    db "workerb", 0
