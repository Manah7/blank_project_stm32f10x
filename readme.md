# 

## Build
```
make
```
## Flash
```
make flash
```
## Clean
```
make clean
```
## Debug
**GDB** (multiarch), terminal 1
```
file bin/project.elf
target extended-remote :3333
```
**OpenOCD**, terminal 2
```
openocd -f target/stlink.cfg -f target/stm32f1x.cfg
```
