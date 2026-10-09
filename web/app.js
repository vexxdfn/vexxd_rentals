const RES = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'vexxd_rentals';
const $ = (s) => document.querySelector(s);
const esc = (v) => String(v ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const money = (v) => `$${Math.floor(Number(v) || 0).toLocaleString('en-US')}`;
const arr = (v) => (Array.isArray(v) ? v : []);

function applyAccent(accent) {
    const hex = /^#[0-9a-f]{6}$/i.test(accent) ? accent : '#ef4444';
    const n = parseInt(hex.slice(1), 16);
    document.documentElement.style.setProperty('--accent', hex);
    document.documentElement.style.setProperty('--accent-rgb', `${(n >> 16) & 255}, ${(n >> 8) & 255}, ${n & 255}`);
}

const post = (name, body = {}) => fetch(`https://${RES}/${name}`, {
    method: 'POST', headers: { 'Content-Type': 'application/json; charset=UTF-8' }, body: JSON.stringify(body),
}).then((r) => r.json()).catch(() => ({}));

const svg = (d, size = 16) => `<svg viewBox="0 0 24 24" width="${size}" height="${size}" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round">${d}</svg>`;
const ICONS = {
    car: '<path d="M5 17a2 2 0 1 0 4 0a2 2 0 1 0 -4 0"/><path d="M15 17a2 2 0 1 0 4 0a2 2 0 1 0 -4 0"/><path d="M5 17h-2v-6l2 -5h9l4 5h1a2 2 0 0 1 2 2v4h-2m-4 0h-6m-6 -6h15m-6 0v-5"/>',
    bike: '<path d="M2 16a3 3 0 1 0 6 0a3 3 0 1 0 -6 0"/><path d="M16 16a3 3 0 1 0 6 0a3 3 0 1 0 -6 0"/><path d="M7.5 14h5l4 -4h-10.5m1.5 4l4 -4"/><path d="M13 6h2l1.5 3l2 4"/>',
    bicycle: '<path d="M2 18a3 3 0 1 0 6 0a3 3 0 0 0 -6 0"/><path d="M16 18a3 3 0 1 0 6 0a3 3 0 0 0 -6 0"/><path d="M12 19v-4l-3 -3l5 -4l2 3h3"/><path d="M13.007 5a2 2 0 1 0 4 0a2 2 0 1 0 -4 0"/>',
    truck: '<path d="M5 17a2 2 0 1 0 4 0a2 2 0 1 0 -4 0"/><path d="M15 17a2 2 0 1 0 4 0a2 2 0 1 0 -4 0"/><path d="M5 17h-2v-11a1 1 0 0 1 1 -1h9v12m-4 0h6m4 0h2v-6h-8m0 -5h5l3 5"/>',
    boat: '<path d="M2 20a2.4 2.4 0 0 0 2 1a2.4 2.4 0 0 0 2 -1a2.4 2.4 0 0 1 2 -1a2.4 2.4 0 0 1 2 1a2.4 2.4 0 0 0 2 1a2.4 2.4 0 0 0 2 -1a2.4 2.4 0 0 1 2 -1a2.4 2.4 0 0 1 2 1a2.4 2.4 0 0 0 2 1a2.4 2.4 0 0 0 2 -1"/><path d="M4 18l-1 -3h18l-1 3"/><path d="M11 12h7l-7 -9v9"/><path d="M8 7l-2 5"/>',
    key: '<path d="M16.555 3.843l3.602 3.602a2.877 2.877 0 0 1 0 4.069l-2.643 2.643a2.877 2.877 0 0 1 -4.069 0l-.301 -.301l-6.558 6.558a2 2 0 0 1 -1.239 .578l-.175 .008h-1.172a1 1 0 0 1 -.993 -.883l-.007 -.117v-1.172a2 2 0 0 1 .467 -1.284l.119 -.13l.414 -.414h2v-2h2v-2l2.144 -2.144l-.301 -.301a2.877 2.877 0 0 1 0 -4.069l2.643 -2.643a2.877 2.877 0 0 1 4.069 0"/><path d="M15 9h.01"/>',
    pin: '<path d="M9 11a3 3 0 1 0 6 0a3 3 0 0 0 -6 0"/><path d="M17.657 16.657l-4.243 4.243a2 2 0 0 1 -2.827 0l-4.244 -4.243a8 8 0 1 1 11.314 0"/>',
    cog: '<path d="M10.325 4.317c.426 -1.756 2.924 -1.756 3.35 0a1.724 1.724 0 0 0 2.573 1.066c1.543 -.94 3.31 .826 2.37 2.37a1.724 1.724 0 0 0 1.065 2.572c1.756 .426 1.756 2.924 0 3.35a1.724 1.724 0 0 0 -1.066 2.573c.94 1.543 -.826 3.31 -2.37 2.37a1.724 1.724 0 0 0 -2.572 1.065c-.426 1.756 -2.924 1.756 -3.35 0a1.724 1.724 0 0 0 -2.573 -1.066c-1.543 .94 -3.31 -.826 -2.37 -2.37a1.724 1.724 0 0 0 -1.065 -2.572c-1.756 -.426 -1.756 -2.924 0 -3.35a1.724 1.724 0 0 0 1.066 -2.573c-.94 -1.543 .826 -3.31 2.37 -2.37c1 .608 2.296 .07 2.572 -1.065"/><path d="M9 12a3 3 0 1 0 6 0a3 3 0 0 0 -6 0"/>',
    plus: '<path d="M12 5l0 14"/><path d="M5 12l14 0"/>',
    grid: '<path d="M4 5a1 1 0 0 1 1 -1h4a1 1 0 0 1 1 1v4a1 1 0 0 1 -1 1h-4a1 1 0 0 1 -1 -1l0 -4"/><path d="M14 5a1 1 0 0 1 1 -1h4a1 1 0 0 1 1 1v4a1 1 0 0 1 -1 1h-4a1 1 0 0 1 -1 -1l0 -4"/><path d="M4 15a1 1 0 0 1 1 -1h4a1 1 0 0 1 1 1v4a1 1 0 0 1 -1 1h-4a1 1 0 0 1 -1 -1l0 -4"/><path d="M14 15a1 1 0 0 1 1 -1h4a1 1 0 0 1 1 1v4a1 1 0 0 1 -1 1h-4a1 1 0 0 1 -1 -1l0 -4"/>',
    x: '<path d="M18 6l-12 12"/><path d="M6 6l12 12"/>',
};
const ico = (name, size) => svg(ICONS[name] || ICONS.car, size);
const CATS = { car: 'Cars', bike: 'Motorcycles', bicycle: 'Bicycles', truck: 'Trucks', boat: 'Boats' };

const settings = { title: 'Vehicle Rentals', account: 'bank', fullAbove: 90, noneBelow: 20, fee: 0, images: 'https://docs.fivem.net/vehicles/%s.webp' };
const tone = (c) => (c >= settings.fullAbove ? 'var(--ok)' : (c <= settings.noneBelow ? 'var(--red)' : 'var(--amber)'));
const gauge = (pct, label) => `<div class="gauge"><svg viewBox="0 0 120 120"><circle cx="60" cy="60" r="52" fill="none" stroke="var(--s3)" stroke-width="6"/>
    <circle cx="60" cy="60" r="52" fill="none" stroke="${tone(pct)}" stroke-width="6" stroke-dasharray="${(326.7 * Math.max(0, Math.min(100, pct)) / 100).toFixed(1)} 326.7"/></svg>
    <div class="inner"><div><b>${pct}%</b><span>${label}</span></div></div></div>`;
const shot = (v, size) => `<img src="${esc(v.image || settings.images.replace('%s', encodeURIComponent(v.model)))}" data-cat="${esc(v.category || 'car')}" data-size="${size}" draggable="false">`;

document.addEventListener('error', (e) => {
    const el = e.target;
    if (!el || el.tagName !== 'IMG' || !el.dataset.size) return;
    const box = document.createElement('div');
    box.innerHTML = ico(el.dataset.cat, Number(el.dataset.size));
    el.replaceWith(box.firstChild);
}, true);

/* ---------- terminal ---------- */
const rt = { open: false, data: null, sel: null, cat: 'all', busy: false };

function rtLoad(data) {
    rt.data = data;
    Object.assign(settings, data.settings || {});
    applyAccent(settings.accent);
    const list = arr(data.vehicles);
    if (!list.find((v) => v.id === rt.sel)) rt.sel = (list.find((v) => v.valid !== false) || list[0] || {}).id || null;
    if (rt.cat !== 'all' && !list.some((v) => v.category === rt.cat)) rt.cat = 'all';
}

function rtOpen(data) {
    rt.open = true;
    rt.cat = 'all';
    rt.sel = null;
    rt.busy = false;
    rtLoad(data);
    $('#receipt').hidden = true;
    $('#r-close').innerHTML = ico('x', 18);
    $('#rent').hidden = false;
    rtRender();
}

function rtHide() {
    rt.open = false;
    $('#rent').hidden = true;
    $('#receipt').hidden = true;
}

function rtClose() {
    rtHide();
    post('close');
}

function policy() {
    const s = settings;
    const most = 100 - s.fee;
    return `<div class="policy"><small>Deposit refund</small>
        <div><span>${s.fullAbove}% or better</span><b>${most}% back</b></div>
        <div><span>${s.noneBelow}% to ${s.fullAbove}%</span><b>Reduced</b></div>
        <div><span>${s.noneBelow}% or worse</span><b>Nothing</b></div></div>`;
}

function scale(cond) {
    return `<div class="scale-wrap"><div class="scale"></div><i class="pin" style="left:${Math.max(0, Math.min(100, cond))}%"></i>
        <div class="ticks"><span>Wrecked</span><span>Damaged</span><span>Clean</span></div></div>`;
}

function meter(label, value, best, text) {
    const pct = best > 0 ? Math.max(6, Math.min(100, Math.round((value / best) * 100))) : 0;
    return `<div class="meter"><div class="meter-top"><span>${label}</span><b>${text || ''}</b></div><div class="bar"><i style="width:${pct}%"></i></div></div>`;
}

function blocker(v) {
    const d = rt.data;
    if (v.valid === false) return 'Not available right now';
    if (!v.licenceOk) return `Needs a ${esc(v.licence)} licence`;
    if (!d.location.bays) return 'No parking bays set up';
    if (d.money < v.price) return `Not enough in your ${settings.account === 'cash' ? 'wallet' : 'bank'}`;
    return '';
}

function detailVehicle(v) {
    if (!v) return '<div class="empty">Nothing to rent here yet.</div>';
    const list = arr(rt.data.vehicles).filter((x) => x.valid !== false);
    const best = (k) => Math.max(0.0001, ...list.map((x) => x[k] || 0));
    const why = blocker(v);
    const s = settings;
    const most = Math.floor(v.price * (100 - s.fee) / 100);
    return `<div class="hero">${shot(v, 90)}</div>
        <div class="d-name">${esc(v.label)}</div>
        <div class="d-sub">${esc(v.class || CATS[v.category] || 'Vehicle')}${v.seats ? ` · ${v.seats} seat${v.seats === 1 ? '' : 's'}` : ''}</div>
        ${v.valid === false ? '' : `<div class="meters">
            ${meter('Top speed', v.speed, best('speed'), `${v.speed} mph`)}
            ${meter('Acceleration', v.accel, best('accel'))}
            ${meter('Braking', v.braking, best('braking'))}
            ${meter('Grip', v.traction, best('traction'))}
        </div>`}
        <div class="deal"><div class="deal-row"><span>Deposit</span><b>${v.price > 0 ? money(v.price) : 'Free'}</b></div>
            ${v.price > 0 ? `<p>Bring it back to any rental desk in good shape and <b>${money(most)}</b> goes straight back to your ${s.account === 'cash' ? 'wallet' : 'bank'}. Damage lowers the refund.</p>` : '<p>No deposit needed. Bring it back when you are done.</p>'}</div>
        <div class="gap"></div>
        <button class="btn btn-primary go" id="r-rent" ${why ? 'disabled' : ''}>${why || `Rent · ${v.price > 0 ? money(v.price) : 'Free'}`}</button>`;
}

function detailRental(r) {
    const v = { model: r.model, category: 'car', image: (arr(rt.data.vehicles).find((x) => x.model === r.model) || {}).image };
    const time = r.minutes < 1 ? 'just now' : `${r.minutes} min ago`;
    let body;
    if (!r.exists) {
        body = `<div class="deal"><div class="deal-row"><span>Deposit held</span><b>${money(r.price)}</b></div>
            <p>We can't find this vehicle anywhere. If it is gone for good, report it lost to close the rental. The deposit is kept.</p></div><div class="gap"></div>`;
    } else {
        body = `${scale(r.condition)}
            <div class="deal"><div class="deal-row"><span>Refund right now</span><b class="${r.refund >= r.price ? 'ok' : ''}">${money(r.refund)}</b></div>
                <p>From a <b>${money(r.price)}</b> deposit.${r.near ? '' : ' Park it next to the desk to hand it back.'}</p></div>
            <div class="gap"></div>
            <button class="btn btn-primary go" id="r-return" ${r.near ? '' : 'disabled'}>${r.near ? `Return · get ${money(r.refund)} back` : 'Vehicle is too far away'}</button>`;
    }
    return `<div class="duo"><div class="hero sm">${shot(v, 70)}</div>${r.exists ? gauge(r.condition, 'Condition') : ''}</div>
        <div class="d-name">${esc(r.label)}</div>
        <div class="d-sub">${esc(r.plate)} · rented ${time}</div>
        ${body}
        <div class="pair"><button class="btn btn-ghost" id="r-refresh">Check again</button><button class="btn btn-danger" id="r-lost">Report it lost</button></div>`;
}

function rtRender() {
    const d = rt.data;
    const list = arr(d.vehicles);
    const r = d.rental;
    $('#r-title').textContent = settings.title;
    $('#r-sub').textContent = d.location.label;
    const cats = ['all', ...Object.keys(CATS).filter((c) => list.some((v) => v.category === c))];
    $('#r-cats').innerHTML = cats.length > 2 ? cats.map((c) => `<button class="rail-btn ${rt.cat === c ? 'active' : ''}" data-cat="${c}">${ico(c === 'all' ? 'grid' : c)}<span>${c === 'all' ? 'Everything' : CATS[c]}</span>
        <em>${c === 'all' ? list.length : list.filter((v) => v.category === c).length}</em></button>`).join('') : '';
    $('#r-policy').innerHTML = policy();
    $('#r-wallet').innerHTML = `<div class="wallet"><span>${settings.account === 'cash' ? 'Cash' : 'Bank'}</span><b>${money(d.money)}</b></div>`;
    $('#r-head').textContent = r ? 'Your rental' : 'Choose a vehicle';
    const shown = list.filter((v) => rt.cat === 'all' || v.category === rt.cat);
    $('#r-fleet').innerHTML = shown.map((v, i) => `<div class="car ${!r && rt.sel === v.id ? 'on' : ''} ${r || v.valid === false ? 'off' : ''}" data-car="${esc(v.id)}" style="animation-delay:${Math.min(i, 8) * .03}s">
        <span class="pill ${v.licenceOk ? 'grey' : 'red'} tag">${v.licenceOk ? esc(v.class || CATS[v.category] || '') : 'Licence needed'}</span>
        <div class="shot">${shot(v, 44)}</div>
        <div class="name"><b>${esc(v.label)}</b><span>${v.price > 0 ? money(v.price) : 'Free'}</span></div>
        <div class="meta">${v.valid === false ? 'Unavailable' : `${v.seats || 1} seat${v.seats === 1 ? '' : 's'} · ${v.speed || 0} mph`}</div></div>`).join('') || '<div class="empty">Nothing to rent here yet.</div>';
    $('#r-detail').innerHTML = r ? detailRental(r) : detailVehicle(list.find((v) => v.id === rt.sel));
}

function receipt(rc) {
    const kept = rc.price - rc.refund;
    const full = kept <= 0;
    const colour = full ? 'var(--ok)' : (rc.refund > 0 ? 'var(--amber)' : 'var(--red)');
    const text = full ? 'Clean return. The whole deposit is back with you.' : (rc.refund > 0 ? 'It came back damaged, so part of the deposit was kept for repairs.' : 'It came back too damaged to refund anything.');
    $('#rc-panel').innerHTML = `<div class="verdict">${gauge(rc.condition, 'Condition')}
            <div><div class="stamp" style="color:${colour}">Returned</div><p>${text}</p></div></div>
        <div class="lines">
            <div><span>${esc(rc.label)} · ${esc(rc.plate)}</span><b>${rc.minutes} min</b></div>
            <div><span>Deposit paid</span><b>${money(rc.price)}</b></div>
            <div><span>Kept</span><b>${money(kept)}</b></div>
            <div class="total"><span>Refunded to your ${settings.account === 'cash' ? 'wallet' : 'bank'}</span><b>${money(rc.refund)}</b></div>
        </div>
        <div class="rc-foot"><button class="btn btn-primary" id="rc-done">Done</button></div>`;
    $('#rent').hidden = true;
    $('#receipt').hidden = false;
}

function receiptDone() {
    $('#receipt').hidden = true;
    $('#rent').hidden = false;
    rtRender();
}

$('#rent').addEventListener('click', async (e) => {
    if (rt.busy) return;
    const car = e.target.closest('.car');
    if (car && !car.classList.contains('off')) { rt.sel = car.dataset.car; return rtRender(); }
    const t = e.target.closest('button');
    if (!t || t.disabled) return;
    if (t.id === 'r-close') return rtClose();
    if (t.dataset.cat) { rt.cat = t.dataset.cat; return rtRender(); }
    if (!['r-rent', 'r-return', 'r-lost', 'r-refresh'].includes(t.id)) return;
    if (t.id === 'r-lost' && !t.classList.contains('sure')) {
        t.classList.add('sure');
        t.textContent = 'Confirm · lose the deposit';
        setTimeout(() => { if (t.isConnected) rtRender(); }, 4000);
        return;
    }
    rt.busy = true;
    try {
        if (t.id === 'r-rent') {
            const res = await post('rent', { vehicle: rt.sel });
            if (res && res.ok) rtHide();
            return;
        }
        const res = await post({ 'r-return': 'return', 'r-lost': 'lost', 'r-refresh': 'refresh' }[t.id]);
        if (res && res.ok) {
            rtLoad(res);
            if (res.receipt) return receipt(res.receipt);
        }
        rtRender();
    } finally {
        rt.busy = false;
    }
});

$('#receipt').addEventListener('click', (e) => {
    const t = e.target.closest('button');
    if (t && t.id === 'rc-done') receiptDone();
});

/* ---------- admin ---------- */
const ad = { open: false, data: null, tab: 'locations', lists: {}, dirty: {}, sel: null, busy: false };
const clone = (v) => JSON.parse(JSON.stringify(v));
const slug = (s) => String(s).toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_+|_+$/g, '').slice(0, 40) || 'item';
const coordText = (c) => (c && Number.isFinite(c.x) ? `${c.x.toFixed(1)}, ${c.y.toFixed(1)}, ${c.z.toFixed(1)}` : 'Not set');

