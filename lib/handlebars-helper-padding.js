module.exports = function (cols) {
  if (cols < 1 || cols > 12) {
    throw new Error("Handlerbars Helper 'padding': columns must be between 1 and 12 (included)");
  }

  return `{type: label, value: " ", columns: ${cols}}`
}
