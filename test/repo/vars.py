#!/usr/bin/env python

makefile = open('../../Makefile.inputs', 'r')
makefile_lines = makefile.readlines()

vars = {}
outputs = {}
errors = 0

for line in makefile_lines:
  if line.startswith('#'):
    makefile_lines.remove(line)
    continue
  parts = line.split('=', 1)
  if parts[0].startswith('export'):
    var_name = parts[0].strip().split(' ')[1].lower()
  else:
    var_name = parts[0].strip().lower()
  vars[var_name] = {'default_value': parts[1].strip(), 'makefile': True}

action = open('../../action.yml', 'r')
action_lines = action.readlines()

at_inputs = False
at_outputs = False
for line in action_lines:
  if not at_inputs:
    if line.strip() == 'inputs:':
      at_inputs = True
      continue
  else:
    if line.startswith('    '):
      parts = line.strip().split(':', 1)
      if parts[0] == 'description':
        vars[var_name]['description'] = parts[1].strip()
      if parts[0] == 'deprecationMessage':
        vars[var_name]['deprecated'] = True
      if parts[0] == 'default':
        if 'default' in vars[var_name]:
          if vars[var_name]['default_value'] != parts[1].strip().strip('"'):
            print("ERROR: Default value for " + var_name + " in action.yml does not match Makefile")
            errors += 1
        else:
          vars[var_name]['default_value'] = parts[1].strip().strip('"')
    elif line.startswith('  '):
      var_name = line.strip().strip(':').lower()
      if var_name in vars:
        vars[var_name][action] = True
      else:
        print("WARNING: " + var_name + " found in action.yml but not Makefile")
        vars[var_name] = {}
        vars[var_name]['action'] = True
    else:
      at_inputs = False

  if not at_outputs:
    if line.strip() == 'outputs:':
      at_outputs = True
      continue
  else:
    if line.startswith('    '):
      parts = line.strip().split(':', 1)
      if parts[0] == 'description':
        outputs[var_name]['description'] = parts[1].strip()
      if parts[0] == 'deprecationMessage':
        outputs[var_name]['deprecated'] = True
      if parts[0] == 'default':
        outputs[var_name]['default_value'] = parts[1].strip().strip('"')
    elif line.startswith('  '):
      var_name = line.strip().strip(':').lower()
      outputs[var_name] = {}
    else:
      at_outputs = False


readme = open('../../README.md', 'r')
readme_lines = readme.readlines()

at_inputs = False
skip_header = True
at_outputs = False
for line in readme_lines:
  if not at_inputs:
    if line.strip() == '### Inputs':
      at_inputs = True
      continue
  else:
    if skip_header:
      if line.startswith('| -----'):
        skip_header = False
        continue
    else:
      if not line.startswith('|'):
        at_inputs = False
        continue
      parts = line.split('|')
      var_name = parts[1].strip().lower()
      if not var_name in vars:
        print("ERROR: " + var_name + " is not listed in action.yml or Makefile")
        vars[var_name] = {}
      vars[var_name]
      var_description = parts[2].strip()
      var_default_value = parts[3].strip()
      var_action = parts[4].strip()
      var_makefile = parts[5].strip()