const KINDS = {
    locations: { label: 'Rental desks', one: 'desk', icon: 'pin',
        blank: () => ({ label: 'Vehicle Rental', coords: null, model: 'a_m_y_business_02', ped: true, blip: true, sprite: 225, colour: 1, spawns: [], vehicles: [] }),
        name: (x) => x.label, sub: (x) => `${arr(x.spawns).length} bay${arr(x.spawns).length === 1 ? '' : 's'} · ${arr(x.vehicles).length || 'all'} vehicles` },
    vehicles: { label: 'Vehicles', one: 'vehicle', icon: 'car',
        blank: () => ({ label: 'New vehicle', model: '', category: 'car', price: 250, licence: '', image: '', enabled: true }),
        name: (x) => x.label, sub: (x) => `${x.model || 'no model'} · ${money(x.price)}` },
};

function adLoad(data, only) {
    ad.data = data;
    for (const k of Object.keys(KINDS)) {
        if (k !== only && ad.dirty[k]) continue;
        ad.lists[k] = clone(arr(data[k]));
        ad.dirty[k] = false;
    }
    Object.assign(settings, data.settings || {});
    applyAccent(settings.accent);
}

function adOpen(data) {
    ad.open = true;
    ad.tab = 'locations';
    ad.dirty = {};
    adLoad(data);
    ad.sel = ad.lists.locations.length ? 0 : null;
    $('#admin').hidden = false;
    adRender();
}

