class StateSubject {
    constructor(initialState) {
        this.state = initialState;
        this.observers = [];
    }

    subscribe(observerFunction) {
        this.observers.push(observerFunction);
    }

    notify() {
        this.observers.forEach((observer) => observer(this.state));
    }

    setState(newState) {
        this.state = { ...this.state, ...newState };
        this.notify();
    }
}

const appStore = new StateSubject({
    loading: false,
    error: null,
    spots: []
});

appStore.subscribe((state) => {
    const loadingState = document.getElementById('loadingState');
    const placeholderState = document.getElementById('placeholderState');
    const resultsContainer = document.getElementById('resultsContainer');
    const submitBtn = document.getElementById('submitBtn');

    if (state.loading) {
        loadingState.classList.remove('hidden');
        placeholderState.classList.add('hidden');
        resultsContainer.innerHTML = '';
        submitBtn.disabled = true;
        submitBtn.classList.add('opacity-50');
    } else {
        loadingState.classList.add('hidden');
        submitBtn.disabled = false;
        submitBtn.classList.remove('opacity-50');

        if (state.spots.length === 0) {
            placeholderState.classList.remove('hidden');
        } else {
            placeholderState.classList.add('hidden');
            renderSpots(state.spots, resultsContainer);
        }
    }
});

function renderSpots(spots, container) {
    container.innerHTML = spots.map((spot, index) => `
        <div class="glass-panel p-6 rounded-2xl relative overflow-hidden transition hover:border-purple-500/40">
            <div class="flex justify-between items-start mb-4">
                <div>
                    <span class="text-xs font-bold text-purple-400 uppercase tracking-widest">Spot #${index + 1}</span>
                    <h3 class="text-2xl font-bold text-white mt-1">${spot.spot_name}</h3>
                    <a href="${spot.light_pollution_link || 'https://www.lightpollutionmap.info/'}" target="_blank" rel="noopener noreferrer"
                        class="inline-block mt-2 text-xs text-cyan-300 hover:text-cyan-200 underline">
                        Open light pollution map
                    </a>
                </div>
                <div class="text-right">
                    <span class="inline-block px-3 py-1 rounded-full text-xs font-semibold bg-cyan-500/10 text-cyan-300 border border-cyan-500/20">
                        Bortle Class ${spot.bortle_class}
                    </span>
                    <p class="text-xs text-emerald-400 mt-1 font-medium">${spot.sky_clarity_percentage}% Sky Clarity</p>
                </div>
            </div>

            <div class="mt-4 pt-4 border-t border-white/10">
                <h4 class="text-xs font-bold uppercase text-gray-400 mb-3">Visibility</h4>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-3 text-xs">
                    <div class="p-3 rounded-lg bg-white/5 border border-white/10">
                        <span class="text-[10px] text-gray-400 uppercase block">Weather</span>
                        <span class="text-sm font-bold text-white">${spot.visibility?.weather || 'N/A'}</span>
                    </div>
                    <div class="p-3 rounded-lg bg-white/5 border border-white/10">
                        <span class="text-[10px] text-gray-400 uppercase block">Cloud Cover</span>
                        <span class="text-sm font-bold text-white">${spot.visibility?.cloud_cover || 'N/A'}</span>
                    </div>
                    <div class="p-3 rounded-lg bg-white/5 border border-white/10">
                        <span class="text-[10px] text-gray-400 uppercase block">Seeing</span>
                        <span class="text-sm font-bold text-white">${spot.visibility?.seeing || 'N/A'}</span>
                    </div>
                    <div class="p-3 rounded-lg bg-white/5 border border-white/10">
                        <span class="text-[10px] text-gray-400 uppercase block">Best Time</span>
                        <span class="text-sm font-bold text-white">${spot.visibility?.best_time || 'N/A'}</span>
                    </div>
                </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 my-4 p-4 rounded-xl bg-black/30 border border-white/5 text-xs">
                <div>
                    <strong class="text-purple-300 block mb-1">Foreground (FG):</strong>
                    <p class="text-gray-300">${spot.composition.foreground}</p>
                </div>
                <div>
                    <strong class="text-cyan-300 block mb-1">Background (BG):</strong>
                    <p class="text-gray-300">${spot.composition.background}</p>
                </div>
            </div>

            <div class="mt-4 pt-4 border-t border-white/10">
                <h4 class="text-xs font-bold uppercase text-gray-400 mb-3">Target Exposure Settings</h4>
                <div class="grid grid-cols-3 gap-3 text-center mb-3">
                    <div class="p-2 rounded-lg bg-white/5 border border-white/10">
                        <span class="text-[10px] text-gray-400 uppercase block">Shutter</span>
                        <span class="text-sm font-bold text-white">${spot.exposure_triangle.shutter_speed}</span>
                    </div>
                    <div class="p-2 rounded-lg bg-white/5 border border-white/10">
                        <span class="text-[10px] text-gray-400 uppercase block">Aperture</span>
                        <span class="text-sm font-bold text-white">${spot.exposure_triangle.aperture}</span>
                    </div>
                    <div class="p-2 rounded-lg bg-white/5 border border-white/10">
                        <span class="text-[10px] text-gray-400 uppercase block">ISO</span>
                        <span class="text-sm font-bold text-white">${spot.exposure_triangle.iso}</span>
                    </div>
                </div>
                <p class="text-xs text-gray-400 italic">💡 ${spot.exposure_triangle.technique_notes}</p>
            </div>
        </div>
    `).join('');
}

