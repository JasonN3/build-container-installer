#!/usr/bin/env python

makefile = open('../../Makefile.inputs', 'r')
makefile_lines = makefile.readlines()

inputs = {}
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
  inputs[var_name] = {'default_value': parts[1].strip(), 'makefile': True}

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
        inputs[var_name]['description'] = parts[1].strip()
      if parts[0] == 'deprecationMessage':
        inputs[var_name]['deprecated'] = True
      if parts[0] == 'default':
        if 'default' in inputs[var_name]:
          if inputs[var_name]['default_value'] != parts[1].strip().strip('"'):
            print("ERROR: Default value for " + var_name + " in action.yml does not match Makefile")
            errors += 1
        else:
          inputs[var_name]['default_value'] = parts[1].strip().strip('"')
    elif line.startswith('  '):
      var_name = line.strip().strip(':').lower()
      if not var_name in inputs:
        inputs[var_name] = {}
      inputs[var_name]['action'] = True
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
      if not var_name in inputs:
        print("ERROR: " + var_name + " is not listed in action.yml or Makefile")
        errors += 1
        continue
      if 'description' in inputs[var_name]:
        if parts[2].strip().strip('\*') != inputs[var_name]['description']:
          print("WARNING: " + var_name + " description in README.md does not match action.yml")
      if 'default_value' in inputs[var_name]:
        if not parts[3].strip().strip('"<>').startswith('*'):
          if inputs[var_name]['default_value'] == "":
            if parts[3].strip().strip('"') != '\\[empty\\]':
              print("ERROR: " + var_name + " default value in README.md does not match action.yml")
              errors += 1
          elif parts[3].strip().strip('"<>') != inputs[var_name]['default_value']:
            print("ERROR: " + var_name + " default value in README.md does not match action.yml")
            errors += 1
      if 'action' in inputs[var_name] and inputs[var_name]['action']:
        if parts[4].strip() != ':white_check_mark:':
          print("WARNING: " + var_name + " not labeled as in action.yml in the README.md")
      if 'makefile' in inputs[var_name] and inputs[var_name]['makefile']:
        if parts[4].strip() != ':white_check_mark:':
          print("WARNING: " + var_name + " not labeled as in Makefile in the README.md")

exit(errors)