function adClose(tell) {
    if (!ad.open) return;
    ad.open = false;
    $('#admin').hidden = true;
    if (tell) post('adminClose');
}

const isList = () => !!KINDS[ad.tab];
const cur = () => (isList() && ad.sel != null ? ad.lists[ad.tab][ad.sel] : null);
const fText = (label, key, v, hint = '', attr = '', wide = false) => `<div class="f ${wide ? 'wide' : ''}"><label>${label}</label><input class="input" data-key="${key}" value="${esc(v)}" ${attr} spellcheck="false">${hint ? `<small>${hint}</small>` : ''}</div>`;
const fNum = (label, key, v, hint = '', attr = '') => `<div class="f"><label>${label}</label><input class="input" type="number" data-key="${key}" value="${esc(v)}" ${attr}>${hint ? `<small>${hint}</small>` : ''}</div>`;
const fSelect = (label, key, v, options, hint = '') => `<div class="f"><label>${label}</label><select class="input" data-key="${key}">${options.map(([val, text]) => `<option value="${esc(val)}" ${String(v) === String(val) ? 'selected' : ''}>${esc(text)}</option>`).join('')}</select>${hint ? `<small>${hint}</small>` : ''}</div>`;
const fSwitch = (label, key, v, hint = '') => `<div class="f"><label>${label}</label><label class="switch"><input type="checkbox" data-key="${key}" ${v ? 'checked' : ''}><span></span></label>${hint ? `<small>${hint}</small>` : ''}</div>`;
const head = (icon, text) => `<div class="card-head"><h3>${ico(icon)} ${text}</h3></div>`;

