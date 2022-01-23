/**
 * Get all URLs in HTML element.
 * @param {HTMLElement} root Root of the all anchors elements.
 * @returns {HTMLAnchorElement[]} Array of all anchors elements.
 */
 function getAllURLs(root) {
  return Array.from(root.getElementsByTagName('a'));
}

/**
 * Generate a new text file then ask the user to download it.
 * @param {string} content Content of the new text file.
 * @param {string} name Default filename
 */
 function downloadFile(content, name='content.txt') {
  // Create the file
  const blob = new Blob([content], { type: 'text/plain' });
  // Create the anchor element
  const a = document.createElement('a');
  // Create the URL to the generated file
  a.href = window.URL.createObjectURL(blob);
  // Set the filename
  a.download = name;
  // Ask the user to download it
  a.click()
}

/**
 * Download a list of url in a HTML element.
 * @param {HTMLElement} root Root of the all anchors elements.
 * @param name Default filename
 */
function createUrlsList(root, name='url.list') {
  downloadFile(getAllURLs(root)
    .reduce((acc, val) => acc + val.href + '\n', ''), name)
}
