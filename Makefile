
TOOLPATH	= /usr/bin
PROJECT   = project

# Hardware
ARMCPU		= cortex-m3
STM32MCU	= STM32F103xB	# Change here for another board

# ST libraries
CMSISBASE 		= cmsis
CMSISINC 		= $(CMSISBASE)/include
DEVICEINC 		= $(CMSISBASE)/Device/STM32F1xx/include
DEVICESRC	 	= $(CMSISBASE)/Device/STM32F1xx/src
DEVICESTARTUP 	= startup_stm32f103xb.s # Change here for another board
DEVICELINKER 	= $(CMSISBASE)/Device/STM32F1xx/linker/STM32F103XB_FLASH.ld # Change here for another board

# File structure
SRCDIR = src
BINDIR = bin
OBJDIR = obj
INCDIR = include

# Sources
SRC = $(wildcard $(SRCDIR)/*.c) $(wildcard $(DEVICESRC)/*.c)
ASM = $(wildcard $(SRCDIR)/*.s) $(DEVICESRC)/$(DEVICESTARTUP)

# Headers
INCLUDE  = -I$(INCDIR)
INCLUDE += -I$(CMSISINC)
INCLUDE += -I$(DEVICEINC)

# C flags
CFLAGS   = -std=c99
CFLAGS	+= -Wall
CFLAGS	+= -fno-common
CFLAGS	+= -mthumb
CFLAGS	+= -mcpu=$(ARMCPU)
CFLAGS	+= -D$(STM32MCU)
CFLAGS	+= -g
CFLAGS	+= -Wa,-ahlms=$(addprefix $(OBJDIR)/,$(notdir $(<:.c=.lst)))
CFLAGS	+= $(INCLUDE)

# L flags
LDFLAGS  = -T$(DEVICELINKER)
LDFLAGS	+= -mthumb
LDFLAGS	+= -mcpu=$(ARMCPU)
LDFLAGS += --specs=nosys.specs
LDFLAGS += --specs=nano.specs
LDFLAGS += -lc
LDFLAGS += -Wl,-Map=$(OBJDIR)/$(PROJECT).map

# A flags
ASFLAGS += -mcpu=$(ARMCPU)

# Tools
CC 				= $(TOOLPATH)/arm-none-eabi-gcc
AS 				= $(TOOLPATH)/arm-none-eabi-as
AR 				= $(TOOLPATH)/arm-none-eabi-ar
LD 				= $(TOOLPATH)/arm-none-eabi-ld
OBJCOPY 		= $(TOOLPATH)/arm-none-eabi-objcopy
SIZE 			= $(TOOLPATH)/arm-none-eabi-size
OBJDUMP 		= $(TOOLPATH)/arm-none-eabi-objdump
SWDFLASH 		= $(TOOLPATH)/st-flash
RM 				= rm -rf


## Build process
OBJ := $(addprefix $(OBJDIR)/,$(notdir $(SRC:.c=.o)))
OBJ += $(addprefix $(OBJDIR)/,$(notdir $(ASM:.s=.o)))

all: $(BINDIR)/$(PROJECT).bin

flash: $(BINDIR)/$(PROJECT).bin
	$(SWDFLASH) write $(BINDIR)/$(PROJECT).bin 0x8000000

macros:
	$(CC) $(GCFLAGS) -dM -E - < /dev/null

clean:
	$(RM) $(BINDIR)
	$(RM) $(OBJDIR)

# Compile / assemble project files
$(OBJDIR)/%.o: $(SRCDIR)/%.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJDIR)/%.o: $(SRCDIR)/%.s
	@mkdir -p $(dir $@)
	$(AS) $(ASFLAGS) -o $@ $<

# Compile / assemble CMSIS and Device files
$(OBJDIR)/%.o: $(DEVICESRC)/%.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJDIR)/%.o: $(DEVICESRC)/%.s
	@mkdir -p $(dir $@)
	$(AS) $(ASFLAGS) -o $@ $<

# Link binaries
$(BINDIR)/$(PROJECT).hex: $(BINDIR)/$(PROJECT).elf
	$(OBJCOPY) -R .stack -O ihex $(BINDIR)/$(PROJECT).elf $(BINDIR)/$(PROJECT).hex

$(BINDIR)/$(PROJECT).bin: $(BINDIR)/$(PROJECT).elf
	$(OBJCOPY) -R .stack -O binary $(BINDIR)/$(PROJECT).elf $(BINDIR)/$(PROJECT).bin

$(BINDIR)/$(PROJECT).elf: $(OBJ)
	@mkdir -p $(dir $@)
	$(CC) $(OBJ) $(LDFLAGS) -o $(BINDIR)/$(PROJECT).elf
	$(OBJDUMP) -D $(BINDIR)/$(PROJECT).elf > $(BINDIR)/$(PROJECT).lst
	$(SIZE) $(BINDIR)/$(PROJECT).elf