function adForm(x) {
    if (ad.tab === 'vehicles') {
        const licences = [['', 'None'], ['car', 'Car'], ['motorcycle', 'Motorcycle'], ['commercial', 'Commercial']];
        if (x.licence && !licences.some((l) => l[0] === x.licence)) licences.push([x.licence, x.licence]);
        return `<div class="card"><div class="grid">
                ${fText('Name', 'label', x.label, '', 'maxlength="40"')}
                <div class="f"><label>Spawn name</label><input class="input" data-key="model" id="vh-model" value="${esc(x.model)}" maxlength="50" spellcheck="false"><small id="vh-check">The model name, like <code>sultanrs</code>.</small></div>
                ${fSelect('Category', 'category', x.category, Object.entries(CATS))}
                ${fNum('Deposit', 'price', x.price, 'Paid up front and refunded by condition on return.', 'min="0"')}
                ${fSelect('Licence needed', 'licence', x.licence, licences, ad.data.dmv ? 'Checked with vexxd_dmv.' : 'Only checked when vexxd_dmv is running.')}
                ${fSwitch('Offered', 'enabled', x.enabled !== false)}
                ${fText('Picture', 'image', x.image, 'Leave empty to use the picture address from Settings.', 'maxlength="300" placeholder="https://"', true)}
            </div></div>`;
    }
    const bays = arr(x.spawns);
    const picked = new Set(arr(x.vehicles));
    return `<div class="card">${head('pin', 'Desk')}<div class="grid">
            ${fText('Name', 'label', x.label, 'Shown on the map and in the terminal.', 'maxlength="60"')}
            <div class="f"><label>Position</label><div class="f-row"><div class="coord ${x.coords ? '' : 'unset'}">${coordText(x.coords)}</div>
                <button class="btn btn-soft sm" id="lc-here">Use my position</button></div></div>
            ${fSwitch('Clerk ped', 'ped', x.ped !== false, 'Off = a plain interaction point.')}
            ${fText('Ped model', 'model', x.model, '', 'maxlength="50"')}
            ${fSwitch('Map blip', 'blip', x.blip !== false)}
            <div class="f"><div class="f-row" style="align-items:flex-start"><div style="flex:1"><label>Blip sprite</label><input class="input" type="number" data-key="sprite" value="${esc(x.sprite)}" min="0"></div>
                <div style="flex:1"><label>Blip colour</label><input class="input" type="number" data-key="colour" value="${esc(x.colour)}" min="0"></div></div></div>
        </div></div>
        <div class="card">${head('car', 'Parking bays')}
            ${bays.map((b, i) => `<div class="f-row"><div class="coord">Bay ${i + 1} · ${coordText(b)}</div><button class="btn btn-danger sm" data-bay="${i}">Remove</button></div>`).join('') || '<p class="card-note">No bays yet. Vehicles can\'t be rented here until there is at least one.</p>'}
            <div class="list-actions"><button class="btn btn-soft" id="lc-bay">${ico('plus', 14)} Add a bay where I am</button></div>
            <p class="card-note" style="margin-top:.6rem">Stand or park where a rented vehicle should appear, facing the way it should face. The first empty bay is used.</p></div>
        <div class="card">${head('grid', 'Vehicles offered here')}
            <div class="chips">${ad.data.vehicles.map((v) => `<button class="chip ${picked.has(v.id) ? 'on' : ''}" data-offer="${esc(v.id)}">${esc(v.label)}</button>`).join('') || '<span class="empty">Add vehicles first.</span>'}</div>
            <p class="card-note" style="margin-top:.6rem">Pick none to offer every vehicle.</p></div>`;
}