const gpsBtn = document.getElementById('gpsBtn');
const gpsStatus = document.getElementById('gpsStatus');
const stopAiBtn = document.getElementById('stopAiBtn');
const stopStatus = document.getElementById('stopStatus');
const yourLocationInput = document.getElementById('yourLocation');
const countryInput = document.getElementById('country');

async function stopAiAndExit() {
    stopAiBtn.disabled = true;
    stopAiBtn.classList.add('opacity-50');
    stopStatus.textContent = 'Stopping AI engine...';
    stopStatus.classList.remove('hidden');

    try {
        const response = await fetch('/api/shutdown', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' }
        });

        const result = await response.json().catch(() => ({}));
        stopStatus.textContent = result.message || 'AI engine stopped.';
    } catch (error) {
        console.error(error);
        stopStatus.textContent = 'AI engine already offline. Closing the page...';
    } finally {
        setTimeout(() => {
            try {
                window.close();
            } catch (err) {
                console.warn('window.close() failed, fallback used instead.');
            }

            try {
                window.location.href = 'about:blank';
            } catch (err) {
                console.warn('Navigation fallback failed.');
            }
        }, 700);
    }
}

function updateCountryFieldMode() {
    const isGpsLocation = yourLocationInput.value.toLowerCase().includes('my current location');

    if (isGpsLocation) {
        countryInput.value = 'Your Current Location';
        countryInput.readOnly = true;
        countryInput.classList.add('cursor-not-allowed', 'opacity-70');
        countryInput.classList.remove('focus:border-purple-500');
        countryInput.setAttribute('aria-label', 'Your Current Location');
    } else {
        countryInput.value = '';
        countryInput.readOnly = false;
        countryInput.classList.remove('cursor-not-allowed', 'opacity-70');
        countryInput.classList.add('focus:border-purple-500');
        countryInput.removeAttribute('aria-label');
    }
}

function setCurrentLocationFromGPS() {
    if (!navigator.geolocation) {
        gpsStatus.textContent = 'Geolocation is not supported by this browser.';
        gpsStatus.classList.remove('hidden');
        return;
    }

    gpsStatus.textContent = 'Requesting current GPS location...';
    gpsStatus.classList.remove('hidden');
    gpsBtn.disabled = true;
    gpsBtn.classList.add('opacity-50');

    navigator.geolocation.getCurrentPosition(
        (position) => {
            const { latitude, longitude } = position.coords;
            const gpsText = `My current location (${latitude.toFixed(5)}, ${longitude.toFixed(5)})`;
            yourLocationInput.value = gpsText;
            updateCountryFieldMode();
            gpsStatus.textContent = 'Current GPS location detected.';
            gpsBtn.disabled = false;
            gpsBtn.classList.remove('opacity-50');
        },
        (error) => {
            console.error(error);
            gpsStatus.textContent = 'Unable to get current GPS location. Please type a location manually.';
            gpsBtn.disabled = false;
            gpsBtn.classList.remove('opacity-50');
        },
        {
            enableHighAccuracy: true,
            timeout: 10000,
            maximumAge: 0
        }
    );
}

yourLocationInput.addEventListener('input', updateCountryFieldMode);

gpsBtn.addEventListener('click', setCurrentLocationFromGPS);
stopAiBtn.addEventListener('click', stopAiAndExit);

document.getElementById('lookupForm').addEventListener('submit', async (e) => {
    e.preventDefault();

    const payload = {
        your_location: document.getElementById('yourLocation').value,
        country: document.getElementById('country').value,
        radius: parseFloat(document.getElementById('radius').value),
        shooting_purpose: document.getElementById('shootingPurpose').value,
        camera_gear: document.getElementById('cameraGear').value
    };

    appStore.setState({ loading: true });

    try {
        const response = await fetch('/api/discover', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });

        const resData = await response.json();

        if (resData.status === 'success' && resData.data.spots) {
            appStore.setState({ loading: false, spots: resData.data.spots });
        } else {
            alert('Error processing location data.');
            appStore.setState({ loading: false });
        }
    } catch (err) {
        console.error(err);
        alert('Failed to connect to local backend engine.');
        appStore.setState({ loading: false });
    }
});
