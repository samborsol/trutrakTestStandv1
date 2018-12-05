# MPLAB IDE generated this makefile for use with GNU make.
# Project: firstpic16.mcp
# Date: Fri Nov 30 09:35:00 2018

AS = MPASMWIN.exe
CC = 
LD = mplink.exe
AR = mplib.exe
RM = rm

firstpic16.cof : main.o
	$(CC) /p16F1826 "main.o" /u_DEBUG /z__MPLAB_BUILD=1 /z__MPLAB_DEBUG=1 /m"firstpic16.map" /w /o"firstpic16.cof"

main.o : main.asm P16F1826.INC
	$(AS) /q /p16F1826 "main.asm" /l"main.lst" /e"main.err" /o"main.o" /d__DEBUG=1

clean : 
	$(CC) "main.o" "main.err" "main.lst" "firstpic16.cof" "firstpic16.hex" "firstpic16.map"