const SWATCHES = ['#ef4444', '#f97316', '#eab308', '#22c55e', '#06b6d4', '#3b82f6', '#8b5cf6', '#ec4899'];
function adSettings() {
    const s = ad.data.settings;
    return `<div class="card">${head('cog', 'General')}<div class="grid">
            ${fText('Title', 'title', s.title, '', 'maxlength="50"')}
            <div class="f"><label>Accent colour</label><div class="color-row"><input type="color" class="color-pick" data-key="accent" value="${esc(s.accent)}">
                <div class="swatches">${SWATCHES.map((x) => `<button class="swatch" data-swatch="${x}" style="background:${x}"></button>`).join('')}</div></div></div>
            ${fSelect('Deposits use', 'account', s.account, [['bank', 'Bank'], ['cash', 'Cash']])}
            ${fText('Plate prefix', 'plate', s.plate, 'Up to 4 letters, followed by four numbers.', 'maxlength="4"')}
            ${fSwitch('Put the player in the driver seat', 'warp', s.warp)}
            ${fNum('Return distance (metres)', 'returnRange', s.returnRange, 'How close to a desk the vehicle has to be parked.', 'min="5" max="200"')}
            ${fText('Picture address', 'images', s.images, '<code>%s</code> is replaced with the spawn name.', 'maxlength="200"', true)}
        </div></div>
        <div class="card">${head('key', 'Deposit refund')}<div class="grid c3">
            ${fNum('Full refund at %', 'fullAbove', s.fullAbove, 'Condition at or above this gets everything back.', 'min="1" max="100"')}
            ${fNum('No refund at %', 'noneBelow', s.noneBelow, 'Condition at or below this gets nothing.', 'min="0" max="99"')}
            ${fNum('Always kept %', 'fee', s.fee, 'A rental fee taken from every deposit. 0 = none.', 'min="0" max="100"')}
        </div><p class="card-note" style="margin-top:.7rem">Condition is the average of the vehicle's body and engine health. Between the two marks the refund slides evenly.</p>
        <div class="list-actions"><button class="btn btn-primary" id="st-save">Save settings</button></div></div>`;
}

