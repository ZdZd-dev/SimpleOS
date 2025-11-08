# The Architecture of simpleOS: A 16-bit x86 Assembly Operating System

## Overview
simpleOS is a complete operating system written entirely in x86 assembly language, designed to run on legacy PC hardware in real mode. This document details the technical architecture and implementation decisions behind the system.

## Boot Process

### Stage 1: Bootloader (512 bytes)
The system begins execution at physical address 0x7C00, following the standard PC boot convention. The boot sector:
- Sets up segment registers (DS, ES, SS) to 0
- Initializes stack pointer to 0x7C00
- Loads the kernel from disk sectors into memory at 0x7E00
- Transfers control to the kernel entry point

### Stage 2: Kernel Initialization
At 0x7E00, the kernel performs:
- Video mode setup (80x25 text mode via BIOS INT 10h)
- Professional UI rendering with border graphics
- System timer initialization
- Interrupt vector configuration

## Memory Layout

```
0x0000-0x03FF: Interrupt Vector Table
0x0400-0x04FF: BIOS Data Area
0x0500-0x7BFF: Free Conventional Memory
0x7C00-0x7DFF: Boot Sector (512 bytes)
0x7E00-0x9FFF: Kernel Code & Data
0xA000-0xFFFF: Video Memory & System Use
```

## Core System Architecture

### 1. User Interface System
**Text Mode Graphics:**
- Utilizes BIOS INT 10h for all video operations
- Implements custom border drawing using box-drawing characters (0xC4, 0xB3, etc.)
- Maintains cursor position tracking for proper text wrapping
- Supports centered text rendering for headers

**Input System:**
- Keyboard input via BIOS INT 16h
- Real-time key processing without blocking
- Support for special keys (arrows, function keys)
- Input buffer management with backspace handling

### 2. Command Interpreter
The shell implements:
- Command parsing and dispatch system
- String comparison for command recognition
- Dynamic command registration
- Built-in help system with command documentation

### 3. Application Framework
All applications follow a consistent pattern:
```assembly
application_entry:
    call clear_content_area
    ; Display instructions
    ; Initialize application state
    ; Main application loop
    ; Clean exit back to shell
```

## Major Subsystems

### 1. File System Interface
While simpleOS doesn't implement a full file system, it provides:
- Disk sector reading via BIOS INT 13h
- Memory-based file buffers for applications
- Simple data persistence within session

### 2. Memory Management
- Static memory allocation for system structures
- Application-specific buffers (snake positions, notepad content, etc.)
- Careful segment:offset addressing throughout

### 3. Game Engine Framework
**Common Game Components:**
- Game state structures (position, score, lives)
- Main game loops with timed updates
- Collision detection systems
- Input handling for game controls
- Rendering systems for game objects

## Key Applications

### 1. Snake Game
**Implementation Details:**
- Linked list structure for snake segments
- Food generation with position validation
- Collision detection with walls and self
- Direction-based movement logic
- Growing mechanism when food is consumed

**Technical Features:**
- Adjustable game speed based on direction
- Border-constrained play area
- Random number generation via system timer

### 2. Pong Game
**Physics System:**
- Ball movement with simple vector mathematics
- Paddle collision detection and angle calculation
- AI opponent with imperfect tracking
- Score tracking and win conditions

**Rendering:**
- ASCII art paddles and ball
- Real-time position updates
- Score display during gameplay

### 3. Space Invaders
**Alien Management:**
- Grid-based alien positioning
- Wave movement patterns
- Progressive difficulty increases
- Alien shooting AI with random timing

**Combat System:**
- Player bullet management
- Alien destruction scoring
- Collision detection for hits
- Game over conditions

### 4. Typing Game
**Word System:**
- Pre-defined word dictionary
- Random word selection
- Input validation and scoring
- Lives management system

**User Interface:**
- Real-time typing feedback
- Score and lives display
- Word presentation system

### 5. Calculator
**Arithmetic Engine:**
- Integer arithmetic operations
- Multiplication and division support
- Error handling for division by zero
- Number parsing from string input

**Interface:**
- Interactive prompt system
- Result formatting and display
- Continuous calculation mode

### 6. Notepad
**Text Editing:**
- Character buffer management
- Cursor position tracking
- Line wrapping and newline handling
- Backspace and delete functionality

**Display System:**
- Text rendering with scroll boundaries
- Cursor positioning feedback
- Edit mode indicators

## System Calls and Services

### BIOS Interrupt Usage
- **INT 10h**: Video services (text mode, cursor control)
- **INT 16h**: Keyboard input services
- **INT 1Ah**: Time and date services
- **INT 13h**: Disk services
- **INT 15h**: System services (memory detection)

### Custom Services
- **print_string**: Basic string output
- **print_string_wrapped**: Word-wrapped text output
- **read_string**: Buffered keyboard input
- **clear_content_area**: Screen management
- **compare_string**: String comparison utility

## Technical Challenges Overcome

### 1. Memory Constraints
- Careful management of 640KB conventional memory
- Efficient data structure design
- In-place algorithm implementations

### 2. Real-mode Limitations
- 16-bit addressing limitations
- Segment:offset arithmetic throughout
- No memory protection features

### 3. Performance Optimization
- Minimal use of expensive operations (division, multiplication)
- Efficient screen updates to reduce flicker
- Optimized game loops for smooth gameplay

## Development Philosophy

### 1. Simplicity First
- Clear, readable assembly code
- Consistent coding patterns
- Minimal abstraction layers

### 2. User Experience
- Responsive input handling
- Clear visual feedback
- Intuitive command structure

### 3. Educational Value
- Demonstrates fundamental computer architecture concepts
- Shows direct hardware interaction
- Illustrates low-level programming techniques

## Future Expansion Possibilities

### 1. Technical Enhancements
- Protected mode operation
- Simple file system implementation
- Basic multi-tasking support
- Hardware interrupt handling

### 2. Application Extensions
- Text editor with file save/load
- Simple BASIC interpreter
- Network connectivity
- Sound support via PC speaker

## Conclusion

simpleOS represents a complete, functional operating system built from first principles using x86 assembly language. It demonstrates that even with the constraints of real mode and limited resources, a rich computing environment with games, utilities, and a professional interface is achievable through careful design and efficient coding practices.

The system serves as both a practical demonstration of low-level programming concepts and a foundation for further exploration in operating system development. Its modular architecture allows for continuous expansion while maintaining the simplicity and performance characteristics that make assembly programming uniquely powerful.

---
*simpleOS - A testament to understanding computers at their most fundamental level.*
