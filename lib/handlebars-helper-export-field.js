module.exports = function (representsField) {
  if (!representsField) {
    throw new Error('Handlerbars Helper "exportField": representsField must be set');
  }

  return `{"type":"field","representsField":"${representsField}"}`;
};