function adCollect() {
    const x = cur();
    document.querySelectorAll('#ad-body [data-key]').forEach((el) => {
        const v = el.type === 'checkbox' ? el.checked : (el.type === 'number' ? Number(el.value) : el.value);
        if (ad.tab === 'settings') ad.data.settings[el.dataset.key] = v;
        else if (x) x[el.dataset.key] = v;
    });
}

function adRender() {
    const tabs = [...Object.entries(KINDS).map(([id, k]) => [id, k.label, k.icon, ad.lists[id].length]), ['settings', 'Settings', 'cog', '']];
    $('#ad-tabs').innerHTML = tabs.map(([id, label, icon, n]) => `<button class="rail-btn ${ad.tab === id ? 'active' : ''}" data-adtab="${id}">${ico(icon)}<span>${label}</span><em>${n}</em></button>`).join('');
    $('#ad-list').hidden = !isList();
    let actions = `<button class="btn btn-icon" id="ad-close" aria-label="Close">${ico('x', 18)}</button>`;
    if (!isList()) {
        $('#ad-title').textContent = 'Settings';
        $('#ad-body').innerHTML = adSettings();
    } else {
        const kind = KINDS[ad.tab];
        const list = ad.lists[ad.tab];
        const dirty = !!ad.dirty[ad.tab];
        if (ad.sel != null && ad.sel >= list.length) ad.sel = list.length ? list.length - 1 : null;
        $('#ad-list-head').innerHTML = `<button class="btn btn-primary full" id="ad-new">${ico('plus', 14)} New ${kind.one}</button>`;
        $('#ad-rows').innerHTML = list.map((x, i) => `<button class="ed-row ${ad.sel === i ? 'on' : ''}" data-row="${i}"><div><b>${esc(kind.name(x))}</b><span>${esc(kind.sub(x))}</span></div></button>`).join('')
            || '<div class="empty">Nothing here yet.</div>';
        const x = cur();
        $('#ad-title').textContent = x ? kind.name(x) : kind.label;
        $('#ad-body').innerHTML = x ? adForm(x) : `<div class="card ed-empty"><p class="card-note">${ad.tab === 'locations' ? 'Stand where the rental desk should be and press New desk.' : 'Pick a vehicle on the left or add a new one.'} Nothing is live until you press Save.</p></div>`;
        if (x) actions = `<button class="btn btn-danger" id="ad-del">Delete</button>${actions}`;
        actions = `<button class="btn btn-primary ${dirty ? 'dirty' : ''}" id="ad-save">${dirty ? 'Save changes' : 'Saved'}</button>${actions}`;
    }
    $('#ad-actions').innerHTML = actions;
}

