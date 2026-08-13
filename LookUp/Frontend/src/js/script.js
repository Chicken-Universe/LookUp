const SUPABASE_URL = 'https://qidnvwyagidmnlafsaer.supabase.co/';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFpZG52d3lhZ2lkbW5sYWZzYWVyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ0NDMyNTAsImV4cCI6MjEwMDAxOTI1MH0.BF1QZhrLf9N4TNewm8wuM6cGoUHZK7-F3erMkKZM0cI';
const supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

const form = document.getElementById('lookupForm');
const promptPreview = document.getElementById('promptPreview');
const status = document.getElementById('status');

const buildPrompt = (target, country, gear, purpose) => {
    return `Destination Target: ${target}\nDestination Country: ${country}\nPhone / Gear Camera: ${gear}\nPurpose: ${purpose}`;
};

form.addEventListener('input', () => {
    const target = form.destinationTarget.value.trim();
    const country = form.destinationCountry.value.trim();
    const gear = form.cameraGear.value.trim();
    const purpose = form.shootingTarget.value.trim();
    promptPreview.textContent = buildPrompt(target || 'Please Input', country || 'Please Input', gear || 'Please Input', purpose || 'Please Input');
});

form.addEventListener('submit', async (event) => {
    event.preventDefault();
    const target = form.destinationTarget.value.trim();
    const country = form.destinationCountry.value.trim();
    const gear = form.cameraGear.value.trim();
    const purpose = form.shootingTarget.value.trim();

    if (!target || !country || !gear || !purpose) {
        status.textContent = 'Please fill in all fields first.';
        status.classList.add('text-rose-400');
        return;
    }

    status.textContent = 'Data is ready to be sent to the AI...';
    status.classList.remove('text-rose-400');
    status.classList.add('text-emerald-300');

    const { data, error } = await supabaseClient
        .from('user_requests')
        .insert([
            {
                destinationTarget: target,
                destinationCountry: country,
                cameraGear: gear,
                shootingTarget: purpose
            }
        ])
        .select();

    if (error) {
        console.error('Error Supabase:', error.message);
        status.textContent = 'Failed to save data: ' + error.message;
        status.classList.add('text-rose-400');
        return;
    }

    const payload = {
        destinationTarget: target,
        destinationCountry: country,
        cameraGear: gear,
        shootingTarget: purpose,
        promptText: buildPrompt(target, country, gear, purpose),
    };

    console.log('AI payload:', payload);
    status.textContent = 'Input on Progress: Data has been sent to the AI successfully (soon to be processed)';
});

form.dispatchEvent(new Event('input'));
