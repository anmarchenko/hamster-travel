const MAX_PDF_DOWNLOAD_BYTES = 10 * 1024 * 1024;
const PDF_OBJECT_URL_REVOKE_DELAY_MS = 30_000;

function base64DecodedSize(base64Data) {
  let padding = base64Data.endsWith('==') ? 2 : base64Data.endsWith('=') ? 1 : 0;

  return Math.floor((base64Data.length * 3) / 4) - padding;
}

function base64ToBlob(base64Data, contentType) {
  if (base64DecodedSize(base64Data) > MAX_PDF_DOWNLOAD_BYTES) {
    throw new Error('PDF download is too large.');
  }

  let binary = window.atob(base64Data);
  let bytes = new Uint8Array(binary.length);

  for (let index = 0; index < binary.length; index += 1) {
    bytes[index] = binary.charCodeAt(index);
  }

  return new Blob([bytes], { type: contentType });
}

export function registerPdfDownloadHandler() {
  window.addEventListener('phx:download-pdf', (event) => {
    let { data, filename, content_type: contentType } = event.detail;
    let blob = base64ToBlob(data, contentType || 'application/pdf');
    let url = window.URL.createObjectURL(blob);
    let link = document.createElement('a');

    link.href = url;
    link.download = filename || 'trip-plan.pdf';
    link.style.display = 'none';

    document.body.appendChild(link);
    link.click();
    link.remove();

    window.setTimeout(
      () => window.URL.revokeObjectURL(url),
      PDF_OBJECT_URL_REVOKE_DELAY_MS,
    );
  });
}