function adPayload(kind) {
    const list = ad.lists[kind];
    const used = new Set(list.filter((x) => x.id).map((x) => x.id));
    for (const x of list) {
        if (x.id) continue;
        const base = slug(kind === 'vehicles' ? (x.model || x.label) : x.label);
        let id = base, n = 2;
        while (used.has(id)) id = `${base}_${n++}`;
        used.add(id);
        x.id = id;
    }
    return list;
}

function markDirty() {
    if (!isList() || ad.dirty[ad.tab]) return;
    ad.dirty[ad.tab] = true;
    const b = $('#ad-save');
    if (b) { b.classList.add('dirty'); b.textContent = 'Save changes'; }
}

$('#admin').addEventListener('click', async (e) => {
    const t = e.target.closest('button');
    if (!t || ad.busy) return;
    const d = t.dataset;
    if (t.id === 'ad-close') return adClose(true);
    adCollect();
    if (d.adtab) { ad.tab = d.adtab; ad.sel = KINDS[d.adtab] && ad.lists[d.adtab].length ? 0 : null; return adRender(); }
    if (d.row) { ad.sel = Number(d.row); return adRender(); }
    if (d.swatch) { ad.data.settings.accent = d.swatch; applyAccent(d.swatch); return adRender(); }
    const list = ad.lists[ad.tab];
    const x = cur();

    ad.busy = true;
    try {
        if (t.id === 'ad-new') {
            const item = KINDS[ad.tab].blank();
            if (ad.tab === 'locations') item.coords = await post('adminHere');
            list.push(item);
            ad.sel = list.length - 1;
            ad.dirty[ad.tab] = true;
        } else if (t.id === 'ad-del') {
            list.splice(ad.sel, 1);
            ad.dirty[ad.tab] = true;
        } else if (t.id === 'lc-here' && x) {
            x.coords = await post('adminHere');
            ad.dirty.locations = true;
        } else if (t.id === 'lc-bay' && x) {
            const c = await post('adminHere');
            if (c && Number.isFinite(c.x) && arr(x.spawns).length < 12) { x.spawns = [...arr(x.spawns), c]; ad.dirty.locations = true; }
        } else if (d.bay != null && x) {
            x.spawns.splice(Number(d.bay), 1);
            ad.dirty.locations = true;
        } else if (d.offer && x) {
            const set = new Set(arr(x.vehicles));
            if (set.has(d.offer)) set.delete(d.offer); else set.add(d.offer);
            x.vehicles = [...set];
            ad.dirty.locations = true;
        } else if (t.id === 'ad-save') {
            const kind = ad.tab;
            const res = await post('adminSave', { kind, list: adPayload(kind) });
            if (res && res.ok) { const sel = ad.sel; adLoad(res, kind); ad.sel = sel; }
        } else if (t.id === 'st-save') {
            const res = await post('adminSettings', { data: ad.data.settings });
            if (res && res.ok) adLoad(res);
        }
        adRender();
    } finally {
        ad.busy = false;
    }
});

