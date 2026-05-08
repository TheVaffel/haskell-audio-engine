"""
Generate types to ensure Haskell and Rust types and values conform to one another to ensure
a safe FFI interaction
"""

RUST_INTERFACE_FILE = 'audio-engine-rs/src/foreign_interface.rs';
HASKELL_INTERFACE_FILE = 'synthesizer-hs/src/ForeignInterface.hs';

AUDIO_COMMANDS = [
    ('InsertAtIndex', ['int', 'signal']),
    ('InsertAndForget', ['signal']),
    ('StopAtIndex', ['int']),
    ('Exit', []),
    ('SetExternalParameter', ['int', 'float', 'float']),
    ('SetExternalParameter2', ['ivec2', 'fvec2', 'float']),
    ('SetExternalParameter3', ['ivec3', 'fvec3', 'float']),
];

AUDIO_GENERATORS = [
    ('SineGenerator', ['signal']),
    ('SineGeneratorWithFrequency', ['float']),
    ('ModulateOp', ['signal', 'signal']),
    ('MixOp', ['signal', 'signal']),
    ('Envelope', ['float', 'float', 'float']),
    ('Volume', ['float', 'signal']),
    ('DistanceFactor', ['ivec3', 'signal']),
    ('Bell', ['float']),
    ('ExternalParameter', ['int']),
    ('Custom', ['float']),
    ('Custom2', ['float']),
];

CONSTANTS = [
    ('LISTENER_X_PARAM_INDEX', 'paramIndexListenerX', 'float'),
    ('LISTENER_Y_PARAM_INDEX', 'paramIndexListenerY', 'float'),
    ('LISTENER_Z_PARAM_INDEX', 'paramIndexListenerZ', 'float'),
];

ALL_SYMBOLS = [*AUDIO_COMMANDS, *AUDIO_GENERATORS]


def gen_rust():
    rust_lines = []
    rust_lines.append('// WARNING: This file has been auto-generated. Modifications should be done to `typegen.py` rather than this file directly');
    rust_lines.append('pub enum NumericCommand {');
    for symbol_index in range(len(ALL_SYMBOLS)):
        rust_lines.append(f'    {ALL_SYMBOLS[symbol_index][0]} = {str(symbol_index)},');
    rust_lines.append('}\n');

    rust_lines.append('#[derive(Clone)]\npub enum AudioCommand {');
    for audio_command in AUDIO_COMMANDS:
        if len(audio_command[1]) == 0:
            rust_lines.append(f'    {audio_command[0]},');
        else:
            rust_lines.append(f'    {audio_command[0]}({','.join([translate_rust_type(x) for x in audio_command[1]])}),');
    rust_lines.append('}\n');

    rust_lines.append('#[derive(Clone)]\npub enum AudioGenerator {');
    for audio_generator in AUDIO_GENERATORS:
        if len(audio_generator[1]) == 0:
            rust_lines.append(f'    {audio_generator[0]},');
        else:
            rust_lines.append(f'    {audio_generator[0]}({','.join([translate_rust_type_with_box(x) for x in audio_generator[1]])}),');
    rust_lines.append('}\n')

    for constant_index in range(len(CONSTANTS)):
        constant = CONSTANTS[constant_index];
        rust_lines.append(f'pub const {constant[0]}: {translate_rust_type(constant[2])} = {constant_index_to_param_index(constant_index)}.0;');

    return rust_lines;


def translate_rust_type(type_name):
    if type_name == 'float':
        return 'f32'
    elif type_name == 'signal':
        return 'AudioGenerator'
    elif type_name == 'int':
        return 'u32'
    elif type_name == 'ivec2':
        return '(i32, i32)';
    elif type_name == 'fvec2':
        return '(f32, f32)';
    elif type_name == 'ivec3':
        return '(i32, i32, i32)';
    elif type_name == 'fvec3':
        return '(f32, f32, f32)';
    raise "Unsupported type for (unboxed) rust translation: " + type_name

def translate_rust_type_with_box(type_name):
    if type_name == 'float':
        return 'f32'
    elif type_name == 'signal':
        return 'Box<AudioGenerator>'
    elif type_name == 'int':
        return 'i32'
    elif type_name == 'ivec2':
        return '(i32, i32)';
    elif type_name == 'fvec2':
        return '(f32, f32)';
    elif type_name == 'ivec3':
        return '(i32, i32, i32)';
    elif type_name == 'fvec3':
        return '(f32, f32, f32)';
    raise "Unsupported type for boxed rust translation: " + type_name

def gen_haskell():
    haskell_lines = []

    haskell_lines.append('-- WARNING: This file has been auto-generated. Modifications should be done to `typegen.py` rather than this file directly');
    haskell_lines.append('module ForeignInterface where');

    for symbol_index in range(len(ALL_SYMBOLS)):
        haskell_lines.append(f'{decapitalize(ALL_SYMBOLS[symbol_index][0])}Marker = {symbol_index} :: Int');

    haskell_lines.append('\n');
    prepend = 'data AudioCommand = ';
    for audio_command in AUDIO_COMMANDS:
        haskell_lines.append(prepend + f'{audio_command[0]} {' '.join([('!' + translate_haskell_type(x)) for x in audio_command[1]])}')
        prepend = '    | '
    haskell_lines.append('    deriving Show\n');

    prepend = 'data AudioGenerator = ';
    for audio_generator in AUDIO_GENERATORS:
        haskell_lines.append(prepend + f'{audio_generator[0]} {' '.join([('!' + translate_haskell_type(x)) for x in audio_generator[1]])}');
        prepend = '    | '
    haskell_lines.append('    | NoGenerator')
    haskell_lines.append('    deriving Show\n')

    for constant_index in range(len(CONSTANTS)):
        constant = CONSTANTS[constant_index];
        haskell_lines.append(f'{constant[1]} = {constant_index_to_param_index(constant_index)} :: {translate_haskell_type(constant[2])}');

    return haskell_lines

def constant_index_to_param_index(constant_index):
    return - (constant_index + 1000)

def decapitalize(st):
    return st[0].lower() + st[1:]

def translate_haskell_type(tt):
    if tt == 'int':
        return 'Int'
    elif tt == 'signal':
        return 'AudioGenerator'
    elif tt == 'float':
        return 'Float'
    elif tt == 'ivec2':
        return '(Int, Int)'
    elif tt == 'fvec2':
        return '(Float, Float)'
    elif tt == 'ivec3':
        return '(Int, Int, Int)'
    elif tt == 'fvec3':
        return '(Float, Float, Float)'

with open(RUST_INTERFACE_FILE, 'w') as ff:
    rust_lines = gen_rust();
    ff.write('\n'.join(rust_lines));

print('\n'.join(rust_lines))

with open(HASKELL_INTERFACE_FILE, 'w') as ff:
    haskell_lines = gen_haskell();
    ff.write('\n'.join(haskell_lines));

print('\n'.join(haskell_lines))
