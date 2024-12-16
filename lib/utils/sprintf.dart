/// default regex
const String placeholderPattern = '(\{\{([a-zA-Z0-9]+)\}\})';

/*
 * Replace string pattern consecutively.
 * Patterns are marked with double-curly brackets.
 * 
 * Example:
 * 
 *     var template = "My name is {{name}} and I'm {{age}} years old"
 *     sprintf(template, ['Oval', 17]);
 * 
 * Result:
 * 
 *     "My name is Oval and I'm 17 years old"
 * 
 **/
String sprintf(String template, List replacements) {
  var regExp = RegExp(placeholderPattern);
  assert(regExp.allMatches(template).length == replacements.length,
      "Template and Replacements length are incompatible");

  for (var replacement in replacements) {
    template = template.replaceFirst(regExp, replacement.toString());
  }

  return template;
}