/**
 * Formats a license plate string with consistent spacing for readability.
 * E.g., "VA1948" -> "VA 1948", "OR79FT" -> "OR 79 FT"
 *
 * @param {string} plate - The license plate to format
 * @returns {string} - The formatted license plate
 */
function formatPlate(plate) {
  if (!plate) return plate;

  // Remove all whitespace to get raw characters
  const raw = plate.toUpperCase().replace(/\s+/g, '');

  if (!raw) return plate;

  // Norwegian: 2 letters + 4-5 digits -> "XX YYYYY"
  const norwegianMatch = raw.match(/^([A-Z]{2})(\d{4,5})$/);
  if (norwegianMatch) {
    return `${norwegianMatch[1]} ${norwegianMatch[2]}`;
  }

  // Swedish: 3 letters + 3 digits -> "XXX 123"
  const swedishMatch = raw.match(/^([A-Z]{3})(\d{3})$/);
  if (swedishMatch) {
    return `${swedishMatch[1]} ${swedishMatch[2]}`;
  }

  // Dutch sidecodes (6 characters in various formats)
  if (raw.length === 6) {
    // XX 99 XX pattern
    const dutch1 = raw.match(/^([A-Z]{2})(\d{2})([A-Z]{2})$/);
    if (dutch1) {
      return `${dutch1[1]} ${dutch1[2]} ${dutch1[3]}`;
    }

    // 99 XX XX pattern
    const dutch2 = raw.match(/^(\d{2})([A-Z]{2})([A-Z]{2})$/);
    if (dutch2) {
      return `${dutch2[1]} ${dutch2[2]} ${dutch2[3]}`;
    }

    // XX XX 99 pattern
    const dutch3 = raw.match(/^([A-Z]{2})([A-Z]{2})(\d{2})$/);
    if (dutch3) {
      return `${dutch3[1]} ${dutch3[2]} ${dutch3[3]}`;
    }

    // 99 XXX 9 pattern
    const dutch4 = raw.match(/^(\d{2})([A-Z]{3})(\d{1})$/);
    if (dutch4) {
      return `${dutch4[1]} ${dutch4[2]} ${dutch4[3]}`;
    }

    // 9 XXX 99 pattern
    const dutch5 = raw.match(/^(\d{1})([A-Z]{3})(\d{2})$/);
    if (dutch5) {
      return `${dutch5[1]} ${dutch5[2]} ${dutch5[3]}`;
    }
  }

  // Generic: split between letters and numbers
  let result = '';
  let lastType = null;

  for (let i = 0; i < raw.length; i++) {
    const char = raw[i];
    const isLetter = /[A-Z]/.test(char);
    const currentType = isLetter ? 'L' : 'D';

    if (lastType !== null && lastType !== currentType) {
      result += ' ';
    }
    result += char;
    lastType = currentType;
  }

  return result;
}

/**
 * Normalizes a license plate for comparison (removes whitespace, uppercase).
 *
 * @param {string} plate - The license plate to normalize
 * @returns {string} - The normalized license plate
 */
function normalizePlate(plate) {
  if (!plate) return '';
  return plate.toUpperCase().replace(/\s+/g, '');
}

module.exports = {
  formatPlate,
  normalizePlate,
};
