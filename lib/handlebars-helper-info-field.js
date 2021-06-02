module.exports = function (label, representsField) {
  if (!label || !representsField) {
    throw new Error("Handlerbars Helper 'infoField': label and representsField must be set");
  }

  return `[{"type":"label","value":"${label}","columns": 6},{"type":"field","representsField":"${representsField}","columns": 6,"isEditable": false}]`;
}
