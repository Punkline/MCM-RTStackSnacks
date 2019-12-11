# --- RTStackSnacks.s - v0.1
# .include this module in your code to enable snacks.
#    use the line:  .include "RTStackSnacks.s"

# --- to find the snacks - use one of these methods:
#    getsnacks rSnacks          # get variable allocations
#    getsnacks.predef rPredef   # get predefined data table
#   - or:
#    lwz rSnacks, -0x2018(rtoc)
#    lwz rPredef, -0x2014(rtoc)


# --- to get a snack - use a snack allocation symbol:
#    lwz rSnack, xMySnack(rSnacks)
#   - or:
#    addi rSnack, rSnacks, xMySnack
# - these symbols are generated below, in Snack Allocations
# - they may also be generated in .RTStackSnacks\Snacks.txt


# 'Snacks' are variable allocations.
# Snack data is effectively static, but initially blank.
# - snacks take up no space in the static DOL file
# - snacks take up no space in the dynamic memory heap
# - snacks are not volatile, and persist between scenes
# - snacks all derive from base address 804eebb0 - size
#   - you may access this from a pointer in -0x2018(rtoc)
#     - shortcut macro:  getsnacks rSnacks

# 'Predef' data is just regular static data.
# - Predef data takes up space in the DOL
# - Predef data can be used to define default values
# - Predef data is static, but loc isn't known by assembler
#   - you may access this from a pointer in -0x2014(rtoc)
#     - shortcut macro:  getsnacks.predef rPredef

# 'Setup symbols' can be used to initialize GAS objects
# - all codes that .include this file will inherit these
# - symbols for Predef structures may be added here
# - utility macros may also be added here

# 'Setup instructions' can be used to initialize Snacks
# - setup instructions are executed at start of the game
# - they may be used to initialize snack variables
#   - Predef may be used to copy defaults if needed

.ifndef RTStackSnacks.included
RTStackSnacks.included=1
# - (This protects this module from multiple .includes)


# --- User Params:
RTStackSnacks.SnackRack.size = 0x800
# This is a number of bytes that are left undefined in the
#  snack allocation frame. (The 'Snack Rack')
# - access the Snack Rack using offset 'RTStackSnacks.xSnackRack'
#   - this is padding, made in addition to the total size
#   - it is initially zeroed out with the rest of the snack allocations

enum.debug = 0
# Setting this to 1 will stop the code from installing, but
#  will let you see the hard offsets generated for all
#  enumerations created from the 'enum' macros.


# --- Bundled Modules:
.include "enum.s"   # - enables useful enumeration macros and register/cr symbols
.include "blaba.s"  # - enables bla and ba instructions as long-form blrl and bctr branches


# --- Setup Symbols and Macros here:
# - non-snack symbols or macros can be defined here for every code that uses the this module






# --- end of Setup Symbols and Macros
.include ".RTStackSnacks\\SetupSymbols.txt"
# -- (you may also include stuff in this file)


# --- Example Snack Allocations:

# You may use 'enum' to list exact offset names
#   enum [base], [size], [name1, name2, ...]
enum 0, 4, example.xMyVar, example.xMySecond, example.xMyThird

# You may use a blank [base] value to continue enumeration with another group of names
enum  , 4, example.namespace.xMyVar

# You may use 'enumf' to format names with a common prefix
#   enumf [base], [size], [prefix], [suffix], [name1, name2, ...]
enumf, 4, example.namespace.,, xMySecond, xMyThird, xMyFourth

# You may use (expressions) in parentheses to change [size] inline with the arguments
enumf, 4, example.,, xMySingle, (8),xMyDouble, (2),xMyHWord, (1),xByteA, xByteB, (4),xMyWord

# You may use the property 'enum' to reference the current [base] memory
example.size = enum - example.xMyVar
# - the last enum value is used to calculate total size in a way similar to this
#   - the enum value must therfore remain intact while building the snacks allocation table
#   - you may store the value of enum in another variable identifier temporarily, if needed


# --- Create Snack Allocations here: - start at base of 0
# - names must be unique, so using a parent namespace is recommended
enum 0, 4,





# --- end of Snack Allocations
.include ".RTStackSnacks\\Snacks.txt"
# -- (you may also include additional offsets in this file)

RTStackSnacks.xSnackRack = enum
RTStackSnacks.bogusframesize = (enum + RTStackSnacks.SnackRack.size + 0x80)
# - this helps define the stack frame size using any enumerations that were defined


.macro RTStackSnacks.PredefDataEmitter
# This container is for real data, not symbols
# You may access it from the getsnacks.predef macro
# - these definitions will take up space in the DOL
## # Examples:
##   .long 0, 1, 2, 3
##   .asciz "Hello World"
##   mflr r0

# --- Initialize Predef Data here:





# --- end of Predef Data
.include ".RTStackSnacks\\PredefData.txt"
# -- (you may also include data in this file)
# -- (use .incbin to include binary files)
.endm


.macro RTStackSnacks.SetupInstructions
# This last container is for any instructions you want
#   to include at the very beginning of the game.
# They will be executed before Melee is fully initialized.
# --- Extra Setup Instructions go here:





# --- end of Setup Instructions
.include ".RTStackSnacks\\SetupInstructions.txt"
# -- (you may also include stuff in this file)
.endm

# --- shortcut macros:
.macro getsnacks, reg; lwz \reg, -0x2018(rtoc);.endm
.macro getsnacks.predef, reg; lwz \reg, -0x2014(rtoc);.endm
.endif
