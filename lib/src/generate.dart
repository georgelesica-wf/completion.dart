import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as pathos;

const _BIN_NAME_REPLACEMENT = '{{binName}}';
const _FUNC_NAME_REPLACEMENT = '{{funcName}}';
const _SCRIPT_DETAILS_REPLACEMENT = '{{details}}';

/*
 * Must be at least one char.
 * Must start with a letter or number
 * Can contain letters, numbers, '_', '-', '.'
 * Must end with letter or number
 */
final _binNameMatch = new RegExp(r'^[a-zA-Z0-9]((\w|-|\.)*[a-zA-Z0-9])?$');

/*
 * Format for unified bash and zsh completion script:
 * https://npmjs.org/
 * https://github.com/isaacs/npm/blob/master/lib/utils/completion.sh
 *
 * Inspiration for auto-generating completion scripts:
 * https://github.com/mklabs/node-tabtab
 * https://github.com/mklabs/node-tabtab/blob/master/lib/completion.sh
 */

String generateCompletionScript(List<String> binaryNames) {
  if (binaryNames.isEmpty) {
    throw new ArgumentError('Provide the name of at least of one command');
  }

  for (final binName in binaryNames) {
    if (!_binNameMatch.hasMatch(binName)) {
      final msg = 'The provided name - "$binName" - is invalid\n'
          'It must match regex: ${_binNameMatch.pattern}';
      throw msg;
    }
  }

  var buffer = new StringBuffer();

  final prefix =
      LineSplitter.split(_PREFIX).map((l) => '# $l'.trim()).join('\n');
  buffer.writeln(prefix);

  // empty line
  buffer.writeln('');

  for (final binName in binaryNames) {
    buffer.writeln(_printBinName(binName));
  }

  final detailLines = ['Generated ${new DateTime.now().toUtc()}',];

  if (Platform.script.scheme == 'file') {
    var scriptPath = Platform.script.toFilePath();
    scriptPath = pathos.absolute(pathos.normalize(scriptPath));

    detailLines.add('By ${scriptPath}');
  }

  final details = detailLines.map((l) => '## $l').join('\n');
  buffer.writeln(details);

  return buffer.toString();
}

String _printBinName(String binName) {
  var templateContents = _TEMPLATE.replaceAll(_BIN_NAME_REPLACEMENT, binName);

  var funcName = binName.replaceAll('.', '_');
  funcName = '__${funcName}_completion';
  templateContents =
      templateContents.replaceAll(_FUNC_NAME_REPLACEMENT, funcName);

  return templateContents;
}

const _PREFIX = '''

Installation:

Via shell config file  ~/.bashrc  (or ~/.zshrc)

  Append the contents to config file
  'source' the file in the config file

You may also have a directory on your system that is configured
   for completion files, such as:

   /usr/local/etc/bash_completion.d/
''';

const _TEMPLATE = r'''
###-begin-{{binName}}-completion-###

if type complete &>/dev/null; then
  {{funcName}}() {
    local si="$IFS"
    IFS=$'\n' COMPREPLY=($(COMP_CWORD="$COMP_CWORD" \
                           COMP_LINE="$COMP_LINE" \
                           COMP_POINT="$COMP_POINT" \
                           {{binName}} completion -- "${COMP_WORDS[@]}" \
                           2>/dev/null)) || return $?
    IFS="$si"
  }
  complete -F {{funcName}} {{binName}}
elif type compdef &>/dev/null; then
  {{funcName}}() {
    si=$IFS
    compadd -- $(COMP_CWORD=$((CURRENT-1)) \
                 COMP_LINE=$BUFFER \
                 COMP_POINT=0 \
                 {{binName}} completion -- "${words[@]}" \
                 2>/dev/null)
    IFS=$si
  }
  compdef {{funcName}} {{binName}}
elif type compctl &>/dev/null; then
  {{funcName}}() {
    local cword line point words si
    read -Ac words
    read -cn cword
    let cword-=1
    read -l line
    read -ln point
    si="$IFS"
    IFS=$'\n' reply=($(COMP_CWORD="$cword" \
                       COMP_LINE="$line" \
                       COMP_POINT="$point" \
                       {{binName}} completion -- "${words[@]}" \
                       2>/dev/null)) || return $?
    IFS="$si"
  }
  compctl -K {{funcName}} {{binName}}
fi

###-end-{{binName}}-completion-###
''';
