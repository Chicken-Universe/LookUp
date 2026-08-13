document.getElementById('lookupForm').addEventListener('submit', async function (e) {
  e.preventDefault();

  const statusEl = document.getElementById('status');
  const previewEl = document.getElementById('promptPreview');
  const destinationTarget = document.getElementById('destinationTarget').value;
  const destinationCountry = document.getElementById('destinationCountry').value;
  const cameraGear = document.getElementById('cameraGear').value;
  const shootingTarget = document.getElementById('shootingTarget').value;
  const formattedPrompt = `Target Lokasi: ${destinationTarget}, ${destinationCountry}\nGear/Kamera: ${cameraGear}\nTujuan Pemotretan: ${shootingTarget}`;

  previewEl.textContent = formattedPrompt;
  statusEl.textContent = 'Sedang mengirim ke Langflow AI...';
  statusEl.className = 'text-sm text-indigo-400';
  
  const FLOW_ID = 'LANGFLOW_ID';
  const LANGFLOW_API_KEY = 'LANGFLOW_API_KEY';
  const LANGFLOW_URL = `http://127.0.0.1:7860/api/v1/run/${FLOW_ID}?stream=false`;

  try {
    const response = await fetch(LANGFLOW_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': LANGFLOW_API_KEY
      },
      body: JSON.stringify({
        input_value: formattedPrompt,
        output_type: 'chat',
        input_type: 'chat',
        tweaks: {}
      })
    });

    if (!response.ok) {
      throw new Error(`Server Error: ${response.status}`);
    }

    const data = await response.json();
    const aiResult = data.outputs[0].outputs[0].results.message.text;

    previewEl.textContent = aiResult;
    statusEl.textContent = 'Selesai!';
    statusEl.className = 'text-sm text-emerald-400';

  } catch (error) {
    console.error('Error saat menghubungi Langflow:', error);
    statusEl.textContent = 'Gagal menghubungi AI. Pastikan server Langflow berjalan.';
    statusEl.className = 'text-sm text-rose-400';
  }
});