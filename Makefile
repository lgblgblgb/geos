AS=ca65
LD=ld65

ASFLAGS=-I inc -I .

KERNAL_SOURCES= \
	kernal/bitmask.s \
	kernal/bswfont.s \
	kernal/conio.s \
	kernal/dlgbox.s \
	kernal/filesys.s \
	kernal/fonts.s \
	kernal/graph.s \
	kernal/header.s \
	kernal/hw.s \
	kernal/icon.s \
	kernal/init.s \
	kernal/irq.s \
	kernal/jumptable.s \
	kernal/keyboard.s \
	kernal/load.s \
	kernal/mainloop.s \
	kernal/math.s \
	kernal/memory.s \
	kernal/menu.s \
	kernal/misc.s \
	kernal/mouse.s \
	kernal/panic.s \
	kernal/patterns.s \
	kernal/process.s \
	kernal/reu.s \
	kernal/serial.s \
	kernal/sprites.s \
	kernal/start.s \
	kernal/time.s \
	kernal/tobasic.s \
	kernal/vars.s

DEPS= \
	inc/c64.inc \
	inc/const.inc \
	inc/diskdrv.inc \
	inc/geosmac.inc \
	inc/geossym.inc \
	inc/inputdrv.inc \
	inc/jumptab.inc \
	inc/kernal.inc \
	inc/printdrv.inc

KERNAL_OBJECTS=$(KERNAL_SOURCES:.s=.o)

ALL_BINS= \
	kernal.bin \
	lokernal.bin \
	start.bin \
	drv1541.bin \
	drv1571.bin \
	drv1581.bin \
	drvf011.bin \
	amigamse.bin \
	joydrv.bin \
	lightpen.bin \
	mse1531.bin \
	koalapad.bin \
	pcanalog.bin

all: geos.d64 geos.d81

clean:
	rm -f $(KERNAL_OBJECTS) drv/*.o input/*.o $(ALL_BINS) combined.prg compressed.prg geos.d64 geos.d81 compressed_c65.prg compressed.bin loader/*.o compressed_c65m.prg

geos.d64: compressed.prg
	if [ -e GEOS64.D64 ]; then \
		cp GEOS64.D64 geos.d64; \
		echo 'delete geos geoboot configure "geos kernal"' | c1541 geos.d64 >/dev/null; \
		echo write compressed.prg geos | c1541 geos.d64 >/dev/null; \
		echo \*\*\* Created geos.d64 based on GEOS64.D64.; \
	else \
		echo format geos,00 d64 geos.d64 | c1541 >/dev/null; \
		echo write compressed.prg geos | c1541 geos.d64 >/dev/null; \
		if [ -e desktop.cvt ]; then echo geoswrite desktop.cvt | c1541 geos.d64; fi >/dev/null; \
		echo \*\*\* Created fresh geos.d64.; \
	fi;

geos.d81: compressed.prg compressed_c65.prg compressed_c65m.prg
	if [ -e GEOS64.D81 ]; then \
		cp GEOS64.D81 geos.d81; \
		echo 'delete geos geoboot configure "geos kernal"' | c1541 geos.d81 >/dev/null; \
		echo write compressed.prg geos | c1541 geos.d81 >/dev/null; \
		echo write compressed_c65.prg geos65 | c1541 geos.d81 >/dev/null; \
		echo write compressed_c65m.prg geos65m | c1541 geos.d81 >/dev/null; \
		echo \*\*\* Created geos.d81 based on GEOS64.D81.; \
	else \
		echo format geos,00 d81 geos.d81 | c1541 >/dev/null; \
		echo write compressed.prg geos | c1541 geos.d81 >/dev/null; \
		echo write compressed_c65.prg geos65 | c1541 geos.d81 >/dev/null; \
		echo write compressed_c65m.prg geos65m | c1541 geos.d81 >/dev/null; \
		if [ -e desktop.cvt ]; then echo geoswrite desktop.cvt | c1541 geos.d81; fi >/dev/null; \
		echo \*\*\* Created fresh geos.d81.; \
	fi;

compressed_c65.prg: compressed.prg loader/uglyboot.o
	$(LD) -t none loader/uglyboot.o -o $@

compressed_c65m.prg: compressed.bin loader/uncrunch.o loader/boot.o
	$(LD) -C loader/c65.cfg loader/boot.o loader/uncrunch.o -o $@

compressed.prg: combined.prg
	pucrunch +f -c64 -x0x5000 $< $@

compressed.bin: combined.prg
	pucrunch -c0 -x0x5000 $< $@

combined.prg: $(ALL_BINS)
	printf "\x00\x50" > tmp.bin
	cat start.bin /dev/zero | dd bs=1 count=16384 >> tmp.bin 2> /dev/null
	#cat drv1541.bin /dev/zero | dd bs=1 count=3456 >> tmp.bin 2> /dev/null
	cat drvf011.bin /dev/zero | dd bs=1 count=3456 >> tmp.bin 2> /dev/null
	cat lokernal.bin /dev/zero | dd bs=1 count=8640 >> tmp.bin 2> /dev/null
	cat kernal.bin /dev/zero | dd bs=1 count=16192 >> tmp.bin 2> /dev/null
	cat joydrv.bin >> tmp.bin 2> /dev/null
	mv tmp.bin combined.prg

kernal.bin: $(KERNAL_OBJECTS) kernal/kernal.cfg
	$(LD) -C kernal/kernal.cfg $(KERNAL_OBJECTS) -o $@ -m kernal.map

lokernal.bin: kernal.bin

start.bin: kernal.bin

drv1541.bin: drv/drv1541.o drv/drv1541.cfg $(DEPS)
	$(LD) -C drv/drv1541.cfg drv/drv1541.o -o $@

drv1571.bin: drv/drv1571.o drv/drv1571.cfg $(DEPS)
	$(LD) -C drv/drv1571.cfg drv/drv1571.o -o $@

drv1581.bin: drv/drv1581.o drv/drv1581.cfg $(DEPS)
	$(LD) -C drv/drv1581.cfg drv/drv1581.o -o $@

drvf011.bin: drv/drvf011.o drv/drvf011.cfg $(DEPS)
	$(LD) -C drv/drvf011.cfg drv/drvf011.o -o $@

amigamse.bin: input/amigamse.o input/amigamse.cfg $(DEPS)
	$(LD) -C input/amigamse.cfg input/amigamse.o -o $@

joydrv.bin: input/joydrv.o input/joydrv.cfg $(DEPS)
	$(LD) -C input/joydrv.cfg input/joydrv.o -o $@

lightpen.bin: input/lightpen.o input/lightpen.cfg $(DEPS)
	$(LD) -C input/lightpen.cfg input/lightpen.o -o $@

mse1531.bin: input/mse1531.o input/mse1531.cfg $(DEPS)
	$(LD) -C input/mse1531.cfg input/mse1531.o -o $@

koalapad.bin: input/koalapad.o input/koalapad.cfg $(DEPS)
	$(LD) -C input/koalapad.cfg input/koalapad.o -o $@

pcanalog.bin: input/pcanalog.o input/pcanalog.cfg $(DEPS)
	$(LD) -C input/pcanalog.cfg input/pcanalog.o -o $@

%.o: %.s $(DEPS)
	$(AS) $(ASFLAGS) $< -o $@

# a must!
love:	
	@echo "Not war, eh?"