$('#admin').addEventListener('input', (e) => {
    const el = e.target;
    if (el.dataset.key === 'accent') applyAccent(el.value);
    if (el.dataset.key) markDirty();
});

$('#admin').addEventListener('change', async (e) => {
    if (e.target.id !== 'vh-model') return;
    const model = e.target.value.trim().toLowerCase();
    const note = $('#vh-check');
    if (!model || !note) return;
    const res = await post('adminCheck', { model });
    if (!note.isConnected || $('#vh-model').value.trim().toLowerCase() !== model) return;
    note.className = res.valid ? 'good' : 'bad';
    note.textContent = res.valid ? 'Found on this server.' : 'No vehicle with that spawn name is loaded on this server.';
});

/* ---------- messages ---------- */
window.addEventListener('message', (e) => {
    const m = e.data || {};
    switch (m.action) {
        case 'open': rtOpen(m.data); break;
        case 'close': rtHide(); break;
        case 'admin': adOpen(m.data); break;
        case 'adminClose': adClose(false); break;
    }
});

window.addEventListener('keydown', (e) => {
    if (!$('#receipt').hidden) {
        if (e.key === 'Escape' || e.key === 'Enter') receiptDone();
        return;
    }
    if (e.key !== 'Escape') return;
    if (rt.open) rtClose();
    else if (ad.open) adClose(true);
});
