; If you're removing the carryable pipe sprite from your hack
;  and applied the included !FixFreeze hijack, use this patch to remove that.

; DO NOT apply this patch otherwise.

!bank = $800000
if read1($00FFD5) == $23
	sa1rom
	!bank = $000000
endif

org $00A2E2
	JSL	$01808C|!bank